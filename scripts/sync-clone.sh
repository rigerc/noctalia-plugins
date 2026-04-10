#!/bin/bash
#
# Clones Noctalia repos if absent, or pulls latest if they exist.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="${SCRIPT_DIR}/.."

declare -A REPOS
REPOS=(
  ["docs/examples/noctalia-plugins"]="https://github.com/noctalia-dev/noctalia-plugins.git"
  ["docs/noctalia-shell"]="https://github.com/noctalia-dev/noctalia-shell.git"
  ["docs/noctalia-docs"]="https://github.com/noctalia-dev/noctalia-docs.git"
)

sync_repo() {
  local target="$1"
  local repo="$2"
  local full_path="${PROJECT_ROOT}/${target}"

  if [[ -d "${full_path}/.git" ]]; then
    echo "Pulling ${target}..."
    git -C "${full_path}" pull
  else
    rm -rf "${full_path}"
    echo "Cloning ${repo} into ${target}..."
    git clone "${repo}" "${full_path}"
  fi
}

main() {
  for target in "${!REPOS[@]}"; do
    echo "=== ${target} ==="
    sync_repo "${target}" "${REPOS[${target}]}"
    echo ""
  done

  echo "All repos synced."
}

main "$@"
