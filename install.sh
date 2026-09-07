#!/usr/bin/env bash

# Maintainer: Christian Kühn (damachin3 at proton dot me)
# website: https://github.com/damachine/tkginstaller

set -euo pipefail

readonly _pkgname="tkginstaller"
readonly _target="/usr/bin/${_pkgname}"
readonly _bash_completion_target="/usr/share/bash-completion/completions/${_pkgname}.bash"
readonly _zsh_completion_target="/usr/share/zsh/site-functions/_${_pkgname}"
readonly _source_base="https://raw.githubusercontent.com/damachine/tkginstaller/refs/heads/master"
declare -a _tmpfiles=()
_resolved_source=""

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
  ((${#_tmpfiles[@]} == 0)) || rm -f -- "${_tmpfiles[@]}"
}

_resolve_source() {
  local _srcdir="$1"
  local _relative_path="$2"

  if [[ -n "${_srcdir}" && -f "${_srcdir}/${_relative_path}" ]]; then
    _resolved_source="${_srcdir}/${_relative_path}"
    return
  fi

  command -v curl >/dev/null 2>&1 || {
    msg_error "Local source missing and curl is required for download fallback"
    return 1
  }

  _resolved_source="$(mktemp)"
  _tmpfiles+=("${_resolved_source}")
  msg_info "Downloading ${_relative_path}"
  curl -fsSL "${_source_base}/${_relative_path}" -o "${_resolved_source}"
}

_install() {
  local _srcdir=""
  local _source_file _bash_completion_file _zsh_completion_file

  # Prefer repository files when this installer is run locally.
  if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    _srcdir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  fi

  _resolve_source "${_srcdir}" "${_pkgname}"
  _source_file="${_resolved_source}"
  _resolve_source "${_srcdir}" "completions/${_pkgname}.bash"
  _bash_completion_file="${_resolved_source}"
  _resolve_source "${_srcdir}" "completions/_${_pkgname}"
  _zsh_completion_file="${_resolved_source}"

  msg_info "Installing ${_pkgname} -> ${_target}"
  install -Dm755 -- "${_source_file}" "${_target}"
  msg_info "Installing Bash completion -> ${_bash_completion_target}"
  install -Dm644 -- "${_bash_completion_file}" "${_bash_completion_target}"
  msg_info "Installing Zsh completion -> ${_zsh_completion_target}"
  install -Dm644 -- "${_zsh_completion_file}" "${_zsh_completion_target}"
  msg_info "Done"
}

_uninstall() {
  local -a _targets=("${_target}" "${_bash_completion_target}" "${_zsh_completion_target}")
  local _removed=false
  local _file

  for _file in "${_targets[@]}"; do
    if [[ -e "${_file}" || -L "${_file}" ]]; then
      msg_info "Removing ${_file}"
      rm -f -- "${_file}"
      _removed=true
    fi
  done

  if [[ "${_removed}" == false ]]; then
    msg_info "Nothing to remove"
    return
  fi

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
