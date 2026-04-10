#!/bin/bash
#
# Clones src/content/docs from the noctalia-dev/noctalia-docs repo into docs/,
# removing any existing copy first to ensure files are up to date.

set -euo pipefail

readonly REPO="https://github.com/noctalia-dev/noctalia-docs.git"
readonly SUBDIR="src/content/docs"
readonly TARGET_DIR="docs/noctalia-docs"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="${SCRIPT_DIR}/.."
readonly FULL_TARGET="${PROJECT_ROOT}/${TARGET_DIR}"
readonly TMP_DIR="${PROJECT_ROOT}/.tmp-noctalia-docs"

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

cleanup() {
  if [[ -d "${TMP_DIR}" ]]; then
    rm -rf "${TMP_DIR}"
  fi
}

main() {
  cleanup
  trap cleanup EXIT

  if [[ -d "${FULL_TARGET}" ]]; then
    echo "Removing existing ${TARGET_DIR}..."
    rm -rf "${FULL_TARGET}"
  fi

  echo "Cloning ${REPO} (sparse checkout for ${SUBDIR})..."
  git clone --depth 1 --filter=blob:none --sparse "${REPO}" "${TMP_DIR}"

  echo "Checking out ${SUBDIR}..."
  git -C "${TMP_DIR}" sparse-checkout set "${SUBDIR}"

  echo "Moving ${SUBDIR} to ${TARGET_DIR}..."
  mv "${TMP_DIR}/${SUBDIR}" "${FULL_TARGET}"

  cleanup
  trap - EXIT

  echo "Done. Docs synced to ${TARGET_DIR}."
}

main "$@"
