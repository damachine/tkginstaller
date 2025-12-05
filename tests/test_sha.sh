#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ----------------------------------------------------------------------
# Script: test_sha.sh
# Purpose: Update SHA256SUMS file for tkginstaller
# Usage:   ./test_sha.sh
# ----------------------------------------------------------------------

main() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="${script_dir}/.."
    local tkginstaller="${project_root}/tkginstaller"
    local sha_file="${project_root}/SHA256SUMS"

    if [[ ! -f "$tkginstaller" ]]; then
        echo "Error: tkginstaller not found at $tkginstaller" >&2
        exit 1
    fi

    echo "Calculating SHA256 checksum..."
    cd "$project_root" || exit 1
    sha256sum tkginstaller > SHA256SUMS

    echo "✓ SHA256SUMS updated"
    cat SHA256SUMS
}

main "$@"
