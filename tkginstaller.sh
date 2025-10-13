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
# Info:
#   TKG-Installer
#   Manage the popular TKG packages (Kernel, Nvidia, Mesa, Wine, Proton) from the Frogging-Family repositories.
#   Interactive Fuzzy finder fzf menue mode.
#   Quick direct command-line mode.
#   Preview readme and configuration.
#   Edit configuration files using your preferred editor.
#   Optional download configuration files.
# Details:
#   This script handles installation, configuration for TKG/Frogminer packages.
#   It uses color output and Unicode icons for better readability.
#   Do not run as root. Use a dedicated user for security.
#   See https://github.com/damachine/tkginstaller further details.
# Usage:
#   Interactive (Menu-mode)
#       run: tkginstaller
#   Command-line (Direct-mode)
#   Skip the menu and run specific actions directly:
#   Examples:
#       run: tkginstaller linux          # Install Linux-TKG
#       run: tkginstaller nvidia         # Install Nvidia-TKG
#       run: tkginstaller mesa           # Install Mesa-TKG
#       run: tkginstaller wine           # Install Wine-TKG
#       run: tkginstaller proton         # Install Proton-TKG
#       run: tkginstaller linux config   # Edit Linux-TKG config
#       run: tkginstaller l c            # Edit Linux-TKG config (short)
#   Show all available commands and shortcuts!
#       run: tkginstaller help
# -----------------------------------------------------------------------------

# Fuzzy finder run in a separate shell and brings SC2016, SC2218 warnings. Allow fzf to expand variables in its own shell at runtime
# shellcheck disable=SC2016
# shellcheck disable=SC2218

# TKG-Installer VERSION
readonly _TKG_INSTALLER_VERSION="v0.12.4"

# =============================================================================
# INITIALIZATION FUNCTIONS
# =============================================================================

# Initialize global variables, paths, and configurations
__init_globals() {
    # Global paths and configuration
    readonly _LOCK_FILE="/tmp/tkginstaller.lock"
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
    ${_ECHO} "${_RED}${_BOLD}${_BREAK} ❌ Do not run as root!${_BREAK}${_RESET}"
    exit 1
fi

# Detect Linux Distribution
if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091 # Source file is system-dependent and may not exist on all systems
    . /etc/os-release
    readonly TKG_DISTRO_NAME="$NAME"
    readonly TKG_DISTRO_ID="${ID:-unknown}"
    readonly TKG_DISTRO_ID_LIKE="${ID_LIKE:-}"
else
    readonly TKG_DISTRO_NAME="Unknown"
    readonly TKG_DISTRO_ID="unknown"
    readonly TKG_DISTRO_ID_LIKE=""
fi

# Help information display
__help() {
    ${_ECHO} "${_LINE}${_BREAK}${_GREEN} 🛈 TKG-Installer Help${_BREAK}${_RESET}"
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
    ${_ECHO} "  $0 l c           # Edit Linux-TKG config (short)"
    ${_ECHO} "  $0 config linux  # Edit Linux-TKG config"
    ${_ECHO} "  $0 c l           # Edit Linux-TKG config (short)"
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
        old_pid=$(cat "$_LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            ${_ECHO} ""
            ${_ECHO} "${_RED}${_BOLD} ❌ Script is already running (PID: $old_pid). Exiting...${_RESET}"
            ${_ECHO} "${_YELLOW}${_BOLD} 🔁 If the script was unexpectedly terminated, remove the lock file manually:${_RESET}${_BREAK}${_BREAK}    tkginstaller.sh clean|c to remove the $_LOCK_FILE${_BREAK}${_RESET}"
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
    unset __PREVIEW_LINUX __PREVIEW_NVIDIA __PREVIEW_MESA __PREVIEW_WINE __PREVIEW_PROTON
    unset __PREVIEW_CONFIG __PREVIEW__clean __PREVIEW__help __PREVIEW_RETURN __PREVIEW__exit TKG_GLOW_STYLE
 }

# Setup exit trap for cleanup on script termination
__exit() {
    local exit_code=${1:-$?}
    trap - INT TERM EXIT HUP

    # Message handling
    if [[ $exit_code -ne 0 ]]; then
        ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} 🎯 ERROR 🎯 TKG-Installer aborted! Exiting...${_BREAK}${_LINE}${_BREAK}${_RESET}"
    else
        ${_ECHO} "${_GREEN} 🧹 Cleanup completed!${_RESET}"
        ${_ECHO} "${_GREEN} 👋 TKG-Installer closed!${_RESET}"
        ${_ECHO} "${_GREEN}${_LINE}${_BREAK}${_RESET}"
    fi

    # Perform cleanup
    __clean
    wait
    exit "$exit_code"
}
trap __exit INT TERM EXIT HUP

# Fuzzy finder menu wrapper function
__fzf_menu() {
    local menu_content="$1"
    local preview_command="$2"
    local header_text="$3"
    local footer_text="$4"
    local border_label_text="${5:-$_TKG_INSTALLER_VERSION}"
    local preview_window_settings="${6:-right:nowrap:60%}"

    fzf \
        --with-shell='bash -c' \
        --style minimal \
        --color='header:#00ff00,pointer:#00ff00,marker:#00ff00' \
        --border=none \
        --border-label="${border_label_text}" \
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
        --pointer='▶' \
        --header="${header_text}" \
        --header-border=line \
        --header-label="${border_label_text}" \
        --header-label-pos=256 \
        --header-first \
        --footer="${footer_text}" \
        --footer-border=line \
        --preview-window="${preview_window_settings}" \
        --preview="${preview_command}" \
        --disabled \
        <<< "${menu_content}"
}

# Display completion status with timestamp
__done() {
    local status=${1:-$?} # Use passed status, fallback to $? for compatibility
    local duration="${SECONDS:-0}"
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    ${_ECHO} "${_GREEN}${_LINE}${_BREAK}${_RESET}${_YELLOW} 📝 Action completed: $(date '+%Y-%m-%d %H:%M:%S')${_RESET}"

    if [[ $status -eq 0 ]]; then
        ${_ECHO} "${_GREEN} ✅ Status: Successful${_RESET}"
    else
        ${_ECHO} "${_RED}${_BOLD} ❌ Status: Error (Code: $status)${_RESET}"
    fi

    ${_ECHO} "${_YELLOW} ⏱️ Duration: ${minutes} min ${seconds} sec${_RESET}${_GREEN}${_BREAK}${_LINE}${_RESET}"
    return "$status"
}

# Pre-installation checks and preparation
__pre() {
    local load__preview="${1:-false}"

    # Welcome message
    ${_ECHO} "${_GREEN}${_LINE}${_BREAK} 🐸 TKG-Installer ${_TKG_INSTALLER_VERSION} for ${TKG_DISTRO_NAME}${_BREAK}${_LINE}${_RESET}"
    ${_ECHO} "${_YELLOW} 🔁 Pre-checks starting...${_RESET}"

    # Check required dependencies
    local dependencies=(bat curl glow fzf git)
    for required_dependency in "${dependencies[@]}"; do
        if ! command -v "$required_dependency" >/dev/null; then
            ${_ECHO} "${_RED}${_BOLD} ❌ $required_dependency is not installed! Please install it first.${_RESET}"
            ${_ECHO} "${_YELLOW}${_BOLD} 🔁 Run: pacman -S ${required_dependency}${_RESET}"            
            exit 1
        fi
    done

    # Setup temporary directory
    ${_ECHO} "${_YELLOW} 🧹 Cleaning old temporary files...${_RESET}"
    rm -rf "$_TMP_DIR" "$_CHOICE_FILE" 2>/dev/null || true
    ${_ECHO} "${_YELLOW} 🗂️ Create temporary directory...${_RESET}"
    mkdir -p "$_TMP_DIR" 2>/dev/null || {
        ${_ECHO} "${_RED}${_BOLD} ❌ Error creating temporary directory: ${_TMP_DIR}${_RESET}"
        return 1
    }

    # Load preview content only for interactive mode
    if [[ "$load__preview" == "true" ]]; then
        ${_ECHO} "${_YELLOW} 📡 Retrieving preview content...${_RESET}"
        __init__preview
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
__get__preview() {
    local preview_choice="$1"
    local frogging_family__PREVIEW_url=""
    local tkg_installer__PREVIEW_url=""

    # Define repository URLs and static previews for each TKG package
    case "$preview_choice" in
        linux)
            tkg_installer__PREVIEW_url="${_TKG_RAW_URL}/linux.md"
            frogging_family__PREVIEW_url="${_FROGGING_FAMILY_RAW_URL}/linux-tkg/refs/heads/master/README.md"
            ;;
        nvidia)
            tkg_installer__PREVIEW_url="${_TKG_RAW_URL}/nvidia.md"
            frogging_family__PREVIEW_url="${_FROGGING_FAMILY_RAW_URL}/nvidia-all/refs/heads/master/README.md"
            ;;
        mesa)
            tkg_installer__PREVIEW_url="${_TKG_RAW_URL}/mesa.md"
            frogging_family__PREVIEW_url="${_FROGGING_FAMILY_RAW_URL}/mesa-git/refs/heads/master/README.md"
            ;;
        wine)
            tkg_installer__PREVIEW_url="${_TKG_RAW_URL}/wine.md"
            frogging_family__PREVIEW_url="${_FROGGING_FAMILY_RAW_URL}/wine-tkg-git/refs/heads/master/wine-tkg-git/README.md"
            ;;
        proton)
            tkg_installer__PREVIEW_url="${_TKG_RAW_URL}/proton.md"
            frogging_family__PREVIEW_url="${_FROGGING_FAMILY_RAW_URL}/wine-tkg-git/refs/heads/master/proton-tkg/README.md"
            ;;
        config)
            tkg_installer__PREVIEW_url="${_TKG_RAW_URL}/config.md"
            ;;
        clean)
            tkg_installer__PREVIEW_url="${_TKG_RAW_URL}/clean.md"
            ;;
        help)
            tkg_installer__PREVIEW_url="${_TKG_RAW_URL}/help.md"
            ;;
        exit)
            tkg_installer__PREVIEW_url="${_TKG_RAW_URL}/exit.md"
            ;;
        return)
            tkg_installer__PREVIEW_url="${_TKG_RAW_URL}/return.md"
            ;;
    esac

    # Glow style detection (auto-detect based on COLORTERM/TERM, or use env override)
    if [[ -z "${TKG_GLOW_STYLE:-}" ]]; then
        case "${COLORTERM:-}${TERM:-}" in
            *light*|*xterm*|*rxvt*|*konsole*)
                TKG_GLOW_STYLE="light"
                ;;
            *)
                TKG_GLOW_STYLE="dark"
                ;;
        esac
    fi

   # Display TKG-INSTALLER remote preview content
    if [[ -n "$tkg_installer__PREVIEW_url" ]]; then
        # Download and cache content
        local tkg_installer_cache="${_TMP_DIR}/$(basename "$tkg_installer__PREVIEW_url")"
        if [[ ! -f "$tkg_installer_cache" ]]; then
            curl -fsSL --max-time 10 "${tkg_installer__PREVIEW_url}" -o "$tkg_installer_cache" 2>/dev/null
        fi
        if [[ -s "$tkg_installer_cache" ]]; then
            ${_ECHO} ""
            glow --pager --width 80 --style "${TKG_GLOW_STYLE:-dark}" "$tkg_installer_cache"
        fi
    fi

    # Display FROGGING-FAMILY remote preview content
    if [[ -n "$frogging_family__PREVIEW_url" ]]; then
        # Download and cache content
        local frogging_family_cache="${_TMP_DIR}/$(basename "$frogging_family__PREVIEW_url")"
        if [[ ! -f "$frogging_family_cache" ]]; then
            curl -fsSL --max-time 10 "${frogging_family__PREVIEW_url}" -o "$frogging_family_cache" 2>/dev/null
        fi
        if [[ -s "$frogging_family_cache" ]]; then
            ${_ECHO} ""
            glow --pager --width 80 --style "${TKG_GLOW_STYLE:-dark}" "$frogging_family_cache"
        fi
    fi
}

# Preview content is initialized only for interactive mode
__init__preview() {
    # Dynamic previews from remote
    __PREVIEW_LINUX="$(__get__preview linux)"
    __PREVIEW_NVIDIA="$(__get__preview nvidia)"
    __PREVIEW_MESA="$(__get__preview mesa)"
    __PREVIEW_WINE="$(__get__preview wine)"
    __PREVIEW_PROTON="$(__get__preview proton)"
    __PREVIEW_CONFIG="$(__get__preview config)"
    __PREVIEW__clean="$(__get__preview clean)"
    __PREVIEW__help="$(__get__preview help)"
    __PREVIEW_RETURN="$(__get__preview return)"
    __PREVIEW__exit="$(__get__preview exit)"

    export __PREVIEW_LINUX __PREVIEW_NVIDIA __PREVIEW_MESA __PREVIEW_WINE __PREVIEW_PROTON
    export __PREVIEW_CONFIG __PREVIEW__clean __PREVIEW__help __PREVIEW_RETURN __PREVIEW__exit TKG_GLOW_STYLE
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# Generic package installation helper
__install_package() {
    local repo_url="$1"
    local package_name="$2"
    local build_command="$3"
    local clean_command="${4:-}"  # Optional clean command after build proton-tkg only
    local work_directory="${5:-}"   # Optional working directory relative to cloned repo

    cd "$_TMP_DIR" || return 1

    # Clone repository
    git clone "$repo_url" || {
        ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Error cloning: $package_name for ${TKG_DISTRO_NAME}${_BREAK}${_LINE}${_BREAK}${_RESET}"
        return 1
    }

    # Navigate to the correct directory (assume it's the cloned repo name)
    local repo_dir
    repo_dir=$(basename "$repo_url" .git)
    cd "$repo_dir" || return 1

    # Navigate to working directory if specified
    if [[ -n "$work_directory" ]]; then
        cd "$work_directory" || {
            ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Error: Working directory not found: $work_directory${_BREAK}${_LINE}${_BREAK}${_RESET}"
            return 1
        }
    fi

    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-bold --no-art --http-url --email --number-of-authors 6 --text-colors 15 3 15 3 15 11 || true
    fi

    # Build and install
    ${_ECHO} "${_GREEN}${_LINE}${_BREAK} 🏗️ Building and installing $package_name for ${TKG_DISTRO_NAME}, this may take a while... ⏳${_BREAK}${_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${_BREAK}${_GREEN}${_LINE}${_RESET}"
    eval "$build_command" || {
        ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Error building: $package_name for ${TKG_DISTRO_NAME}${_BREAK}${_LINE}${_BREAK}${_RESET}"
        return 1
    }

    # Optional clean up
    if [[ -n "$clean_command" ]]; then
        ${_ECHO} "${_GREEN}${_LINE}${_BREAK} 🏗️ Clean up build artifacts...${_BREAK}${_LINE}${_RESET}"
        eval "$clean_command" || {
            ${_ECHO} "${_YELLOW}${_BOLD}${_LINE}${_BREAK} ✅ Nothing to clean: $package_name${_BREAK}${_LINE}${_BREAK}${_RESET}"
            return 1
        }
    fi
}

# Linux-TKG installation
__linux_install() {
    local distro_id="${TKG_DISTRO_ID,,}"
    local distro_like="${TKG_DISTRO_ID_LIKE,,}"
    local build_command

    if [[ "${distro_id}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${distro_like}" == *"arch"* ]]; then
        build_command="makepkg -si"
    else
        build_command="chmod +x install.sh && ./install.sh install"
    fi

    __install_package "${_FROGGING_FAMILY_REPO}/linux-tkg.git" "linux-tkg" "$build_command"
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
    local distro_id="${TKG_DISTRO_ID,,}"
    local distro_like="${TKG_DISTRO_ID_LIKE,,}"
    local build_command

    if [[ "${distro_id}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${distro_like}" == *"arch"* ]]; then
        build_command="makepkg -si"
    else
        build_command="chmod +x non-makepkg-build.sh && ./non-makepkg-build.sh"
    fi

    __install_package "${_FROGGING_FAMILY_REPO}/wine-tkg-git.git" "wine-tkg-git" "$build_command" "" "wine-tkg-git"
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
    local target_file="$1"

    # Parse $EDITOR variable (may contain arguments)
    local editor_raw="${EDITOR-}"
    local editor_parts=()
    IFS=' ' read -r -a editor_parts <<< "$editor_raw" || true

    # Fallback to nano if no editor configured or not executable
    if [[ -z "${editor_parts[0]:-}" ]] || ! command -v "${editor_parts[0]}" >/dev/null 2>&1; then
        if command -v nano >/dev/null 2>&1; then
            editor_parts=(nano)
        else
            ${_ECHO} "${_YELLOW}${_BOLD}${_LINE}${_BREAK} ⚠️ No editor found: please set \$EDITOR environment or install 'nano'.${_BREAK}${_LINE}${_BREAK}${_RESET}"
            sleep 2
            return 1
        fi
    fi

    # Execute the editor with the target target_file
    "${editor_parts[@]}" "$target_file"
}

# Configuration file editor with interactive menu
__edit_config() {
    while true; do
        local config_choice

        # Ensure configuration directory exists
        if [[ ! -d "${_CONFIG_DIR}" ]]; then
            ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Configuration directory not found: ${_CONFIG_DIR}${_BREAK}${_LINE}${_BREAK}${_RESET}"
            read -r -p "Do you want to create the configuration directory? [y/N]: " create_dir
            echo
            case "$create_dir" in
                y|Y|yes)
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
                    ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ⚠️ Directory creation cancelled. Return to Mainmenu...${_BREAK}${_LINE}${_BREAK}${_RESET}"
                    sleep 3
                    clear
                    return 0
                    ;;
            esac

            # Clear screen
            clear
        fi

        # Function to handle configuration file editing
        local menu_options=(
            "linux-tkg  |🧠 Linux   ─ 📝 linux-tkg.cfg"
            "nvidia-all |🎮 Nvidia  ─ 📝 nvidia-all.cfg"
            "mesa-git   |🧩 Mesa    ─ 📝 mesa-git.cfg"
            "wine-tkg   |🍷 Wine    ─ 📝 wine-tkg.cfg"
            "proton-tkg |🎮 Proton  ─ 📝 proton-tkg.cfg"
            "return     |⏪ Return"
        )
        local menu_content
        menu_content=$(printf '%s\n' "${menu_options[@]}")

        # Define common error message for preview
        local error_config_not_exist="${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Error: No external configuration file found.${_BREAK}${_BREAK} ⚠️ Click to download missing file${_BREAK}${_LINE}${_RESET}"

        # Define a reusable bat command for the preview
        local bat_cmd="bat --style=numbers --language=bash --wrap character --highlight-line 1 --force-colorization"

        local preview_command='
            key=$(echo {} | cut -d"|" -f1 | xargs)
            config_file_path="'"${_CONFIG_DIR}"'/${key}.cfg"

            # For wine-tkg, the config file name is different
            if [[ "$key" == "wine-tkg" ]]; then
                config_file_path="'"${_CONFIG_DIR}"'/wine-tkg.cfg"
            fi
            
            case $key in
                linux-tkg|nvidia-all|mesa-git|wine-tkg|proton-tkg)
                    '"$bat_cmd"' "$config_file_path" 2>/dev/null || '"${_ECHO}"' "'"$error_config_not_exist"'"
                    ;;
                return)
                    $_ECHO "$__PREVIEW_RETURN"
                    ;;
            esac
        '
        local header_text=$'🐸 TKG-Installer ─ Editor menue\n\n   Edit external configuration file\n   Default directory: ~/.config/frogminer/'
        local footer_text=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\n🐸 Frogging-Family: https://github.com/Frogging-Family\n🌐 About: https://github.com/damachine/tkginstaller'
        local border_label_text="${_TKG_INSTALLER_VERSION}"
        local preview_window_settings='right:wrap:70%'

        config_choice=$(__fzf_menu "$menu_content" "$preview_command" "$header_text" "$footer_text" "$border_label_text" "$preview_window_settings")

        # Handle cancelled selection
        if [[ -z "$config_choice" ]]; then
            ${_ECHO} "${_YELLOW}${_LINE}${_BREAK} ⏪ Exit editor menu...${_BREAK}${_LINE}${_RESET}"
            sleep 1
            clear
            return 0
        fi

        # Extract selected configuration type
        local config_file
        config_file=$(echo "$config_choice" | cut -d"|" -f1 | xargs)

        # Handle configuration file editing
        case $config_file in
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
    local config_name="$1"
    local config_path="$2" 
    local config_url="$3"

    ${_ECHO} "${_YELLOW}${_LINE}${_BREAK} 🔧 Opening external $config_name configuration file...${_BREAK}${_LINE}${_RESET}"
    sleep 1
    clear

    if [[ -f "$config_path" ]]; then
        # Edit existing configuration file
        __editor "$config_path" || {
            ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Error opening $config_path configuration!${_BREAK}${_LINE}${_BREAK}${_RESET}"
            sleep 3
            clear
            return 1
        }
    else
        # Download and create new configuration file
        ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ⚠️ $config_path does not exist.${_BREAK}${_LINE}${_BREAK}${_RESET}"
        read -r -p "Do you want to download the default configuration from $config_url? [y/N]: " user_answer
        echo
        case "$user_answer" in
            y|Y|yes)
                mkdir -p "$(dirname "$config_path")"
                if curl -fsSL "$config_url" -o "$config_path" 2>/dev/null; then
                    ${_ECHO} "${_GREEN}${_LINE}${_BREAK} ✅ Configuration ready at $config_path${_BREAK}${_LINE}${_BREAK}${_RESET}"
                    sleep 3
                    clear
                    __editor "$config_path" || {
                        ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Error opening $config_path configuration!${_BREAK}${_LINE}${_BREAK}${_RESET}"
                        sleep 3
                        clear
                        return 1
                    }
                else
                    ${_ECHO} "${_RED}${_BOLD}${_LINE}${_BREAK} ❌ Error downloading configuration from $config_url${_BREAK}${_LINE}${_BREAK}${_RESET}"
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

    ${_ECHO} "${_YELLOW}${_LINE}${_BREAK} ✅ Closing external $config_name configuration file...${_BREAK}${_LINE}${_RESET}"
    sleep 1
    clear
    return 0
}

# =============================================================================
# PROMT MENUE FUNCTIONS
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
# FZF MAINMENUE FUNCTIONS
# =============================================================================

# Interactive main menu with fzf preview
__menu() {
    local menu_options=(
        "Linux  |🧠 Kernel  ─ Linux-TKG custom kernels"
        "Nvidia |🖥️ Nvidia  ─ Nvidia Open-Source or proprietary graphics driver"
        "Mesa   |🧩 Mesa    ─ Open-Source graphics driver for AMD and Intel"
        "Wine   |🍷 Wine    ─ Windows compatibility layer"
        "Proton |🎮 Proton  ─ Windows compatibility layer for Steam / Gaming"
        "Config |🛠️ Config  ─ Edit external TKG configuration files"
        "Clean  |🧹 Clean   ─ Clean downloaded files"
        "Help   |❓ Help    ─ Shows all commands"
        "Exit   |❌ Exit"
    )

    local menu_content
    menu_content=$(printf '%s\n' "${menu_options[@]}")

    local preview_command='
        key=$(echo {} | cut -d"|" -f1 | xargs)
        case $key in
            Linux*) $_ECHO "$__PREVIEW_LINUX" ;;
            Nvidia*) $_ECHO "$__PREVIEW_NVIDIA" ;;
            Mesa*) $_ECHO "$__PREVIEW_MESA" ;;
            Wine*) $_ECHO "$__PREVIEW_WINE" ;;
            Proton*) $_ECHO "$__PREVIEW_PROTON" ;;
            Config*) $_ECHO "$__PREVIEW_CONFIG" ;;
            Clean*) $_ECHO "$__PREVIEW__clean" ;;
            Help*) $_ECHO "$__PREVIEW__help" ;;
            Exit*) $_ECHO "$__PREVIEW__exit" ;;
        esac
    '
    local header_text=$'🐸 TKG-Installer ─ Select a option\n\n   Manage the popular TKG packages from the Frogging-Family repositories.'
    local footer_text=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\n🐸 Frogging-Family: https://github.com/Frogging-Family\n🌐 About: https://github.com/damachine/tkginstaller'
    local border_label_text="${_TKG_INSTALLER_VERSION}"
    local preview_window_settings='right:wrap:60%'

    local main_choice
    main_choice=$(__fzf_menu "$menu_content" "$preview_command" "$header_text" "$footer_text" "$border_label_text" "$preview_window_settings")

    # Handle cancelled selection (ESC pressed)
    if [[ -z "${main_choice:-}" ]]; then
        ${_ECHO} "${_YELLOW}${_LINE}${_BREAK} 👋 Exit TKG-Installer...${_BREAK}${_LINE}${_RESET}"
        sleep 1
        clear
        __exit 0
    fi

    # Save selection to temporary file for processing
    echo "$main_choice" | cut -d"|" -f1 | xargs > "$_CHOICE_FILE"
}

# =============================================================================
# MAIN PROGRAM ENTRY POINT
# =============================================================================

# Handle direct command-line arguments for quick execution
__handle_direct_mode() {
    local arg1="${1,,}"  # Convert to lowercase
    local arg2="${2,,}"  # Convert to lowercase

    # Accept both [package] [config] and [config] [package] order
    local package=""
    local config_arg=""

    # Check for config argument in either position
    if [[ "$arg1" =~ ^(config|c|edit|e)$ ]]; then
        config_arg="$arg1"
        case "$arg2" in
            linux|l|--linux|-l) package="linux-tkg" ;;
            nvidia|n|--nvidia|-n) package="nvidia-all" ;;
            mesa|m|--mesa|-m) package="mesa-git" ;;
            wine|w|--wine|-w) package="wine-tkg" ;;
            proton|p|--proton|-p) package="proton-tkg" ;;
        esac
    elif [[ "$arg2" =~ ^(config|c|edit|e)$ ]]; then
        config_arg="$arg2"
        case "$arg1" in
            linux|l|--linux|-l) package="linux-tkg" ;;
            nvidia|n|--nvidia|-n) package="nvidia-all" ;;
            mesa|m|--mesa|-m) package="mesa-git" ;;
            wine|w|--wine|-w) package="wine-tkg" ;;
            proton|p|--proton|-p) package="proton-tkg" ;;
        esac
    fi

    if [[ -n "$package" && -n "$config_arg" ]]; then
        # Determine config file path and URL based on package
        local config_path="${_CONFIG_DIR}/${package}.cfg"
        local config_url=""
        local config_name=""

        case "$package" in
            linux-tkg)
                config_name="Linux-TKG"
                config_url="${_FROGGING_FAMILY_RAW_URL}/linux-tkg/master/customization.cfg"
                ;;
            nvidia-all)
                config_name="Nvidia-TKG"
                config_url="${_FROGGING_FAMILY_RAW_URL}/nvidia-all/master/customization.cfg"
                ;;
            mesa-git)
                config_name="Mesa-TKG"
                config_url="${_FROGGING_FAMILY_RAW_URL}/mesa-git/master/customization.cfg"
                ;;
            wine-tkg)
                config_name="Wine-TKG"
                config_url="${_FROGGING_FAMILY_RAW_URL}/wine-tkg-git/master/wine-tkg-git/customization.cfg"
                ;;
            proton-tkg)
                config_name="Proton-TKG"
                config_url="${_FROGGING_FAMILY_RAW_URL}/wine-tkg-git/master/proton-tkg/proton-tkg.cfg"
                ;;
        esac

        # Disable exit trap before handling config
        trap - INT TERM EXIT HUP

        # Handle config file
        __handle_config "$config_name" "$config_path" "$config_url"

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
    case "$arg1" in
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
        clean|c|--clean|-c)
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
            ${_ECHO} "  $0 l c           # Edit Linux-TKG config (short)"
            ${_ECHO} "  $0 config linux  # Edit Linux-TKG config"
            ${_ECHO} "  $0 c l           # Edit Linux-TKG config (short)"
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
__main_interactive() {
    # Interactive mode - show menu and handle user selection
    __pre true
    clear
    __menu

    # Process user selection from menu
    local user_choice
    user_choice=$(< "$_CHOICE_FILE")
    rm -f "$_CHOICE_FILE"

    case $user_choice in
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
        __handle_direct_mode "$@"
    else
        __main_interactive
    fi
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Start the main program with all provided arguments
__main "$@"
