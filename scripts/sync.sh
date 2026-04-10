#!/bin/bash
#
# Runs all sync scripts to update local copies of Noctalia repos.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

main() {
  echo "=== Syncing examples ==="
  "${SCRIPT_DIR}/sync-examples.sh"

  echo ""
  echo "=== Syncing shell source ==="
  "${SCRIPT_DIR}/sync-shell-source.sh"

  echo ""
  echo "=== Syncing docs ==="
  "${SCRIPT_DIR}/sync-docs.sh"

  echo ""
  echo "All syncs complete."
}

main "$@"
