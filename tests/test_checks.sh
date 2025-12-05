#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ----------------------------------------------------------------------
# Script: validate.sh
# Purpose: Run syntax and lint checks on tkginstaller
# Usage:   ./validate.sh
# ----------------------------------------------------------------------

main() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local tkginstaller="${script_dir}/../tkginstaller"

    if [[ ! -f "$tkginstaller" ]]; then
        echo "Error: tkginstaller not found at $tkginstaller" >&2
        exit 1
    fi

    echo "Running bash syntax check..."
    bash -n "$tkginstaller"

    echo "Running shellcheck..."
    shellcheck "$tkginstaller"

    echo "✓ All checks passed"
}

main "$@"
