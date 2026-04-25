#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ----------------------------------------------------------------------
# Purpose: Install only the tkginstaller script into a standard bin path
# Usage:   ./install.sh [--uninstall]
# ----------------------------------------------------------------------

_pkgname="tkginstaller"
_srcdir="/usr/bin"
_source="https://raw.githubusercontent.com/damachine/tkginstaller/master/tkginstaller"
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
  --uninstall       Remove installed script
  -h, --help        Show this help

Examples:
  sudo ./install.sh
  sudo ./install.sh --uninstall
EOF
}

parse_args() {
  while (($#)); do
    case "$1" in
      --uninstall | -u)
        _mode="uninstall"
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        msg_error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

cleanup() {
  if [[ -n "${_tmpfile}" && -f "${_tmpfile}" ]]; then
    rm -f -- "${_tmpfile}"
  fi
}

install() {
  local _pkgdir
  _pkgdir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

  if [[ ! -f "${_pkgdir}/${_pkgname}" ]]; then
    command -v curl >/dev/null 2>&1 || {
      msg_error "Local source missing and curl is required for download fallback"
      exit 1
    }

    _tmpfile="$(mktemp)"
    msg_info "Local source not found, downloading ${_pkgname}"
    curl -fsSL "$_source" -o "${_tmpfile}"
    msg_info "Installing ${_pkgname} -> ${_srcdir}/${_pkgname}"
    install -Dm755 "${_tmpfile}" "${_srcdir}/${_pkgname}"
    msg_info "Done"
    return
  fi

  msg_info "Installing ${_pkgname}"
  install -Dm755 "${_pkgdir}/${_pkgname}" "${_srcdir}/${_pkgname}"
  msg_info "Done"
}

uninstall() {
  if [[ -e "${_srcdir}/${_pkgname}" ]]; then
    msg_info "Removing ${_pkgname}"
    rm -f -- "${_srcdir}/${_pkgname}"
    msg_info "Done"
  else
    msg_info "Nothing to remove: ${_srcdir}/${_pkgname}"
  fi
}

main() {
  local _mode="install"
  trap cleanup EXIT
  parse_args "$@"

  if [[ "$_mode" == "uninstall" ]]; then
    uninstall
  else
    install
  fi
}

main "$@"
