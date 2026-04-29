#!/bin/bash
#
# Runs qmllint against explicitly selected plugin files or directories.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly NOCTALIA_SHELL_DIR="${PROJECT_ROOT}/docs/noctalia-shell"
TMP_ROOT=""
OUTPUT_MODE="json"

declare -a PLUGIN_TARGETS=()
declare -a DIR_TARGETS=()
declare -a FILE_TARGETS=()
declare -a RESOLVED_FILES=()
declare -a GROUPED_PLUGIN_ROOTS=()
declare -A SEEN_FILES=()
declare -A PLUGIN_FILE_LISTS=()
declare -A PLUGIN_RESULT_JSONS=()
declare -A PLUGIN_RESULT_STATUSES=()
declare -A PLUGIN_REPORT_JSONS=()

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [--plugin <plugin>] [--dir <directory>] [--file <file.qml>] [--summary]

Required:
  At least one target flag must be provided.

Flags:
  --plugin <plugin>  Lint a plugin directory identified by name or path.
  --dir <directory>  Lint all .qml files under a directory.
  --file <file.qml>  Lint one specific QML file.
  --summary          Print a human-readable summary instead of JSON.
  --help             Show this help message.

Output:
  Default: writes a JSON report to stdout containing all qmllint warnings and
  errors for each selected plugin group.
  --summary: prints a compact human-readable summary with finding counts and
  per-file diagnostics.
  Exits non-zero if any selected plugin group has findings.
EOF
}

cleanup() {
  if [[ -n "${TMP_ROOT}" && -d "${TMP_ROOT}" ]]; then
    rm -rf "${TMP_ROOT}"
  fi
}

is_absolute_path() {
  local path="$1"
  [[ "${path}" == /* ]]
}

resolve_existing_path() {
  local raw_path="$1"
  local resolved=""

  if is_absolute_path "${raw_path}"; then
    resolved="$(realpath -e "${raw_path}")"
  else
    resolved="$(realpath -e "${raw_path}")"
  fi

  printf '%s\n' "${resolved}"
}

ensure_within_project() {
  local path="$1"

  case "${path}" in
    "${PROJECT_ROOT}"/* | "${PROJECT_ROOT}")
      return 0
      ;;
    *)
      err "Path is outside this workspace: ${path}"
      return 1
      ;;
  esac
}

resolve_plugin_target() {
  local raw_target="$1"
  local candidate=""
  local resolved=""

  if [[ -d "${PROJECT_ROOT}/${raw_target}" ]]; then
    candidate="${PROJECT_ROOT}/${raw_target}"
  else
    candidate="${raw_target}"
  fi

  resolved="$(resolve_existing_path "${candidate}")"
  ensure_within_project "${resolved}"

  if [[ ! -d "${resolved}" ]]; then
    err "Plugin target is not a directory: ${raw_target}"
    return 1
  fi

  if [[ ! -f "${resolved}/manifest.json" ]]; then
    err "Plugin target does not contain manifest.json: ${raw_target}"
    return 1
  fi

  printf '%s\n' "${resolved}"
}

find_plugin_root() {
  local raw_path="$1"
  local current=""

  if [[ -d "${raw_path}" ]]; then
    current="${raw_path}"
  else
    current="$(dirname "${raw_path}")"
  fi

  while [[ "${current}" == "${PROJECT_ROOT}" || "${current}" == "${PROJECT_ROOT}"/* ]]; do
    if [[ -f "${current}/manifest.json" ]]; then
      printf '%s\n' "${current}"
      return 0
    fi
    if [[ "${current}" == "${PROJECT_ROOT}" ]]; then
      break
    fi
    current="$(dirname "${current}")"
  done

  err "No plugin root found for path: ${raw_path}"
  return 1
}

add_resolved_file() {
  local file_path="$1"

  if [[ -n "${SEEN_FILES["${file_path}"]+x}" ]]; then
    return 0
  fi

  SEEN_FILES["${file_path}"]=1
  RESOLVED_FILES+=("${file_path}")
}

collect_qml_files_from_plugin() {
  local plugin_root="$1"
  local found_any=0
  local file_path=""

  while IFS= read -r file_path; do
    found_any=1
    add_resolved_file "${file_path}"
  done < <(find "${plugin_root}" -type f -name '*.qml' | sort)

  if [[ "${found_any}" -eq 0 ]]; then
    err "No QML files found under plugin: ${plugin_root}"
    return 1
  fi
}

collect_qml_files_from_dir() {
  local dir_path="$1"
  local found_any=0
  local file_path=""

  while IFS= read -r file_path; do
    found_any=1
    add_resolved_file "${file_path}"
  done < <(find "${dir_path}" -type f -name '*.qml' | sort)

  if [[ "${found_any}" -eq 0 ]]; then
    err "No QML files found under directory: ${dir_path}"
    return 1
  fi
}

collect_explicit_targets() {
  local plugin_root=""
  local dir_path=""
  local file_path=""

  for plugin_root in "${PLUGIN_TARGETS[@]}"; do
    collect_qml_files_from_plugin "${plugin_root}"
  done

  for dir_path in "${DIR_TARGETS[@]}"; do
    collect_qml_files_from_dir "${dir_path}"
  done

  for file_path in "${FILE_TARGETS[@]}"; do
    add_resolved_file "${file_path}"
  done

  if [[ "${#RESOLVED_FILES[@]}" -eq 0 ]]; then
    err "No QML files were selected."
    return 1
  fi
}

register_grouped_plugin_root() {
  local plugin_root="$1"
  local existing=""

  for existing in "${GROUPED_PLUGIN_ROOTS[@]}"; do
    if [[ "${existing}" == "${plugin_root}" ]]; then
      return 0
    fi
  done

  GROUPED_PLUGIN_ROOTS+=("${plugin_root}")
}

group_files_by_plugin_root() {
  local file_path=""
  local plugin_root=""

  for file_path in "${RESOLVED_FILES[@]}"; do
    plugin_root="$(find_plugin_root "${file_path}")"
    register_grouped_plugin_root "${plugin_root}"
    PLUGIN_FILE_LISTS["${plugin_root}"]+="${file_path}"$'\n'
  done
}

write_qmldir() {
  local module_dir="$1"
  local module_name="$2"
  local source_dir="$3"
  local qml_file=""
  local base_name=""
  local type_name=""
  local first_line=""

  mkdir -p "${module_dir}"
  {
    echo "module ${module_name}"
    shopt -s nullglob
    for qml_file in "${source_dir}"/*.qml; do
      base_name="$(basename "${qml_file}")"
      type_name="${base_name%.qml}"
      first_line="$(head -n 1 "${qml_file}" || true)"
      if [[ "${first_line}" == "pragma Singleton" ]]; then
        echo "singleton ${type_name} 1.0 ${base_name}"
      else
        echo "${type_name} 1.0 ${base_name}"
      fi
      ln -sfn "${qml_file}" "${module_dir}/${base_name}"
    done
  } > "${module_dir}/qmldir"
}

build_import_shims() {
  local service_dir=""
  local service_name=""

  mkdir -p "${TMP_ROOT}/qs/Services"
  write_qmldir "${TMP_ROOT}/qs/Commons" "qs.Commons" "${NOCTALIA_SHELL_DIR}/Commons"
  write_qmldir "${TMP_ROOT}/qs/Widgets" "qs.Widgets" "${NOCTALIA_SHELL_DIR}/Widgets"

  for service_dir in "${NOCTALIA_SHELL_DIR}"/Services/*; do
    [[ -d "${service_dir}" ]] || continue
    shopt -s nullglob
    if [[ "${#service_dir}" -gt 0 ]] && compgen -G "${service_dir}/*.qml" > /dev/null; then
      service_name="$(basename "${service_dir}")"
      write_qmldir \
        "${TMP_ROOT}/qs/Services/${service_name}" \
        "qs.Services.${service_name}" \
        "${service_dir}"
    fi
  done
}

resolve_qmllint_bin() {
  if [[ -x "/usr/lib/qt6/bin/qmllint" ]]; then
    printf '%s\n' "/usr/lib/qt6/bin/qmllint"
    return 0
  fi

  if command -v qmllint > /dev/null 2>&1; then
    command -v qmllint
    return 0
  fi

  err "qmllint was not found. Install Qt6 qmllint or add it to PATH."
  return 1
}

ensure_jq_available() {
  if command -v jq > /dev/null 2>&1; then
    return 0
  fi

  err "jq was not found. Install jq to parse qmllint JSON output."
  return 1
}

validate_environment() {
  if [[ ! -d "${NOCTALIA_SHELL_DIR}" ]]; then
    err "Missing Noctalia shell sources at ${NOCTALIA_SHELL_DIR}"
    return 1
  fi

  if [[ ! -d "${NOCTALIA_SHELL_DIR}/Commons" || ! -d "${NOCTALIA_SHELL_DIR}/Widgets" ]]; then
    err "Noctalia shell sources are incomplete under ${NOCTALIA_SHELL_DIR}"
    return 1
  fi
}

lint_plugin_group() {
  local qmllint_bin="$1"
  local plugin_root="$2"
  local group_file=""
  local result_json=""
  local -a qml_files=()
  local -a cmd=()
  local status=0

  group_file="${TMP_ROOT}/files.$(basename "${plugin_root}").txt"
  printf '%s' "${PLUGIN_FILE_LISTS["${plugin_root}"]}" > "${group_file}"

  while IFS= read -r group_path; do
    [[ -n "${group_path}" ]] || continue
    qml_files+=("${group_path}")
  done < "${group_file}"

  result_json="${TMP_ROOT}/result.$(basename "${plugin_root}").json"
  PLUGIN_RESULT_JSONS["${plugin_root}"]="${result_json}"

  cmd=(
    "${qmllint_bin}"
    --json "${result_json}"
    -W 0
    -I "${TMP_ROOT}"
    -I "${plugin_root}"
  )
  cmd+=("${qml_files[@]}")

  if "${cmd[@]}"; then
    PLUGIN_RESULT_STATUSES["${plugin_root}"]=0
    return 0
  else
    status=$?
    PLUGIN_RESULT_STATUSES["${plugin_root}"]="${status}"
    return "${status}"
  fi
}

build_plugin_report() {
  local plugin_root="$1"
  local result_json="${PLUGIN_RESULT_JSONS["${plugin_root}"]}"
  local group_file="${TMP_ROOT}/files.$(basename "${plugin_root}").txt"
  local report_json="${TMP_ROOT}/report.$(basename "${plugin_root}").json"
  local lint_status="${PLUGIN_RESULT_STATUSES["${plugin_root}"]:-1}"

  jq \
    --arg plugin "$(basename "${plugin_root}")" \
    --arg pluginRoot "${plugin_root}" \
    --argjson lintExitCode "${lint_status}" \
    --rawfile selectedFilesRaw "${group_file}" \
    '
      def selected_files:
        $selectedFilesRaw
        | split("\n")
        | map(select(length > 0));
      def all_warnings:
        (.files // [])
        | map(.warnings // [])
        | add // [];
      def warning_count:
        ((all_warnings | length) // 0);
      {
        plugin: $plugin,
        pluginRoot: $pluginRoot,
        selectedFiles: selected_files,
        lintPassed: ($lintExitCode == 0 and (warning_count == 0)),
        lintExitCode: $lintExitCode,
        selectedFileCount: (selected_files | length),
        warningCount: warning_count,
        warningCountsById: (
          all_warnings
          | group_by(.id)
          | map({key: .[0].id, value: length})
          | from_entries
        ),
        qmllint: .
      }
    ' "${result_json}" > "${report_json}"

  PLUGIN_REPORT_JSONS["${plugin_root}"]="${report_json}"
}

emit_results_json() {
  local checked_groups="$1"
  local pass_groups="$2"
  local failed_groups="$3"
  local report_json=""
  local -a report_files=()

  for plugin_root in "${GROUPED_PLUGIN_ROOTS[@]}"; do
    report_json="${PLUGIN_REPORT_JSONS["${plugin_root}"]}"
    report_files+=("${report_json}")
  done

  jq -s \
    --argjson selectedFileCount "${#RESOLVED_FILES[@]}" \
    --argjson pluginGroupCount "${checked_groups}" \
    --argjson passCount "${pass_groups}" \
    --argjson failCount "${failed_groups}" \
    '
      {
        ok: ($failCount == 0),
        selectedFileCount: $selectedFileCount,
        pluginGroupCount: $pluginGroupCount,
        passCount: $passCount,
        failCount: $failCount,
        results: .
      }
    ' "${report_files[@]}"
}

emit_results_summary() {
  local checked_groups="$1"
  local pass_groups="$2"
  local failed_groups="$3"
  local plugin_root=""
  local report_json=""

  echo "qmllint summary"
  echo "selected files: ${#RESOLVED_FILES[@]}"
  echo "plugin groups: ${checked_groups}"
  echo "passed: ${pass_groups}"
  echo "failed: ${failed_groups}"
  echo ""

  for plugin_root in "${GROUPED_PLUGIN_ROOTS[@]}"; do
    report_json="${PLUGIN_REPORT_JSONS["${plugin_root}"]}"

    jq -r '
      [
        (if .lintPassed then "PASS" else "FAIL" end),
        .plugin,
        "(" + (.selectedFileCount | tostring) + " file(s), " +
        (.warningCount | tostring) + " finding(s))"
      ] | join(" ")
    ' "${report_json}"

    jq -r '
      .warningCountsById
      | to_entries
      | sort_by(.key)
      | .[]
      | "  " + .key + ": " + (.value | tostring)
    ' "${report_json}"

    jq -r '
      .qmllint.files[]
      | select((.warnings | length) > 0)
      | "  " + .filename,
        (
          .warnings[]
          | "    line " + (.line | tostring) + ":" + (.column | tostring)
            + " [" + .type + "/" + .id + "] " + .message
        )
    ' "${report_json}"

    echo ""
  done
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --plugin)
        if [[ $# -lt 2 ]]; then
          err "Missing value for --plugin"
          usage
          return 1
        fi
        PLUGIN_TARGETS+=("$(resolve_plugin_target "$2")")
        shift 2
        ;;
      --dir)
        if [[ $# -lt 2 ]]; then
          err "Missing value for --dir"
          usage
          return 1
        fi
        DIR_TARGETS+=("$(resolve_existing_path "$2")")
        ensure_within_project "${DIR_TARGETS[${#DIR_TARGETS[@]}-1]}"
        if [[ ! -d "${DIR_TARGETS[${#DIR_TARGETS[@]}-1]}" ]]; then
          err "Directory target does not exist: $2"
          return 1
        fi
        shift 2
        ;;
      --file)
        if [[ $# -lt 2 ]]; then
          err "Missing value for --file"
          usage
          return 1
        fi
        FILE_TARGETS+=("$(resolve_existing_path "$2")")
        ensure_within_project "${FILE_TARGETS[${#FILE_TARGETS[@]}-1]}"
        if [[ ! -f "${FILE_TARGETS[${#FILE_TARGETS[@]}-1]}" ]]; then
          err "File target does not exist: $2"
          return 1
        fi
        if [[ "${FILE_TARGETS[${#FILE_TARGETS[@]}-1]}" != *.qml ]]; then
          err "File target must be a .qml file: $2"
          return 1
        fi
        shift 2
        ;;
      --summary)
        OUTPUT_MODE="summary"
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      --*)
        err "Unknown flag: $1"
        usage
        return 1
        ;;
      *)
        err "Positional arguments are not supported: $1"
        usage
        return 1
        ;;
    esac
  done

  if [[ "${#PLUGIN_TARGETS[@]}" -eq 0 && "${#DIR_TARGETS[@]}" -eq 0 && "${#FILE_TARGETS[@]}" -eq 0 ]]; then
    err "At least one target flag is required."
    usage
    return 1
  fi
}

main() {
  local qmllint_bin=""
  local plugin_root=""
  local checked_groups=0
  local failed_groups=0
  local pass_groups=0
  local report_json=""

  parse_args "$@"
  validate_environment
  qmllint_bin="$(resolve_qmllint_bin)"
  ensure_jq_available

  cleanup
  TMP_ROOT="$(mktemp -d /tmp/noctalia-qmllint.XXXXXX)"
  trap cleanup EXIT

  collect_explicit_targets
  group_files_by_plugin_root
  build_import_shims

  for plugin_root in "${GROUPED_PLUGIN_ROOTS[@]}"; do
    checked_groups=$((checked_groups + 1))
    lint_plugin_group "${qmllint_bin}" "${plugin_root}" || true
    build_plugin_report "${plugin_root}"
    report_json="${PLUGIN_REPORT_JSONS["${plugin_root}"]}"
    if jq -e '.lintPassed' "${report_json}" > /dev/null; then
      pass_groups=$((pass_groups + 1))
    else
      failed_groups=$((failed_groups + 1))
    fi
  done

  if [[ "${OUTPUT_MODE}" == "summary" ]]; then
    emit_results_summary "${checked_groups}" "${pass_groups}" "${failed_groups}"
  else
    emit_results_json "${checked_groups}" "${pass_groups}" "${failed_groups}"
  fi

  if [[ "${failed_groups}" -gt 0 ]]; then
    return 1
  fi
}

main "$@"
