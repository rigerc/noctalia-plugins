#!/bin/bash
#
# Clones the noctalia-dev/noctalia-plugins repo into docs/examples/,
# removing any existing copy first to ensure files are up to date.

set -euo pipefail

readonly REPO="https://github.com/noctalia-dev/noctalia-plugins.git"
readonly TARGET_DIR="docs/examples/noctalia-plugins"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FULL_TARGET="${SCRIPT_DIR}/../${TARGET_DIR}"

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

main() {
  if [[ -d "${FULL_TARGET}" ]]; then
    echo "Removing existing ${TARGET_DIR}..."
    rm -rf "${FULL_TARGET}"
  fi

  echo "Cloning ${REPO} into ${TARGET_DIR}..."
  git clone "${REPO}" "${FULL_TARGET}"

  echo "Removing .git directory..."
  rm -rf "${FULL_TARGET}/.git"

  echo "Done. Examples synced to ${TARGET_DIR}."
}

main "$@"
