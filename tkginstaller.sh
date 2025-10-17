#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# author: damachine (christkue79@gmail.com)
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
#   TKG-Installer
#   Easily build the TKG packages from the Frogging-Family repositories.
# DESCRIPTION:
#   This script handles building, installation and configuration for TKG/Frogminer packages.
#   It uses color output and Unicode icons for better readability.
#   Do not run as root. Use a dedicated user for security.
#   See https://github.com/damachine/tkginstaller for details.
# USAGE:
#   Interactive (Menu-mode) Run the script without arguments to enter the menu:
#       run: tkginstaller
#   Command-line (Direct-mode) Skip the menu and run specific actions directly:
#       run: tkginstaller linux          # Install Linux-TKG
#       run: tkginstaller linux config   # Edit Linux-TKG config
#   Show all available commands and shortcuts!
#       run: tkginstaller help
# -----------------------------------------------------------------------------

# Fuzzy finder run in a separate shell (subshell) - export variables for fzf
# shellcheck disable=SC2016
# shellcheck disable=SC2218

# TKG-Installer VERSION
readonly _TKG_INSTALLER_VERSION="v0.13.2"

# Lock file to prevent concurrent execution
readonly _LOCK_FILE="/tmp/tkginstaller.lock"

# =============================================================================
# INITIALIZATION FUNCTIONS
# =============================================================================

# Initialize global variables, paths, and configurations
__init_globals() {
    # Global paths and configuration
    _TMP_DIR="$HOME/.cache/tkginstaller"
    _CHOICE_FILE="${_TMP_DIR}/choice.tmp"
    _CONFIG_DIR="$HOME/.config/frogminer"
    _TKG_REPO="https://github.com/damachine/tkginstaller"
    _TKG_RAW_URL="https://raw.githubusercontent.com/damachine/tkginstaller/refs/heads/master/docs"
    _FROGGING_FAMILY_REPO="https://github.com/Frogging-Family"
    _FROGGING_FAMILY_RAW_URL="https://raw.githubusercontent.com/Frogging-Family"

    # Export variables for fzf subshells (unset __exit run)
    export _TMP_DIR _CHOICE_FILE _CONFIG_DIR _TKG_REPO _TKG_RAW_URL _FROGGING_FAMILY_REPO _FROGGING_FAMILY_RAW_URL
}

# Initialize color and formatting definitions
__init_colors() {
    # Formatting and color definitions
    _ECHO="echo -e"
    _BREAK="\n"
    _LINE="──────────────────────────────────────────────────────────────────────────────────────────"
    _RESET=$"\033[0m"
    _BOLD=$"\033[1m"
    _RED=$"\033[0;31m"
    _GREEN=$"\033[0;32m"
    _YELLOW=$"\033[0;33m"
    _BLUE=$"\033[0;34m"

    # Export variables for fzf subshells (unset __exit run)
    export _ECHO _BREAK _LINE _RESET _BOLD _RED _GREEN _YELLOW _BLUE
}

# =============================================================================
# ENVIRONMENT SETUP
# =============================================================================

# Safety settings and strict mode
#set -euo pipefail # Uncomment to enable strict mode (may cause issues with some commands)

# Force standard locale for consistent behavior (sorting, comparisons, messages)
#export LC_ALL=C # Uncomment if locale issues arise

# Initialize globals and colors
__init_globals
__init_colors

# Check for root execution
if [[ "$(id -u)" -eq 0 ]]; then
    ${_ECHO} "${_RED}${_BOLD}${_BREAK} ❌ Warning: You are running as root!${_BREAK}${_RESET}"
    read -r -p "Do you really want to continue as root? [y/N]: " allow_root
    if [[ ! "$allow_root" =~ ^(y|Y|yes|Yes|YES)$ ]]; then
        ${_ECHO} "${_RED}${_BOLD}${_BREAK} ❌ Aborted. Please run as a regular user.${_BREAK}${_RESET}"
        exit 1
    fi
fi

# Detect Linux Distribution
if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091 # Source file is system-dependent and may not exist on all systems
    . /etc/os-release
    export _distro_name="$NAME"
    export _distro_id="${ID:-unknown}"
    export _distro_like="${ID_LIKE:-}"
else
    export _distro_name="Unknown"
    export _distro_id="unknown"
    export _distro_like=""
fi

# Help information display
__help() {
    ${_ECHO} "${_LINE}${_BREAK}${_GREEN} 🛈 TKG-Installer Help${_BREAK}${_RESET}"
    ${_ECHO} "${_BLUE} Run interactive fzf finder menu.${_RESET}"
    ${_ECHO} "${_GREEN} Interactive:${_RESET} $0"
    ${_ECHO} ""
    ${_ECHO} "${_BLUE} Run directly without entering the menu.${_RESET}"
    ${_ECHO} "${_GREEN} Syntax:${_RESET} $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p]"
    ${_ECHO} "${_YELLOW} Example:${_RESET}"
    ${_ECHO} "  $0 linux         # Install Linux-TKG"
    ${_ECHO} "  $0 nvidia        # Install Nvidia-TKG"
    ${_ECHO} "  $0 mesa          # Install Mesa-TKG"
    ${_ECHO} "  $0 wine          # Install Wine-TKG"
    ${_ECHO} "  $0 proton        # Install Proton-TKG"
    ${_ECHO} ""
    ${_ECHO} "${_BLUE} Access configuration files directly without entering the menu.${_RESET}"
    ${_ECHO} "${_GREEN} Syntax:${_RESET} $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p] [config|c|edit|e]"
    ${_ECHO} "${_GREEN}        ${_RESET} $0 [config|c|edit|e] [linux|l|nvidia|n|mesa|m|wine|w|proton|p]"
    ${_ECHO} "${_YELLOW} Example:${_RESET}"
    ${_ECHO} "  $0 linux config  # Edit Linux-TKG config"
    ${_ECHO} "  $0 config linux  # Edit Linux-TKG config"
    ${_ECHO} ""
    ${_ECHO} "${_YELLOW} Shortcuts:${_RESET} l=linux, n=nvidia, m=mesa, w=wine, p=proton, c=config, e=edit"
    ${_ECHO} "${_LINE}${_RESET}"
}

# Help can show always
if [[ $# -gt 0 && "${1:-}" =~ ^(help|h|-h|--help)$ ]]; then
    __help
fi

# Prevent concurrent execution (after help check)
if [[ -f "$_LOCK_FILE" ]]; then
    # Check if the process is still running
    if [[ -r "$_LOCK_FILE" ]]; then
        _old_pid=$(cat "$_LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$_old_pid" ]] && kill -0 "$_old_pid" 2>/dev/null; then
            ${_ECHO} ""
            ${_ECHO} "${_RED}${_BOLD} ❌ Script is already running (PID: $_old_pid). Exiting...${_RESET}"
            ${_ECHO} "${_YELLOW}${_BOLD} 🔁 If the script was unexpectedly terminated, remove the lock file manually:${_RESET}${_BREAK}${_BREAK}    tkginstaller clean|c to remove the $_LOCK_FILE${_BREAK}${_RESET}"
            exit 1
        else
            ${_ECHO} ""
            ${_ECHO} "${_YELLOW} 🔁 Removing stale lock file...${_BREAK}${_RESET}"
            rm -f "$_LOCK_FILE" 2>/dev/null || {
                ${_ECHO} "${_RED}${_BOLD} ❌ Error removing stale lock file! Exiting...${_RESET}"
                exit 1
            }
        fi
    fi
fi
echo $$ > "$_LOCK_FILE"

# =============================================================================
# CORE UTILITY FUNCTIONS
# =============================================================================

# Cleanup handler for graceful exit
__clean() {
    rm -f "$_LOCK_FILE" 2>/dev/null || true
    rm -f "$_CHOICE_FILE" 2>/dev/null || true
    rm -rf "$_TMP_DIR" 2>/dev/null || true

    # Unset exported variables
    unset _TMP_DIR _CHOICE_FILE _CONFIG_DIR _TKG_REPO _TKG_RAW_URL _FROGGING_FAMILY_REPO _FROGGING_FAMILY_RAW_URL
    unset _ECHO _BREAK _LINE _RESET _BOLD _RED _GREEN _YELLOW _BLUE
    unset _preview_linux _preview_nvidia _preview_mesa _preview_wine _preview_proton
    unset _preview_config _preview_clean _preview_help _preview_return _preview_exit _glow_style
    unset _distro_name _distro_id _distro_like
 }

# Setup exit trap for cleanup on script termination
__exit() {
    local _exit_code=${1:-$?}
    trap - INT TERM EXIT HUP

    # Message handling
    if [[ $_exit_code -ne 0 ]]; then
        ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} 🎯 ERROR 🎯 TKG-Installer aborted! Exiting...${_BREAK}${_LINE}${_BREAK}${_RESET}"
    else
        ${_ECHO} "${_GREEN} 🧹 Cleanup completed!${_RESET}"
        ${_ECHO} "${_GREEN} 👋 TKG-Installer closed!${_RESET}"
        ${_ECHO} "${_GREEN}${_LINE}${_BREAK}${_RESET}"
    fi

    # Perform cleanup
    __clean
    wait
    exit "$_exit_code"
}
trap __exit INT TERM EXIT HUP

# Fuzzy finder menu wrapper function
__fzf_menu() {
    local _menu_content="$1"
    local _preview_command="$2"
    local _header_text="$3"
    local _footer_text="$4"
    local _border_label_text="${5:-$_TKG_INSTALLER_VERSION}"
    local _preview_window_settings="${6:-right:nowrap:60%}"

    fzf \
        --with-shell='bash -c' \
        --style minimal \
        --color='header:#00ff00,pointer:#00ff00,marker:#00ff00' \
        --border=none \
        --border-label="${_border_label_text}" \
        --layout=reverse \
        --highlight-line \
        --height='-1' \
        --padding=0 \
        --ansi \
        --delimiter='|' \
        --with-nth='2' \
        --no-extended \
        --no-input \
        --no-multi \
        --no-multi-line \
        --pointer='🐸' \
        --header="${_header_text}" \
        --header-border=line \
        --header-label="${_border_label_text}" \
        --header-label-pos=256 \
        --header-first \
        --footer="${_footer_text}" \
        --footer-border=line \
        --preview-window="${_preview_window_settings}" \
        --preview="${_preview_command}" \
        --disabled \
        <<< "${_menu_content}"
}

# Display completion status with timestamp
__done() {
    local _status=${1:-$?} # Use passed status, fallback to $? for compatibility
    local _duration="${SECONDS:-0}"
    local _minutes=$((_duration / 60))
    local _seconds=$((_duration % 60))

    ${_ECHO} "${_GREEN}${_LINE}${_BREAK}${_RESET}${_YELLOW} 📝 Action completed: $(date '+%Y-%m-%d %H:%M:%S')${_RESET}"

    if [[ $_status -eq 0 ]]; then
        ${_ECHO} "${_GREEN} ✅ Status: Successful${_RESET}"
    else
        ${_ECHO} "${_RED}${_BOLD} ❌ Status: Error (Code: $_status)${_RESET}"
    fi

    ${_ECHO} "${_YELLOW} ⏱️ Duration: ${_minutes} min ${_seconds} sec${_RESET}${_GREEN}${_BREAK}${_LINE}${_RESET}"
    return "$_status"
}

# Pre-installation checks and preparation
__pre() {
    local _load_preview="${1:-false}"

    # Welcome message
    ${_ECHO} "${_GREEN}${_LINE}${_BREAK} 🐸 TKG-Installer ${_TKG_INSTALLER_VERSION} for ${_distro_name}${_BREAK}${_LINE}${_RESET}"
    ${_ECHO} "${_YELLOW} 🔁 Pre-checks starting...${_RESET}"

    # Check required dependencies
    local _dependencies=(git)
    if [[ "$_load_preview" == "true" ]]; then
        _dependencies+=(bat curl glow fzf)
    fi

    # Define package names per distro
    declare -A _pkg_map
    case "${_distro_id,,}" in
        arch|manjaro|endeavouros|cachyos)
            _pkg_map=(
                [git]=git
                [bat]=bat
                [curl]=curl
                [glow]=glow
                [fzf]=fzf
            )
            _install_cmd="pacman -S"
            ;;
        fedora)
            _pkg_map=(
                [git]=git
                [bat]=bat
                [curl]=curl
                [glow]=glow
                [fzf]=fzf
            )
            _install_cmd="dnf install"
            ;;
        opensuse*|suse*)
            _pkg_map=(
                [git]=git
                [bat]=bat
                [curl]=curl
                [glow]=glow
                [fzf]=fzf
            )
            _install_cmd="zypper install"
            ;;
        gentoo)
            _pkg_map=(
                [git]=dev-vcs/git
                [bat]=app-misc/bat
                [curl]=net-misc/curl
                [glow]=app-text/glow
                [fzf]=app-misc/fzf
            )
            _install_cmd="emerge"
            ;;
        ubuntu|debian|linuxmint|pop|elementary)
            _pkg_map=(
                [git]=git
                [bat]=bat
                [curl]=curl
                [glow]=glow
                [fzf]=fzf
            )
            _install_cmd="apt install"
            ;;
        *)
            # Default: show generic names
            _pkg_map=(
                [git]=git
                [bat]=bat
                [curl]=curl
                [glow]=glow
                [fzf]=fzf
            )
            _install_cmd="your-package-manager install"
            ;;
    esac

    local _missing_deps=()
    for _required_dependency in "${_dependencies[@]}"; do
        if ! command -v "$_required_dependency" >/dev/null; then
            _missing_deps+=("$_required_dependency")
        fi
    done

    # Exit if any dependencies are missing
    if [[ ${#_missing_deps[@]} -gt 0 ]]; then
        ${_ECHO} "${_RED}${_BOLD} ❌ Please install this first...${_BREAK}    The following dependencies are missing:${_BREAK}${_RESET}"
        for _dep in "${_missing_deps[@]}"; do
            local _pkg_name="${_pkg_map[$_dep]:-$_dep}"
            ${_ECHO} "${_YELLOW}${_BOLD}    - ${_dep}:${_RESET} ${_install_cmd} ${_pkg_name}${_RESET}"
        done
        ${_ECHO} "${_BREAK}${_RESET}"
        exit 1
    fi

    # Setup temporary directory
    ${_ECHO} "${_YELLOW} 🧹 Cleaning old temporary files...${_RESET}"
    rm -rf "$_TMP_DIR" "$_CHOICE_FILE" 2>/dev/null || true
    ${_ECHO} "${_YELLOW} 🗂️ Create temporary directory...${_RESET}"
    mkdir -p "$_TMP_DIR" 2>/dev/null || {
        ${_ECHO} "${_RED}${_BOLD} ❌ Error creating temporary directory: ${_TMP_DIR}${_RESET}"
        return 1
    }

    # Load preview content only for interactive mode
    if [[ "$_load_preview" == "true" ]]; then
        ${_ECHO} "${_YELLOW} 📡 Retrieving preview content...${_RESET}"
        __init_preview
    fi

    # Final message
    ${_ECHO} "${_GREEN} 🐸 Starting...${_RESET}"

    # Short delay for better UX
    wait
    sleep 1
}

# =============================================================================
# PREVIEW FUNCTIONS
# =============================================================================

# Dynamic preview content generator for fzf menus
__get_preview() {
    local _preview_choice="$1"
    local _frogging_family_preview_url=""
    local _tkg_installer_preview_url=""

    # Define repository URLs and static previews for each TKG package
    case "$_preview_choice" in
        linux)
            _tkg_installer_preview_url="${_TKG_RAW_URL}/linux.md"
            _frogging_family_preview_url="${_FROGGING_FAMILY_RAW_URL}/linux-tkg/refs/heads/master/README.md"
            ;;
        nvidia)
            _tkg_installer_preview_url="${_TKG_RAW_URL}/nvidia.md"
            _frogging_family_preview_url="${_FROGGING_FAMILY_RAW_URL}/nvidia-all/refs/heads/master/README.md"
            ;;
        mesa)
            _tkg_installer_preview_url="${_TKG_RAW_URL}/mesa.md"
            _frogging_family_preview_url="${_FROGGING_FAMILY_RAW_URL}/mesa-git/refs/heads/master/README.md"
            ;;
        wine)
            _tkg_installer_preview_url="${_TKG_RAW_URL}/wine.md"
            _frogging_family_preview_url="${_FROGGING_FAMILY_RAW_URL}/wine-tkg-git/refs/heads/master/wine-tkg-git/README.md"
            ;;
        proton)
            _tkg_installer_preview_url="${_TKG_RAW_URL}/proton.md"
            _frogging_family_preview_url="${_FROGGING_FAMILY_RAW_URL}/wine-tkg-git/refs/heads/master/proton-tkg/README.md"
            ;;
        config)
            _tkg_installer_preview_url="${_TKG_RAW_URL}/config.md"
            ;;
        clean)
            _tkg_installer_preview_url="${_TKG_RAW_URL}/clean.md"
            ;;
        help)
            _tkg_installer_preview_url="${_TKG_RAW_URL}/help.md"
            ;;
        exit)
            _tkg_installer_preview_url="${_TKG_RAW_URL}/exit.md"
            ;;
        return)
            _tkg_installer_preview_url="${_TKG_RAW_URL}/return.md"
            ;;
    esac

    # Glow style detection (auto-detect based on COLORTERM/TERM, or use env override)
    if [[ -z "${_glow_style:-}" ]]; then
        case "${COLORTERM:-}${TERM:-}" in
            *light*|*xterm*|*rxvt*|*konsole*)
                _glow_style="light"
                ;;
            *)
                _glow_style="dark"
                ;;
        esac
    fi

   # Display TKG-INSTALLER remote preview content
    if [[ -n "$_tkg_installer_preview_url" ]]; then
        glow --pager --width 80 --style "${_glow_style:-dark}" "$_tkg_installer_preview_url"
    fi

    # Display FROGGING-FAMILY remote preview content
    if [[ -n "$_frogging_family_preview_url" ]]; then
        glow --pager --width 80 --style "${_glow_style:-dark}" "$_frogging_family_preview_url"
    fi
}

# Preview content is initialized only for interactive mode
__init_preview() {
    # Dynamic previews from remote
    _preview_linux="$(__get_preview linux)"
    _preview_nvidia="$(__get_preview nvidia)"
    _preview_mesa="$(__get_preview mesa)"
    _preview_wine="$(__get_preview wine)"
    _preview_proton="$(__get_preview proton)"
    _preview_config="$(__get_preview config)"
    _preview_clean="$(__get_preview clean)"
    _preview_help="$(__get_preview help)"
    _preview_return="$(__get_preview return)"
    _preview_exit="$(__get_preview exit)"

    export _preview_linux _preview_nvidia _preview_mesa _preview_wine _preview_proton
    export _preview_config _preview_clean _preview_help _preview_return _preview_exit _glow_style
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# Generic package installation helper
__install_package() {
    local _repo_url="$1"
    local _package_name="$2"
    local _build_command="$3"
    local _clean_command="${4:-}"  # Optional clean command after build proton-tkg only
    local _work_directory="${5:-}"   # Optional working directory relative to cloned repo

    cd "$_TMP_DIR" || return 1

    # Clone repository
    git clone "$_repo_url" || {
        ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Error cloning: $_package_name for ${_distro_name}${_BREAK}${_LINE}${_BREAK}${_RESET}"
        return 1
    }

    # Navigate to the correct directory (assume it's the cloned repo name)
    local _repo_dir
    _repo_dir=$(basename "$_repo_url" .git)
    cd "$_repo_dir" || return 1

    # Navigate to working directory if specified
    if [[ -n "$_work_directory" ]]; then
        cd "$_work_directory" || {
            ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Error: Working directory not found: $_work_directory${_BREAK}${_LINE}${_BREAK}${_RESET}"
            return 1
        }
    fi

    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-bold --no-art --http-url --email --number-of-authors 6 --text-colors 15 3 15 3 15 11 || true
    fi

    # Build and install
    ${_ECHO} "${_GREEN}${_LINE}${_BREAK} 🏗️ Building and installing $_package_name for ${_distro_name}, this may take a while... ⏳${_BREAK}${_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${_BREAK}${_GREEN}${_LINE}${_RESET}"
    eval "$_build_command" || {
        ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Error building: $_package_name for ${_distro_name}${_BREAK}${_LINE}${_BREAK}${_RESET}"
        return 1
    }

    # Optional clean up
    if [[ -n "$_clean_command" ]]; then
        ${_ECHO} "${_GREEN}${_LINE}${_BREAK} 🏗️ Clean up build artifacts...${_BREAK}${_LINE}${_RESET}"
        eval "$_clean_command" || {
            ${_ECHO} "${_YELLOW}${_BOLD}${_LINE}${_BREAK} ✅ Nothing to clean: $_package_name${_BREAK}${_LINE}${_BREAK}${_RESET}"
            return 1
        }
    fi
}

# Linux-TKG installation
__linux_install() {
    local _build_command

    if [[ "${_distro_id}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like}" == *"arch"* ]]; then
        _build_command="makepkg -si"
    else
        _build_command="chmod +x install.sh && ./install.sh install"
    fi

    __install_package "${_FROGGING_FAMILY_REPO}/linux-tkg.git" "linux-tkg" "$_build_command"
}

# Nvidia-TKG installation
__nvidia_install() {
    __install_package "${_FROGGING_FAMILY_REPO}/nvidia-all.git" "nvidia-all" "makepkg -si"
}

# Mesa-TKG installation
__mesa_install() {
    __install_package "${_FROGGING_FAMILY_REPO}/mesa-git.git" "mesa-git" "makepkg -si"
}

# Wine-TKG installation
__wine_install() {
    local _build_command

    if [[ "${_distro_id}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like}" == *"arch"* ]]; then
        _build_command="makepkg -si"
    else
        _build_command="chmod +x non-makepkg-build.sh && ./non-makepkg-build.sh"
    fi

    __install_package "${_FROGGING_FAMILY_REPO}/wine-tkg-git.git" "wine-tkg-git" "$_build_command" "" "wine-tkg-git"
}

# Proton-TKG installation
__proton_install() {
    __install_package "${_FROGGING_FAMILY_REPO}/wine-tkg-git.git" "wine-tkg-git" "./proton-tkg.sh" "./proton-tkg.sh clean" "proton-tkg"
}

# =============================================================================
# EDITOR MANAGEMENT FUNCTION
# =============================================================================

# Text editor wrapper with fallback support
__editor() {
    local _target_file="$1"

    # Parse $EDITOR variable (may contain arguments)
    local _editor_raw="${EDITOR-}"
    local _editor_parts=()
    IFS=' ' read -r -a _editor_parts <<< "$_editor_raw" || true

    # Fallback to nano if no editor configured or not executable
    if [[ -z "${_editor_parts[0]:-}" ]] || ! command -v "${_editor_parts[0]}" >/dev/null 2>&1; then
        if command -v nano >/dev/null 2>&1; then
            _editor_parts=(nano)
        else
            ${_ECHO} "${_YELLOW}${_BOLD}${_LINE}${_BREAK} ⚠️ No editor found: please set \$EDITOR environment or install 'nano'.${_BREAK}${_LINE}${_BREAK}${_RESET}"
            sleep 2
            return 1
        fi
    fi

    # Execute the editor with the target _target_file
    "${_editor_parts[@]}" "$_target_file"
}

# Configuration file editor with interactive menu
__edit_config() {
    while true; do
        local _config_choice

        # Ensure configuration directory exists
        if [[ ! -d "${_CONFIG_DIR}" ]]; then
            ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Configuration directory not found: ${_CONFIG_DIR}${_BREAK}${_LINE}${_BREAK}${_RESET}"
            read -r -p "Do you want to create the configuration directory? [y/N]: " create_dir
            echo
            case "$create_dir" in
                y|Y|yes|Yes|YES)
                    mkdir -p "${_CONFIG_DIR}" || {
                        ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Error creating configuration directory!${_BREAK}${_LINE}${_BREAK}${_RESET}"
                        sleep 3
                        clear
                        return 1
                    }
                    ${_ECHO} "${_GREEN}${_LINE}${_BREAK} ✅ Configuration directory created: ${_CONFIG_DIR}${_BREAK}${_LINE}${_BREAK}${_RESET}"
                    sleep 3
                    ;;
                *)
                    ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ⚠️ Directory creation cancelled. Return to Main menu...${_BREAK}${_LINE}${_BREAK}${_RESET}"
                    sleep 3
                    clear
                    return 0
                    ;;
            esac

            # Clear screen
            clear
        fi

        # Function to handle configuration file editing
        local _menu_options=(
            "linux-tkg  |🧠 Linux   ─ 📝 linux-tkg.cfg"
        )

        # Only show Nvidia and Mesa config if Arch-based
        if [[ "${_distro_id,,}" =~ ^(1arch|cachyos|manjaro|endeavouros)$ || "${_distro_like,,}" == *"1arch"* ]]; then
            _menu_options+=(
                "nvidia-all |🎮 Nvidia  ─ 📝 nvidia-all.cfg"
                "mesa-git   |🧩 Mesa    ─ 📝 mesa-git.cfg"
            )
        fi

        # Always show Wine and Proton config
        _menu_options+=(
            "wine-tkg   |🍷 Wine    ─ 📝 wine-tkg.cfg"
            "proton-tkg |🎮 Proton  ─ 📝 proton-tkg.cfg"
            "return     |⏪ Return"
        )

        # Prepare menu content
        local _menu_content
        _menu_content=$(printf '%s\n' "${_menu_options[@]}")

        # Define common error message for preview
        local _error_config_not_exist="${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Error: No external configuration file found.${_BREAK}${_BREAK} ⚠️ Click to download missing file${_BREAK}${_LINE}${_RESET}"

        # Define a reusable bat command for the preview
        local _bat_cmd="bat --style=numbers --language=bash --wrap character --highlight-line 1 --force-colorization"

        local _preview_command='
            key=$(echo {} | cut -d"|" -f1 | xargs)
            _config_file_path="'"${_CONFIG_DIR}"'/${key}.cfg"

            # For wine-tkg, the config file name is different
            if [[ "$key" == "wine-tkg" ]]; then
                _config_file_path="'"${_CONFIG_DIR}"'/wine-tkg.cfg"
            fi
            
            case $key in
                linux-tkg|nvidia-all|mesa-git|wine-tkg|proton-tkg)
                    '"$_bat_cmd"' "$_config_file_path" 2>/dev/null || '"${_ECHO}"' "'"$_error_config_not_exist"'"
                    ;;
                return)
                    $_ECHO "$_preview_return"
                    ;;
            esac
        '
        local _header_text=$'🐸 TKG-Installer ─ Editor menu\n\n   Edit external configuration file\n   Default directory: ~/.config/frogminer/'
        local _footer_text=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\n🐸 Frogging-Family: https://github.com/Frogging-Family\n🌐 About: https://github.com/damachine/tkginstaller'
        local _border_label_text="${_TKG_INSTALLER_VERSION}"
        local _preview_window_settings='right:wrap:70%'

        _config_choice=$(__fzf_menu "$_menu_content" "$_preview_command" "$_header_text" "$_footer_text" "$_border_label_text" "$_preview_window_settings")

        # Handle cancelled selection
        if [[ -z "$_config_choice" ]]; then
            ${_ECHO} "${_YELLOW}${_LINE}${_BREAK} ⏪ Exit editor menu...${_BREAK}${_LINE}${_RESET}"
            sleep 1
            clear
            return 0
        fi

        # Extract selected configuration type
        local _config_file
        _config_file=$(echo "$_config_choice" | cut -d"|" -f1 | xargs)

        # Handle configuration file editing
        case $_config_file in
            linux-tkg)
                __handle_config \
                    "Linux-TKG" \
                    "${_CONFIG_DIR}/linux-tkg.cfg" \
                    "${_FROGGING_FAMILY_RAW_URL}/linux-tkg/master/customization.cfg"
                ;;
            nvidia-all)
                __handle_config \
                    "Nvidia-TKG" \
                    "${_CONFIG_DIR}/nvidia-all.cfg" \
                    "${_FROGGING_FAMILY_RAW_URL}/nvidia-all/master/customization.cfg"
                ;;
            mesa-git)
                __handle_config \
                    "Mesa-TKG" \
                    "${_CONFIG_DIR}/mesa-git.cfg" \
                    "${_FROGGING_FAMILY_RAW_URL}/mesa-git/master/customization.cfg"
                ;;
            wine-tkg)
                __handle_config \
                    "Wine-TKG" \
                    "${_CONFIG_DIR}/wine-tkg.cfg" \
                    "${_FROGGING_FAMILY_RAW_URL}/wine-tkg-git/master/wine-tkg-git/customization.cfg"
                ;;
            proton-tkg)
                __handle_config \
                    "Proton-TKG" \
                    "${_CONFIG_DIR}/proton-tkg.cfg" \
                    "${_FROGGING_FAMILY_RAW_URL}/wine-tkg-git/master/proton-tkg/proton-tkg.cfg"
                ;;
            return)
                ${_ECHO} "${_YELLOW}${_LINE}${_BREAK} ⏪ Exit editor menu...${_BREAK}${_LINE}${_RESET}"
                sleep 1
                clear
                return 0
                ;;
            *)
                ${_ECHO} ""
                ${_ECHO} "${_RED}${_BOLD} ❌ Invalid option: $TKG_CHOICE${_RESET}"
                ${_ECHO} "${_GREEN} Usage:${_RESET} $0 help${_RESET}"
                ${_ECHO} "        $0 [linux|nvidia|mesa|wine|proton]${_BREAK}${_RESET}"
                return 1
                ;;
        esac
    done
}

# Helper function to handle individual config file editing
__handle_config() {
    local _config_name="$1"
    local _config_path="$2" 
    local _config_url="$3"

    ${_ECHO} "${_YELLOW}${_LINE}${_BREAK} 🔧 Opening external $_config_name configuration file...${_BREAK}${_LINE}${_RESET}"
    sleep 1
    clear

    if [[ -f "$_config_path" ]]; then
        # Edit existing configuration file
        __editor "$_config_path" || {
            ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Error opening $_config_path configuration!${_BREAK}${_LINE}${_BREAK}${_RESET}"
            sleep 3
            clear
            return 1
        }
    else
        # Download and create new configuration file
        ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ⚠️ $_config_path does not exist.${_BREAK}${_LINE}${_BREAK}${_RESET}"
        read -r -p "Do you want to download the default configuration from $_config_url? [y/N]: " user_answer
        echo
        case "$user_answer" in
            y|Y|yes|Yes|YES)
                mkdir -p "$(dirname "$_config_path")"
                if curl -fsSL "$_config_url" -o "$_config_path" 2>/dev/null; then
                    ${_ECHO} "${_GREEN}${_LINE}${_BREAK} ✅ Configuration ready at $_config_path${_BREAK}${_LINE}${_BREAK}${_RESET}"
                    sleep 3
                    clear
                    __editor "$_config_path" || {
                        ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Error opening $_config_path configuration!${_BREAK}${_LINE}${_BREAK}${_RESET}"
                        sleep 3
                        clear
                        return 1
                    }
                else
                    ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Error downloading configuration from $_config_url${_BREAK}${_LINE}${_BREAK}${_RESET}"
                    sleep 3
                    clear
                    return 1
                fi
                ;;
            *)
                ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ⚠️ Download cancelled. No configuration file created. Return to Mainmenu...${_BREAK}${_LINE}${_BREAK}${_RESET}"
                sleep 3
                clear
                return 1
                ;;
        esac

        # Clear screen
        clear
    fi

    ${_ECHO} "${_YELLOW}${_LINE}${_BREAK} ✅ Closing external $_config_name configuration file...${_BREAK}${_LINE}${_RESET}"
    sleep 1
    clear
    return 0
}

# =============================================================================
# PROMPT MENU FUNCTIONS
# =============================================================================

# Combined Linux + Nvidia installation
__linuxnvidia_prompt() {
    SECONDS=0
    __linux_prompt || true
    __nvidia_prompt || true
}

# Linux-TKG installation prompt
__linux_prompt() {
    SECONDS=0
    ${_ECHO} "${_GREEN}${_LINE}${_BREAK} 🧠 Fetching Linux-TKG from Frogging-Family repository... ⏳${_BREAK}${_LINE}${_RESET}"
    __linux_install
    __done $?
}

# Nvidia-TKG installation prompt
__nvidia_prompt() {
    SECONDS=0
    ${_ECHO} "${_GREEN}${_LINE}${_BREAK} 🖥️ Fetching Nvidia-TKG from Frogging-Family repository... ⏳${_BREAK}${_LINE}${_RESET}"
    __nvidia_install
    __done $?
}

# Mesa-TKG installation prompt
__mesa_prompt() {
    SECONDS=0
    ${_ECHO} "${_GREEN}${_LINE}${_BREAK} 🧩 Fetching Mesa-TKG from Frogging-Family repository... ⏳${_BREAK}${_LINE}${_RESET}"
    __mesa_install
    __done $?
}

# Wine-TKG installation prompt
__wine_prompt() {
    SECONDS=0
    ${_ECHO} "${_GREEN}${_LINE}${_BREAK} 🍷 Fetching Wine-TKG from Frogging-Family repository... ⏳${_BREAK}${_LINE}${_RESET}"
    __wine_install
    __done $?
}

# Proton-TKG installation prompt
__proton_prompt() {
    SECONDS=0
    ${_ECHO} "${_GREEN}${_LINE}${_BREAK} 🎮 Fetching Proton-TKG from Frogging-Family repository... ⏳${_BREAK}${_LINE}${_RESET}"
    __proton_install
    __done $?
}

# Configuration editor prompt
__config_prompt() {
    __edit_config || true
}

# =============================================================================
# FZF MAIN MENU FUNCTIONS
# =============================================================================

# Interactive main menu with fzf preview
__menu() {
    local _menu_options=(
        "Linux  |🧠 Linux   ─ Linux-TKG custom kernels"
    )

    # Only show Nvidia and Mesa if Arch-based
    if [[ "${_distro_id,,}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like,,}" == *"arch"* ]]; then
        _menu_options+=(
            "Nvidia |🖥️ Nvidia  ─ Nvidia Open-Source or proprietary graphics driver"
            "Mesa   |🧩 Mesa    ─ Open-Source graphics driver for AMD and Intel"
        )
    fi

    _menu_options+=(
        "Wine   |🍷 Wine    ─ Windows compatibility layer"
        "Proton |🎮 Proton  ─ Windows compatibility layer for Steam / Gaming"
        "Config |🛠️ Config  ─ Edit external TKG configuration files"
        "Clean  |🧹 Clean   ─ Clean downloaded files"
        "Help   |❓ Help    ─ Shows all commands"
        "Exit   |❌ Exit"
    )

    local _menu_content
    _menu_content=$(printf '%s\n' "${_menu_options[@]}")

    local _preview_command='
        key=$(echo {} | cut -d"|" -f1 | xargs)
        case $key in
            Linux*) $_ECHO "$_preview_linux" ;;
            Nvidia*)
                if [[ "${_distro_id,,}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like,,}" == *"arch"* ]]; then
                    $_ECHO "$_preview_nvidia"
                else
                    $_ECHO "${_RED}${_BOLD} ❌ Nvidia-TKG is only available for Arch-based distributions.${_RESET}"
                fi
                ;;
            Mesa*)
                if [[ "${_distro_id,,}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like,,}" == *"arch"* ]]; then
                    $_ECHO "$_preview_mesa"
                else
                    $_ECHO "${_RED}${_BOLD} ❌ Mesa-TKG is only available for Arch-based distributions.${_RESET}"
                fi
                ;;
            Wine*) $_ECHO "$_preview_wine" ;;
            Proton*) $_ECHO "$_preview_proton" ;;
            Config*) $_ECHO "$_preview_config" ;;
            Clean*) $_ECHO "$_preview_clean" ;;
            Help*) $_ECHO "$_preview_help" ;;
            Exit*) $_ECHO "$_preview_exit" ;;
        esac
    '
    local _header_text=$'🐸 TKG-Installer\n\n🏗️ Easily build the TKG packages from the Frogging-Family repositories.'
    local _footer_text=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\n🐸 Frogging-Family: https://github.com/Frogging-Family\n🌐 About: https://github.com/damachine/tkginstaller'
    local _border_label_text="${_TKG_INSTALLER_VERSION}"
    local _preview_window_settings='right:wrap:60%'

    local _main_choice
    _main_choice=$(__fzf_menu "$_menu_content" "$_preview_command" "$_header_text" "$_footer_text" "$_border_label_text" "$_preview_window_settings")

    # Handle cancelled selection (ESC pressed)
    if [[ -z "${_main_choice:-}" ]]; then
        ${_ECHO} "${_YELLOW}${_LINE}${_BREAK} 👋 Exit TKG-Installer...${_BREAK}${_LINE}${_RESET}"
        sleep 1
        clear
        __exit 0
    fi

    # Save selection to temporary file for processing
    echo "$_main_choice" | cut -d"|" -f1 | xargs > "$_CHOICE_FILE"
}

# =============================================================================
# MAIN PROGRAM ENTRY POINT
# =============================================================================

# Handle direct command-line arguments for quick execution
__main_direct_mode() {
    local _arg1="${1,,}"  # Convert to lowercase
    local _arg2="${2,,}"  # Convert to lowercase

    # Accept both [package] [config] and [config] [package] order
    local _package=""
    local _config_arg=""

    # Check for config argument in either position
    if [[ "$_arg1" =~ ^(config|c|edit|e)$ ]]; then
        _config_arg="$_arg1"
        case "$_arg2" in
            linux|l|--linux|-l) _package="linux-tkg" ;;
            nvidia|n|--nvidia|-n) _package="nvidia-all" ;;
            mesa|m|--mesa|-m) _package="mesa-git" ;;
            wine|w|--wine|-w) _package="wine-tkg" ;;
            proton|p|--proton|-p) _package="proton-tkg" ;;
        esac
    elif [[ "$_arg2" =~ ^(config|c|edit|e)$ ]]; then
        _config_arg="$_arg2"
        case "$_arg1" in
            linux|l|--linux|-l) _package="linux-tkg" ;;
            nvidia|n|--nvidia|-n) _package="nvidia-all" ;;
            mesa|m|--mesa|-m) _package="mesa-git" ;;
            wine|w|--wine|-w) _package="wine-tkg" ;;
            proton|p|--proton|-p) _package="proton-tkg" ;;
        esac
    fi

    if [[ -n "$_package" && -n "$_config_arg" ]]; then
        # Determine config file path and URL based on package
        local _config_path="${_CONFIG_DIR}/${_package}.cfg"
        local _config_url=""
        local _config_name=""

        case "$_package" in
            linux-tkg)
                _config_name="Linux-TKG"
                _config_url="${_FROGGING_FAMILY_RAW_URL}/linux-tkg/master/customization.cfg"
                ;;
            nvidia-all)
                _config_name="Nvidia-TKG"
                _config_url="${_FROGGING_FAMILY_RAW_URL}/nvidia-all/master/customization.cfg"
                ;;
            mesa-git)
                _config_name="Mesa-TKG"
                _config_url="${_FROGGING_FAMILY_RAW_URL}/mesa-git/master/customization.cfg"
                ;;
            wine-tkg)
                _config_name="Wine-TKG"
                _config_url="${_FROGGING_FAMILY_RAW_URL}/wine-tkg-git/master/wine-tkg-git/customization.cfg"
                ;;
            proton-tkg)
                _config_name="Proton-TKG"
                _config_url="${_FROGGING_FAMILY_RAW_URL}/wine-tkg-git/master/proton-tkg/proton-tkg.cfg"
                ;;
        esac

        # Disable exit trap before handling config
        trap - INT TERM EXIT HUP

        # Handle config file
        __handle_config "$_config_name" "$_config_path" "$_config_url"

        # Display exit messages
        ${_ECHO} "${_GREEN} 🧹 Cleanup completed!${_RESET}"
        ${_ECHO} "${_GREEN} 👋 TKG-Installer closed!${_RESET}"
        ${_ECHO} "${_GREEN}${_LINE}${_RESET}"
        ${_ECHO} "${_BREAK}${_RESET}"

        # Clean exit
        __clean
        exit 0
    fi

    # Handle regular install commands
    case "$_arg1" in
        linux|l|--linux|-l)
            __pre
            __linux_prompt
            exit 0
            ;;
        nvidia|n|--nvidia|-n)
            __pre
            __nvidia_prompt
            exit 0
            ;;
        mesa|m|--mesa|-m)
            __pre
            __mesa_prompt
            exit 0
            ;;
        wine|w|--wine|-w)
            __pre
            __wine_prompt
            exit 0
            ;;
        proton|p|--proton|-p)
            __pre
            __proton_prompt
            exit 0
            ;;
        clean|--clean)
            ${_ECHO} "${_YELLOW}${_LINE}${_BREAK} 🧹 Cleaning temporary files...${_BREAK}${_LINE}${_RESET}"      
            __pre >/dev/null 2>&1 || true
            rm -f "$_LOCK_FILE" 2>&1 || true
            sleep 1
            clear
            ;;
        help|h|--help|-h)
            # Disable exit trap before cleanup and exit
            trap - INT TERM EXIT HUP

            # Clean exit without triggering __exit cleanup messages. Unset exported all variables
            __clean
            exit 0
            ;;
        *)
            # Invalid argument handling
            ${_ECHO} "${_LINE}${_BREAK}${_RED}${_BOLD} ❌ Invalid argument: ${1:-}${_RESET}"
            ${_ECHO} "${_YELLOW}    The argument is either invalid or incomplete.${_BREAK}${_RESET}"
            ${_ECHO} "${_BLUE} Run interactive fzf finder menu.${_RESET}"
            ${_ECHO} "${_GREEN} Interactive:${_RESET} $0"
            ${_ECHO} ""
            ${_ECHO} "${_BLUE} Run directly without entering the menu.${_RESET}"
            ${_ECHO} "${_GREEN} Syntax:${_RESET} $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p]"
            ${_ECHO} ""
            ${_ECHO} "${_YELLOW} Example:${_RESET}"
            ${_ECHO} "  $0 linux         # Install Linux-TKG"
            ${_ECHO} "  $0 nvidia        # Install Nvidia-TKG"
            ${_ECHO} "  $0 mesa          # Install Mesa-TKG"
            ${_ECHO} "  $0 wine          # Install Wine-TKG"
            ${_ECHO} "  $0 proton        # Install Proton-TKG"
            ${_ECHO} ""
            ${_ECHO} "${_BLUE} Access configuration files directly without entering the menu.${_RESET}"
            ${_ECHO} "${_GREEN} Syntax:${_RESET} $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p] [config|c|edit|e]"
            ${_ECHO} "${_GREEN}        ${_RESET} $0 [config|c|edit|e] [linux|l|nvidia|n|mesa|m|wine|w|proton|p]"
            ${_ECHO} "${_YELLOW} Example:${_RESET}"
            ${_ECHO} "  $0 linux config  # Edit Linux-TKG config"
            ${_ECHO} "  $0 config linux  # Edit Linux-TKG config"
            ${_ECHO} ""
            ${_ECHO} "${_YELLOW} Shortcuts:${_RESET} l=linux, n=nvidia, m=mesa, w=wine, p=proton, c=config, e=edit"
            ${_ECHO} "${_LINE}${_RESET}"

            # Disable exit trap before cleanup and exit
            trap - INT TERM EXIT HUP

            # Clean exit without triggering __exit cleanup messages. Unset exported all variables
            __clean
            exit 1
            ;;
    esac
}

# Main function for interactive mode
__main_interactive_mode() {
    # Interactive mode - show menu and handle user selection
    __pre true
    clear
    __menu

    # Process user selection from menu
    local _user_choice
    _user_choice=$(< "$_CHOICE_FILE")
    rm -f "$_CHOICE_FILE"

    case $_user_choice in
        Linux)
            __linux_prompt
            ;;
        Nvidia)
            __nvidia_prompt
            ;;
        Mesa)
            __mesa_prompt
            ;;
        Wine)
            __wine_prompt
            ;;
        Proton)
            __proton_prompt
            ;;
        Config)
            __config_prompt
            rm -f "$_LOCK_FILE"
            clear
            exec "$0"
            ;;
        Help)
            # Help argument handling
            __help

            # Disable exit trap before cleanup and exit
            trap - INT TERM EXIT HUP

            # Clean exit without triggering __exit cleanup messages. Unset exported all variables
            __clean
            exit 0
            ;;
        Clean)
            ${_ECHO} "${_YELLOW}${_LINE}${_BREAK} 🧹 Cleaning temporary files...${_BREAK} 🔁 Restarting...${_BREAK}${_LINE}${_RESET}"      
            __pre >/dev/null 2>&1 || true
            rm -f "$_LOCK_FILE" 2>&1 || true
            sleep 1
            clear
            exec "$0" 
            ;;
        Exit)
            ${_ECHO} "${_YELLOW}${_LINE}${_BREAK} 👋 Exit TKG-Installer...${_BREAK}${_LINE}${_RESET}"
            sleep 1
            clear
            exit 0
            ;;
    esac
}

# Main function - handles command line arguments and menu interaction
__main() {
    # Handle direct command line arguments for automation
    if [[ $# -gt 0 ]]; then
        __main_direct_mode "$@"
    else
        __main_interactive_mode
    fi
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Start the main program with all provided arguments
__main "$@"
