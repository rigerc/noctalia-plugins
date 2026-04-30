#!/bin/bash
#
# Runs qmllint against explicitly selected plugin files or directories.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly PROJECT_ROOT
readonly NOCTALIA_SHELL_DIR="${PROJECT_ROOT}/docs/noctalia-shell"
TMP_ROOT=""
OUTPUT_MODE="json"
JSON_OUTPUT_FILE=""

declare -a PLUGIN_TARGETS=()
declare -a DIR_TARGETS=()
declare -a FILE_TARGETS=()
declare -a RESOLVED_FILES=()
declare -a GROUPED_PLUGIN_ROOTS=()
declare -A SEEN_FILES=()
declare -A SEEN_PLUGIN_ROOTS=()
declare -A PLUGIN_FILE_LISTS=()
declare -A PLUGIN_RESULT_JSONS=()
declare -A PLUGIN_RESULT_STATUSES=()
declare -A PLUGIN_REPORT_JSONS=()

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [--plugin <plugin>] [--dir <directory>] [--file <file.qml>] [--summary] [--json-file <path>]

Required:
  At least one target flag must be provided.

Flags:
  --plugin <plugin>  Lint a plugin directory identified by name or path.
  --dir <directory>  Lint all .qml files under a plugin subdirectory.
  --file <file.qml>  Lint one specific .qml file inside a plugin.
  --summary          Print a compact human-readable summary instead of JSON.
  --json-file <path> Write the aggregated lint report to a JSON file.
  --help             Show this help message.

Output:
  Default: writes a JSON report to stdout containing all qmllint warnings and
  errors for each selected plugin group.
  --summary: prints finding totals and counts grouped by warning id.
  --json-file: writes the same aggregated report to the given file path.
  Exits non-zero if any selected plugin group has findings.
EOF
}

cleanup() {
  if [[ -n "${TMP_ROOT}" && -d "${TMP_ROOT}" ]]; then
    rm -rf "${TMP_ROOT}"
  fi
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

resolve_candidate_path() {
  local raw_path="$1"
  local resolved=""
  local project_candidate="${PROJECT_ROOT}/${raw_path}"

  if [[ -e "${project_candidate}" ]]; then
    resolved="$(realpath -e -- "${project_candidate}")"
  elif [[ -e "${raw_path}" ]]; then
    resolved="$(realpath -e -- "${raw_path}")"
  else
    return 1
  fi

  printf '%s\n' "${resolved}"
}

resolve_target_path() {
  local raw_target="$1"
  local target_label="$2"
  local candidate=""
  candidate="$(resolve_candidate_path "${raw_target}")" || {
    err "${target_label} does not exist: ${raw_target}"
    return 1
  }
  ensure_within_project "${candidate}" || return 1
  printf '%s\n' "${candidate}"
}

resolve_plugin_target() {
  local raw_target="$1"
  local resolved=""

  resolved="$(resolve_target_path "${raw_target}" "Plugin target")" || return 1

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

find_plugin_root_internal() {
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

  return 1
}

find_plugin_root() {
  local raw_path="$1"
  local plugin_root=""

  plugin_root="$(find_plugin_root_internal "${raw_path}")" || {
    err "No plugin root found for path: ${raw_path}"
    return 1
  }

  printf '%s\n' "${plugin_root}"
}

ensure_target_in_plugin_root() {
  local resolved_path="$1"
  local target_label="$2"
  local raw_target="$3"

  find_plugin_root_internal "${resolved_path}" > /dev/null || {
    err "${target_label} must be inside a plugin root: ${raw_target}"
    return 1
  }
}

resolve_directory_target() {
  local raw_target="$1"
  local resolved=""

  resolved="$(resolve_target_path "${raw_target}" "Directory target")" || return 1

  if [[ ! -d "${resolved}" ]]; then
    err "Directory target is not a directory: ${raw_target}"
    return 1
  fi

  ensure_target_in_plugin_root "${resolved}" "Directory target" "${raw_target}" || return 1
  printf '%s\n' "${resolved}"
}

resolve_file_target() {
  local raw_target="$1"
  local resolved=""

  resolved="$(resolve_target_path "${raw_target}" "File target")" || return 1

  if [[ ! -f "${resolved}" ]]; then
    err "File target is not a file: ${raw_target}"
    return 1
  fi

  if [[ "${resolved}" != *.qml ]]; then
    err "File target must be a .qml file: ${raw_target}"
    return 1
  fi

  ensure_target_in_plugin_root "${resolved}" "File target" "${raw_target}" || return 1
  printf '%s\n' "${resolved}"
}

resolve_output_file_path() {
  local raw_target="$1"
  local parent_dir=""
  local resolved_parent=""

  if [[ "${raw_target}" != /* ]]; then
    raw_target="${PROJECT_ROOT}/${raw_target}"
  fi

  parent_dir="$(dirname "${raw_target}")"
  mkdir -p "${parent_dir}" || {
    err "Could not create JSON output directory: ${parent_dir}"
    return 1
  }

  resolved_parent="$(realpath -e -- "${parent_dir}")"
  printf '%s\n' "${resolved_parent}/$(basename "${raw_target}")"
}


add_resolved_file() {
  local file_path="$1"

  if [[ -n "${SEEN_FILES["${file_path}"]+x}" ]]; then
    return 0
  fi

  SEEN_FILES["${file_path}"]=1
  RESOLVED_FILES+=("${file_path}")
}

collect_qml_files() {
  local path="$1"
  local label="$2"
  local found_any=0
  local file_path=""

  while IFS= read -r file_path; do
    found_any=1
    add_resolved_file "${file_path}"
  done < <(find "${path}" -type f -name '*.qml' | sort)

  if [[ "${found_any}" -eq 0 ]]; then
    err "No QML files found under ${label}: ${path}"
    return 1
  fi
}

collect_explicit_targets() {
  local plugin_root=""
  local dir_path=""
  local file_path=""

  for plugin_root in "${PLUGIN_TARGETS[@]}"; do
    collect_qml_files "${plugin_root}" "plugin"
  done

  for dir_path in "${DIR_TARGETS[@]}"; do
    collect_qml_files "${dir_path}" "directory"
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

  if [[ -n "${SEEN_PLUGIN_ROOTS["${plugin_root}"]+x}" ]]; then
    return 0
  fi

  SEEN_PLUGIN_ROOTS["${plugin_root}"]=1
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
  (
    echo "module ${module_name}"
    shopt -s nullglob
    for qml_file in "${source_dir}"/*.qml; do
      base_name="$(basename "${qml_file}")"
      type_name="${base_name%.qml}"
      first_line="$(head -n 1 "${qml_file}")"
      if [[ "${first_line}" == "pragma Singleton" ]]; then
        echo "singleton ${type_name} 1.0 ${base_name}"
      else
        echo "${type_name} 1.0 ${base_name}"
      fi
      ln -sfn "${qml_file}" "${module_dir}/${base_name}"
    done
  ) > "${module_dir}/qmldir"
}

build_import_shims() {
  local service_dir=""
  local service_name=""
  local sub_dir=""
  local sub_name=""

  mkdir -p "${TMP_ROOT}/qs/Services"
  ln -sfn "${NOCTALIA_SHELL_DIR}/Helpers" "${TMP_ROOT}/qs/Helpers"

  write_qmldir "${TMP_ROOT}/qs/Commons" "qs.Commons" "${NOCTALIA_SHELL_DIR}/Commons"
  write_qmldir "${TMP_ROOT}/qs/Widgets" "qs.Widgets" "${NOCTALIA_SHELL_DIR}/Widgets"

  for sub_dir in "${NOCTALIA_SHELL_DIR}/Commons"/*/; do
    [[ -d "${sub_dir}" ]] || continue
    compgen -G "${sub_dir}*.qml" > /dev/null || continue
    sub_name="$(basename "${sub_dir%/}")"
    write_qmldir \
      "${TMP_ROOT}/qs/Commons/${sub_name}" \
      "qs.Commons.${sub_name}" \
      "${sub_dir}"
  done

  for sub_dir in "${NOCTALIA_SHELL_DIR}/Widgets"/*/; do
    [[ -d "${sub_dir}" ]] || continue
    compgen -G "${sub_dir}*.qml" > /dev/null || continue
    sub_name="$(basename "${sub_dir%/}")"
    write_qmldir \
      "${TMP_ROOT}/qs/Widgets/${sub_name}" \
      "qs.Widgets.${sub_name}" \
      "${sub_dir}"
  done

  for service_dir in "${NOCTALIA_SHELL_DIR}"/Services/*; do
    [[ -d "${service_dir}" ]] || continue
    service_name="$(basename "${service_dir}")"
    if compgen -G "${service_dir}/*.qml" > /dev/null; then
      write_qmldir \
        "${TMP_ROOT}/qs/Services/${service_name}" \
        "qs.Services.${service_name}" \
        "${service_dir}"
    fi
    for sub_dir in "${service_dir}"/*/; do
      [[ -d "${sub_dir}" ]] || continue
      compgen -G "${sub_dir}*.qml" > /dev/null || continue
      sub_name="$(basename "${sub_dir%/}")"
      write_qmldir \
        "${TMP_ROOT}/qs/Services/${service_name}/${sub_name}" \
        "qs.Services.${service_name}.${sub_name}" \
        "${sub_dir}"
    done
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
  local group_file=""
  local report_json=""
  local lint_status="${PLUGIN_RESULT_STATUSES["${plugin_root}"]:-1}"

  group_file="${TMP_ROOT}/files.$(basename "${plugin_root}").txt"
  report_json="${TMP_ROOT}/report.$(basename "${plugin_root}").json"

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
      def diagnostics:
        [
          (.files // [])[]
          | .filename as $filename
          | (.warnings // [])[]
          | {
              plugin: $plugin,
              filename: $filename,
              line,
              column,
              id,
              message,
              severity: .type
            }
        ];
      def all_diagnostics:
        diagnostics;
      def warning_count:
        ((all_diagnostics | length) // 0);
      {
        plugin: $plugin,
        pluginRoot: $pluginRoot,
        selectedFiles: selected_files,
        lintPassed: ($lintExitCode == 0 and (warning_count == 0)),
        lintExitCode: $lintExitCode,
        selectedFileCount: (selected_files | length),
        warningCount: warning_count,
        severityCounts: (
          all_diagnostics
          | group_by(.severity)
          | map({key: .[0].severity, value: length})
          | from_entries
        ),
        warningCountsById: (
          all_diagnostics
          | group_by(.id)
          | map({key: .[0].id, value: length})
          | from_entries
        ),
        diagnostics: all_diagnostics,
        qmllint: .
      }
    ' "${result_json}" > "${report_json}"

  PLUGIN_REPORT_JSONS["${plugin_root}"]="${report_json}"
}

build_aggregate_report() {
  local checked_groups="$1"
  local pass_groups="$2"
  local failed_groups="$3"
  local aggregate_report="$4"
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
    ' "${report_files[@]}" > "${aggregate_report}"
}

write_json_artifact() {
  local source_json="$1"
  local destination_json="$2"

  jq '.' "${source_json}" > "${destination_json}" || {
    err "Could not write JSON output file: ${destination_json}"
    return 1
  }
}

emit_results_summary() {
  local aggregate_report="$1"
  local plugin_root=""
  local report_json=""

  echo "qmllint summary"
  jq -r '"selected files: " + (.selectedFileCount | tostring)' "${aggregate_report}"
  jq -r '"plugin groups: " + (.pluginGroupCount | tostring)' "${aggregate_report}"
  jq -r '"passed: " + (.passCount | tostring)' "${aggregate_report}"
  jq -r '"failed: " + (.failCount | tostring)' "${aggregate_report}"
  echo ""

  for plugin_root in "${GROUPED_PLUGIN_ROOTS[@]}"; do
    report_json="${PLUGIN_REPORT_JSONS["${plugin_root}"]}"

    jq -r '
      [
        (if .lintPassed then "PASS" else "FAIL" end),
        .plugin,
        "(" + (.selectedFileCount | tostring) + " file(s), " +
        (.warningCount | tostring) + " finding(s), " +
        "info=" + ((.severityCounts.info // 0) | tostring) + ", " +
        "warning=" + ((.severityCounts.warning // 0) | tostring) + ", " +
        "error=" + ((.severityCounts.error // 0) | tostring) + ")"
      ] | join(" ")
    ' "${report_json}"

    jq -r '
      .warningCountsById
      | to_entries
      | sort_by(.key)
      | .[]
      | "  " + .key + ": " + (.value | tostring)
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
        DIR_TARGETS+=("$(resolve_directory_target "$2")")
        shift 2
        ;;
      --file)
        if [[ $# -lt 2 ]]; then
          err "Missing value for --file"
          usage
          return 1
        fi
        FILE_TARGETS+=("$(resolve_file_target "$2")")
        shift 2
        ;;
      --summary)
        OUTPUT_MODE="summary"
        shift
        ;;
      --json-file)
        if [[ $# -lt 2 ]]; then
          err "Missing value for --json-file"
          usage
          return 1
        fi
        JSON_OUTPUT_FILE="$(resolve_output_file_path "$2")"
        shift 2
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
  local aggregate_report=""
  local report_json=""

  parse_args "$@"
  validate_environment
  qmllint_bin="$(resolve_qmllint_bin)"
  ensure_jq_available

  TMP_ROOT="$(mktemp -d /tmp/noctalia-qmllint.XXXXXX)"
  trap cleanup EXIT
  aggregate_report="${TMP_ROOT}/aggregate-report.json"

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

  build_aggregate_report \
    "${checked_groups}" \
    "${pass_groups}" \
    "${failed_groups}" \
    "${aggregate_report}"

  if [[ -n "${JSON_OUTPUT_FILE}" ]]; then
    write_json_artifact "${aggregate_report}" "${JSON_OUTPUT_FILE}"
  fi

  if [[ "${OUTPUT_MODE}" == "summary" ]]; then
    emit_results_summary "${aggregate_report}"
  else
    cat "${aggregate_report}"
  fi

  if [[ "${failed_groups}" -gt 0 ]]; then
    return 1
  fi
}

main "$@"
