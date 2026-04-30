#!/bin/bash
#
# Runs targeted QML linting for Codex PostToolUse hook payloads.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly PROJECT_ROOT
readonly LINT_SCRIPT="${SCRIPT_DIR}/qmllint-plugins.sh"

if ! command -v jq > /dev/null 2>&1; then
  exit 0
fi

if [[ ! -x "${LINT_SCRIPT}" ]]; then
  exit 0
fi

INPUT_JSON="$(cat)"
if [[ -z "${INPUT_JSON}" ]]; then
  exit 0
fi

TOOL_NAME="$(printf '%s' "${INPUT_JSON}" | jq -r '.tool_name // .tool // empty')"
case "${TOOL_NAME}" in
  "" | "Bash" | "shell_command" | "exec_command")
    exit 0
    ;;
esac

collect_patch_paths() {
  local patch_text="$1"

  if [[ -z "${patch_text}" ]]; then
    return 0
  fi

  grep -E '^\*\*\* (Update|Add) File: .*\.qml$' <<< "${patch_text}" \
    | sed -E 's/^\*\*\* (Update|Add) File: //'
}

collect_json_paths() {
  printf '%s' "${INPUT_JSON}" | jq -r '
    [
      .tool_input.file_path?,
      .tool_input.path?,
      .tool_input.target_file?,
      .tool_input.new_file_path?,
      (.tool_input.paths[]?),
      (.tool_input.files[]?),
      (.tool_input.file_paths[]?),
      (.tool_input.edits[]?.file_path?),
      (.tool_input.operations[]?.path?),
      (.tool_input.operations[]?.file_path?)
    ]
    | flatten
    | map(select(type == "string"))
    | .[]
  '
}

resolve_qml_paths() {
  local raw_path=""

  while IFS= read -r raw_path; do
    [[ -n "${raw_path}" ]] || continue
    [[ "${raw_path}" == *.qml ]] || continue

    if [[ "${raw_path}" != /* ]]; then
      raw_path="${PROJECT_ROOT}/${raw_path}"
    fi

    if [[ -f "${raw_path}" ]]; then
      realpath -e -- "${raw_path}"
    fi
  done
}

PATCH_TEXT="$(printf '%s' "${INPUT_JSON}" | jq -r '
  .tool_input.patch
  // .tool_input.input
  // .tool_input.text
  // ""
')"

declare -a QML_FILES=()
mapfile -t QML_FILES < <(
  {
    collect_json_paths
    collect_patch_paths "${PATCH_TEXT}"
  } | resolve_qml_paths | sort -u
)

if [[ "${#QML_FILES[@]}" -eq 0 ]]; then
  exit 0
fi

declare -a CMD=("${LINT_SCRIPT}" "--summary")
for qml_file in "${QML_FILES[@]}"; do
  CMD+=("--file" "${qml_file}")
done

if ! "${CMD[@]}"; then
  printf 'PostToolUse qmllint found issues in edited QML files.\n' >&2
fi

exit 0
