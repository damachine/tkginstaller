#!/usr/bin/env bash

# Maintainer: Christian Kühn (damachin3 at proton dot me)
# website: https://github.com/damachine/tkginstaller

set -euo pipefail

readonly _pkgname="tkginstaller"
readonly _target="/usr/bin/${_pkgname}"
readonly _source="https://raw.githubusercontent.com/damachine/tkginstaller/refs/heads/master/${_pkgname}"
_tmpfile=""

msg_info() {
  printf '==> %s\n' "$*"
}

msg_error() {
  printf 'ERROR: %s\n' "$*" >&2
}

usage() {
  cat <<'EOF'
Usage: ./install.sh [OPTIONS]

Options:
  -u, --uninstall   Remove installed script
  -h, --help        Show this help

Examples:
  sudo ./install.sh
  sudo ./install.sh --uninstall
EOF
}

cleanup() {
  [[ -z "${_tmpfile}" ]] || rm -f -- "${_tmpfile}"
}

_install() {
  local _source_file=""

  # Prefer the repository copy only when this installer is a local file.
  if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    local _srcdir
    _srcdir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    [[ ! -f "${_srcdir}/${_pkgname}" ]] || _source_file="${_srcdir}/${_pkgname}"
  fi

  if [[ -z "${_source_file}" ]]; then
    command -v curl >/dev/null 2>&1 || {
      msg_error "Local source missing and curl is required for download fallback"
      return 1
    }

    _tmpfile="$(mktemp)"
    msg_info "Local source not found, downloading ${_pkgname}"
    curl -fsSL "${_source}" -o "${_tmpfile}"
    _source_file="${_tmpfile}"
  fi

  msg_info "Installing ${_pkgname} -> ${_target}"
  install -Dm755 -- "${_source_file}" "${_target}"
  msg_info "Done"
}

_uninstall() {
  if [[ ! -e "${_target}" && ! -L "${_target}" ]]; then
    msg_info "Nothing to remove: ${_target}"
    return
  fi

  msg_info "Removing ${_target}"
  rm -f -- "${_target}"
  msg_info "Done"
}

main() {
  trap cleanup EXIT

  if (($# > 1)); then
    msg_error "Too many arguments"
    usage
    return 2
  fi

  if (($# == 0)); then
    _install
    return
  fi

  case "$1" in
    -u | --uninstall) _uninstall ;;
    -h | --help) usage ;;
    *)
      msg_error "Unknown option: $1"
      usage
      return 2
      ;;
  esac
}

main "$@"
