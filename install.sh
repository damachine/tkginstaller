#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# author : damachine (christkue79 at gmail dot com)
# website: https://github.com/damachine
#          https://github.com/damachine/tkginstaller
# -----------------------------------------------------------------------------
# MIT License
#
# Copyright (c) 2025 damachine
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# -----------------------------------------------------------------------------
# INFO:
#   Installation script for TKG-Installer
# DESCRIPTION:
#   This script automates the installation of TKG-Installer with integrity verification.
#   It downloads the latest version from the official repository, verifies the checksum,
#   and sets up a shell alias for easy access.
# USAGE:
#   Simply run this script using cURL:
#   curl -fsSL https://raw.githubusercontent.com/damachine/tkginstaller/master/install.sh | bash
# -----------------------------------------------------------------------------

# shellcheck disable=SC2218 # Allow usage of printf with variable format strings
set -e

# Initialize color and style (copied from tkginstaller)
__init_style() {
    _break=$'\n'
    _reset=$'\033[0m'
    __color() {
        local r=${1:-255} g=${2:-255} b=${3:-255} idx=${4:-7}
        if [[ "${COLORTERM,,}" == *truecolor* || "${COLORTERM,,}" == *24bit* ]]; then
            printf '\033[38;2;%d;%d;%dm' "$r" "$g" "$b"
            return 0
        fi
        if command -v tput >/dev/null 2>&1; then
            local _tput_seq
            _tput_seq=$(tput sgr0; tput setaf "$idx")
            printf '%s' "${_tput_seq}"
            return 0
        fi
        local _idx256
        case "$idx" in
            1) _idx256=196 ;;  # bright red
            2) _idx256=118 ;;  # light green
            3) _idx256=214 ;;  # orange/yellow
            4) _idx256=39  ;;  # bright blue
            *) _idx256=15  ;;  # white
        esac
        printf '\033[38;5;%dm' "$_idx256"
    }

    # Define TrueColor values, fallback to tput
    _red="$(__color 220 60 60 1)"           # warm red
    _green_light="$(__color 80 255 140 2)"  # light green
    _green_neon="$(__color 120 255 100 2)"  # neon green
    _green_mint="$(__color 152 255 200 6)"  # mint green
    _green_dark="$(__color 34 68 34 2)"     # dark green (#224422)
    _orange="$(__color 255 190 60 3)"       # orange/yellow
    _gray="$(__color 200 250 200 7)"        # gray

    # Draw underline
    _uline_on=$(tput smul 2>/dev/null || printf '\033[4m')
    _uline_off=$(tput rmul 2>/dev/null || printf '\033[24m')
}

# Initialize colors
__init_style

# Configuration
_tkg_repo_url="https://raw.githubusercontent.com/damachine/tkginstaller/master"
_tkg_install_dir="${HOME}/.tkginstaller"
_tkg_script_name="tkginstaller"

# Functions
__msg_info() { printf '%b\n' "${_green_light}$*${_reset}"; }
__msg_error() { printf '%b\n' "${_red}ERROR: $*${_reset}"; }
__msg_warning() { printf '%b\n' "${_orange}WARNING: $*${_reset}"; }
__msg_step() { printf '%b\n' "${_gray} ➜➜ $*${_reset}"; }
__msg_prompt() { printf '%b\n' "$*"; }

__banner() {
    local __color="${1:-$_green_neon}"
    printf '%b\n' "${__color}"
    cat << "EOF"
░▀█▀░█░█░█▀▀░░░░░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░░█▀▀░█▀▄
░░█░░█▀▄░█░█░▄▄▄░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░░█▀▀░█▀▄
░░▀░░▀░▀░▀▀▀░░░░░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀
──  KISS the 🐸 ──
EOF
    printf '%b\n' "${_reset}"
}

# Check for root
if [[ "$(id -u)" -eq 0 ]]; then
    __banner "$_orange"
    __msg_warning "You are running as root!${_break}"
    __msg_prompt " Running this script as root is not recommended for security reasons.${_break}"
    __msg_prompt "Do you really want to continue as root? [y/N]: "
    trap 'echo;echo; __msg_prompt "${_red}Aborted by user.\n";sleep 1.5s; exit 1' INT
    read -r _user_answer
    trap - INT
    if [[ ! "$_user_answer" =~ ^([yY]|[yY][eE][sS])$ ]]; then
        __msg_prompt "${_red}Aborted by user.${_break}"
        exit 1
    fi
fi

__cleanup() {
    cd "$OLDPWD" 2>/dev/null || true
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap __cleanup EXIT INT TERM

# Main installation
__main() {
    # Welcome message
    __banner
    printf "%s" "${_green_neon}Starting installation"
    for _ in {1..3}; do
        printf " ."
        sleep 0.3s
    done
    printf "%b\n" "${_break}${_reset}"

    # Check dependencies
    __msg_step "Checking dependencies..."
    for cmd in curl sha256sum; do
        if ! command -v "$cmd" &>/dev/null; then
            __msg_error "$cmd is not installed!"
            exit 1
        fi
    done
    __msg_info "[✓] Dependencies OK${_break}"

    # Create installation directory
    __msg_step "Creating installation directory: $_tkg_install_dir"
    mkdir -p "$_tkg_install_dir"

    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # Download files
    __msg_step "Downloading tkginstaller..."
    if ! curl -fsSL "${_tkg_repo_url}/${_tkg_script_name}" -o "${_tkg_script_name}"; then
        __msg_error "Failed to download tkginstaller"
        exit 1
    fi

    __msg_step "Downloading checksum..."
    if curl -fsSL "${_tkg_repo_url}/SHA256SUMS" -o "SHA256SUMS" 2>/dev/null; then
        __msg_info "[✓] Download complete${_break}"
    
        __msg_step "Verifying integrity..."
        if sha256sum -c "SHA256SUMS" 2>&1 | grep -q "OK"; then
            __msg_info "[✓] Checksum verification successful!${_break}"
        else
            __msg_error "Checksum verification FAILED!${_break}"
            __msg_warning "The downloaded file does not match the expected checksum."
            __msg_warning "This could indicate:"
            __msg_warning " - File corruption during download"
            __msg_warning " - Security compromise"
            __msg_warning " - Network issues${_break}"
            __msg_error "Installation aborted for security reasons."
            exit 1
        fi
    else
        __msg_warning "Checksum file not available (expected for development versions)"
        __msg_warning "Skipping integrity verification${_break}"
    fi

    # Move to installation directory
    __msg_step "Installing to: $_tkg_install_dir"
    mv "${_tkg_script_name}" "${_tkg_install_dir}/"
    mv "SHA256SUMS" "${_tkg_install_dir}/"
    chmod +x "${_tkg_install_dir}/${_tkg_script_name}"
    __msg_info "[✓] Installation complete${_break}"

    # Setup shell alias
    __msg_step "Setting up shell alias..."
    
    # Detect shell - prioritize $SHELL variable (most reliable)
    SHELL_RC=""
    CURRENT_SHELL="$(basename "${SHELL}")"
    
    case "$CURRENT_SHELL" in
        zsh)
            SHELL_RC="${HOME}/.zshrc"
            ;;
        bash)
            SHELL_RC="${HOME}/.bashrc"
            ;;
        *)
            # Fallback: check shell version variables
            if [[ -n "${ZSH_VERSION:-}" ]]; then
                SHELL_RC="${HOME}/.zshrc"
            elif [[ -n "${BASH_VERSION:-}" ]]; then
                SHELL_RC="${HOME}/.bashrc"
            fi
            ;;
    esac

    if [[ -n "$SHELL_RC" ]]; then
        # Check if alias already exists
        if grep -q "alias ${_tkg_script_name}=" "$SHELL_RC" 2>/dev/null; then
            __msg_info "[✓] Alias already exists in $SHELL_RC"
        else
            # Append alias to shell RC file in a single here-doc block
            cat >> "$SHELL_RC" <<EOF

# TKG-Installer alias
alias ${_tkg_script_name}='${_tkg_install_dir}/${_tkg_script_name}'
EOF
            __msg_info "[✓] Alias added to $SHELL_RC"
        fi
    else
        __msg_warning "Could not detect shell configuration file."
        __msg_warning "Add this manually to your shell config:"
        __msg_prompt " ${_gray}alias ${_tkg_script_name}='${_tkg_install_dir}/${_tkg_script_name}'${_reset}${_break}"
    fi

    # Clean temp dir
    __cleanup

    __msg_info "${_break}${_break}${_green_neon}${_uline_on}INSTALLATION SUCCESSFUL!${_uline_off}${_reset}${_break}${_break}"
    __msg_prompt "${_green_neon}${_uline_on}Next steps${_uline_off}:${_reset}"
    __msg_prompt "1) Reload your shell config:"

    if [[ -n "$SHELL_RC" ]]; then
        __msg_prompt "   ${_gray}source $SHELL_RC${_reset}${_break}"
    fi
    
    __msg_prompt "2) Run the installer:"
    __msg_prompt "   ${_gray}${_tkg_script_name}${_reset}${_break}"
    __msg_prompt "Documentation: ${_gray}https://github.com/damachine/tkginstaller${_reset}${_break}"
}

# Run main
__main