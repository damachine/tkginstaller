#!/usr/bin/env bash

# Fuzzy finder run in a separate shell and brings SC2016, SC2218 fail warnings. Allow fzf to expand variables in its own shell at runtime
# shellcheck disable=SC2016
# shellcheck disable=SC2218

# TKG-Installer VERSION
# TKG-Installer VERSION
readonly TKG_INSTALLER_VERSION="v0.11.8"

# -----------------------------------------------------------------------------
# author: damachine (christkue79@gmail.com)
# Maintainer: DAMACHINE <christkue79@gmail.com>
# website: https://github.com/damachine
#          https://github.com/damachine/tkginstaller
# copyright: (c) 2025 damachine
# license: MIT
# version: 1.0
#   This software is provided "as is", without warranty of any kind, express or implied.
#   I do not guarantee that it will work as intended on your system.
# -----------------------------------------------------------------------------
# Info:
# 	TKG-Installer
# 	Manage the popular TKG packages (Kernel, Nvidia, Mesa, Wine, Proton) from the Frogging-Family repositories.
# 	Interactive Fuzzy finder fzf menue mode.
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
#       run: tkginstaller linux    # Install Linux-TKG
#       run: tkginstaller nvidia   # Install Nvidia-TKG
#       run: tkginstaller mesa     # Install Mesa-TKG
#       run: tkginstaller wine     # Install Wine-TKG
#       run: tkginstaller proton   # Install Proton-TKG
#   Show all available commands and shortcuts!
#       run: tkginstaller help
# -----------------------------------------------------------------------------

# =============================================================================
# INITIALIZATION FUNCTIONS
# =============================================================================

# ⚙️ Initialize global variables, paths, and configurations
_init_globals() {
    # 📌 Global paths and configuration
    readonly TKG_LOCKFILE="/tmp/tkginstaller.lock"
    TKG_REPO="https://github.com/damachine/tkginstaller"
    TKG_RAW_URL="https://raw.githubusercontent.com/damachine/tkginstaller/refs/heads/master/docs"
    FROGGING_FAMILY_REPO="https://github.com/Frogging-Family"
    FROGGING_FAMILY_RAW_URL="https://raw.githubusercontent.com/Frogging-Family"
    FROGGING_FAMILY_CONFIG_DIR="$HOME/.config/frogminer"
    TKG_TMP_DIR="$HOME/.cache/tkginstaller"
    TKG_CHOICE_FILE="${TKG_TMP_DIR}/choice.tmp"

    # 📝 Export variables for fzf subshells (unset _exit run)
    export TKG_REPO TKG_RAW_URL FROGGING_FAMILY_REPO FROGGING_FAMILY_RAW_URL TKG_TMP_DIR FROGGING_FAMILY_CONFIG_DIR TKG_CHOICE_FILE
}

# 🎨 Initialize color and formatting definitions
_init_colors() {
    # 🎨 Formatting and color definitions
    TKG_ECHO="echo -e"
    TKG_BREAK="\n"
    TKG_LINE="──────────────────────────────────────────────────────────────────────────────────────────"
    TKG_RESET=$"\033[0m"
    TKG_BOLD=$"\033[1m"
    TKG_RED=$"\033[0;31m"
    TKG_GREEN=$"\033[0;32m"
    TKG_YELLOW=$"\033[0;33m"
    TKG_BLUE=$"\033[0;34m"

    # 📝 Export variables for fzf subshells (unset _exit run)
    export TKG_ECHO TKG_BREAK TKG_LINE TKG_RESET TKG_BOLD TKG_RED TKG_GREEN TKG_YELLOW TKG_BLUE
}

# =============================================================================
# ENVIRONMENT SETUP
# =============================================================================

# 🔒 Safety settings and strict mode
#set -euo pipefail

# 🌐 Force standard locale for consistent behavior (sorting, comparisons, messages)
#export LC_ALL=C

# ✨ Initialize globals and colors
_init_globals
_init_colors

# Check for root execution
if [[ "$(id -u)" -eq 0 ]]; then
    ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_BREAK} ❌ Do not run as root!${TKG_BREAK}${TKG_RESET}"
    exit 1
fi

# 🧑‍💻 Detect Linux Distribution
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

# ❓ Help information display
_help() {
    ${TKG_ECHO} ""
    ${TKG_ECHO} "${TKG_GREEN} Interactive:${TKG_RESET} $0"
    ${TKG_ECHO} "${TKG_GREEN} Commandline:${TKG_RESET} $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p]"
    ${TKG_ECHO} "${TKG_GREEN} Edit Config:${TKG_RESET} $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p] [config|c|edit|e]"
    ${TKG_ECHO} "${TKG_YELLOW} Shortcuts:${TKG_RESET}   l=linux, n=nvidia, m=mesa, w=wine, p=proton, c=config, e=edit"
    ${TKG_ECHO} ""
    ${TKG_ECHO} "${TKG_YELLOW} Example:${TKG_RESET} Run commandline mode directly without menu"
    ${TKG_ECHO} "         $0 linux         # Install Linux-TKG"
    ${TKG_ECHO} "         $0 nvidia        # Install Nvidia-TKG"
    ${TKG_ECHO} "         $0 mesa          # Install Mesa-TKG"
    ${TKG_ECHO} "         $0 wine          # Install Wine-TKG"
    ${TKG_ECHO} "         $0 proton        # Install Proton-TKG"
    ${TKG_ECHO} ""
    ${TKG_ECHO} "${TKG_YELLOW} Example:${TKG_RESET} Edit configuration files directly"
    ${TKG_ECHO} "         $0 linux config  # Edit Linux-TKG config"
    ${TKG_ECHO} "         $0 l c           # Edit Linux-TKG config (short)"
    ${TKG_ECHO} ""
    ${TKG_ECHO} "${TKG_YELLOW} Tip: See all possible shortcuts above${TKG_RESET}"
    ${TKG_ECHO} ""
    ${TKG_ECHO} " 🌐 ${TKG_BLUE}${TKG_REPO} 🐸 ${FROGGING_FAMILY_REPO}${TKG_RESET}"
    ${TKG_ECHO} ""
}

# ❓ Help can show always
if [[ $# -gt 0 && "${1:-}" =~ ^(help|h|-h|--help)$ ]]; then
    _help
fi

# 🔒 Prevent concurrent execution (after help check)
if [[ -f "$TKG_LOCKFILE" ]]; then
    # Check if the process is still running
    if [[ -r "$TKG_LOCKFILE" ]]; then
        old_pid=$(cat "$TKG_LOCKFILE" 2>/dev/null || echo "")
        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            ${TKG_ECHO} " "
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Script is already running (PID: $old_pid). Exiting...${TKG_RESET}"
            ${TKG_ECHO} "${TKG_YELLOW}${TKG_BOLD} 🔁 If the script was unexpectedly terminated, remove the lock file manually:${TKG_RESET}${TKG_BREAK}${TKG_BREAK}    rm -f $TKG_LOCKFILE${TKG_BREAK}${TKG_RESET}"
            exit 1
        else
            ${TKG_ECHO} " "
            ${TKG_ECHO} "${TKG_YELLOW} 🔁 Removing stale lock file...${TKG_BREAK}${TKG_RESET}"
            rm -f "$TKG_LOCKFILE" 2>/dev/null || {
                ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error removing stale lock file! Exiting...${TKG_RESET}"
                exit 1
            }
        fi
    fi
fi
echo $$ > "$TKG_LOCKFILE"

# =============================================================================
# CORE UTILITY FUNCTIONS
# =============================================================================

# 🧹 Cleanup handler for graceful exit
_clean() {
    rm -f "$TKG_LOCKFILE" 2>/dev/null || true
    rm -f "$TKG_CHOICE_FILE" 2>/dev/null || true
    rm -rf "$TKG_TMP_DIR" 2>/dev/null || true

    # Unset exported variables
    unset TKG_REPO TKG_RAW_URL FROGGING_FAMILY_REPO FROGGING_FAMILY_RAW_URL TKG_TMP_DIR FROGGING_FAMILY_CONFIG_DIR TKG_CHOICE_FILE
    unset TKG_ECHO TKG_BREAK TKG_LINE TKG_RESET TKG_BOLD TKG_RED TKG_GREEN TKG_YELLOW TKG_BLUE
    unset TKG_PREVIEW_LINUX TKG_PREVIEW_NVIDIA TKG_PREVIEW_MESA TKG_PREVIEW_WINE TKG_PREVIEW_PROTON
    unset TKG_PREVIEW_CONFIG TKG_PREVIEW_CLEAN TKG_PREVIEW_HELP TKG_PREVIEW_RETURN TKG_PREVIEW_EXIT
 }

# 👋 Setup exit trap for cleanup on script termination
_exit() {
    local exit_code=${1:-$?}
    trap - INT TERM EXIT HUP

    # Message handling
    if [[ $exit_code -ne 0 ]]; then
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} 🎯 ERROR 🎯 TKG-Installer aborted! Exiting...${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
    else
        ${TKG_ECHO} "${TKG_GREEN} 🧹 Cleanup completed!${TKG_RESET}"
        ${TKG_ECHO} "${TKG_GREEN} 👋 TKG-Installer closed!${TKG_RESET}"
        ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
        ${TKG_ECHO} "${TKG_BLUE} 🌐 ${TKG_REPO} 🐸 ${FROGGING_FAMILY_REPO}${TKG_BREAK}${TKG_RESET}"
    fi

    # Perform cleanup
    _clean
    wait
    exit "$exit_code"
}
trap _exit INT TERM EXIT HUP

# 🧩 Fuzzy finder menu wrapper function
_fzf_menu() {
    local menu_content="$1"
    local preview_command="$2"
    local header_text="$3"
    local footer_text="$4"
    local border_label_text="${5:-$TKG_INSTALLER_VERSION}"
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

# ✅ Display completion status with timestamp
_done() {
    local status=$?
    local duration="${SECONDS:-0}"
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 📝 Action completed: $(date '+%Y-%m-%d %H:%M:%S')${TKG_RESET}"
    
    if [[ $status -eq 0 ]]; then
        ${TKG_ECHO} "${TKG_GREEN} ✅ Status: Successful${TKG_RESET}"
    else
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Status: Error (Code: $status)${TKG_RESET}"
    fi

    ${TKG_ECHO} "${TKG_YELLOW} ⏱️ Duration: ${minutes} min ${seconds} sec${TKG_RESET}${TKG_GREEN}${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    ${TKG_ECHO} " "
}

# 🧼 Pre-installation checks and preparation
_pre() {
    local load_preview="${1:-false}"

    # Welcome message
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🐸 TKG-Installer ${TKG_INSTALLER_VERSION} for ${TKG_DISTRO_NAME}${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    ${TKG_ECHO} "${TKG_YELLOW} 🔁 Pre-checks starting...${TKG_RESET}"

    # Check required dependencies
    local dependencies=(bat curl fzf git)
    for required_dependency in "${dependencies[@]}"; do
        if ! command -v "$required_dependency" >/dev/null; then
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ $required_dependency is not installed! Please install it first.${TKG_RESET}"
            ${TKG_ECHO} "${TKG_YELLOW}${TKG_BOLD} 🔁 Run: pacman -S ${required_dependency}${TKG_RESET}"            
            exit 1
        fi
    done

    # Setup temporary directory
    ${TKG_ECHO} "${TKG_YELLOW} 🧹 Cleaning old temporary files...${TKG_RESET}"
    rm -rf "$TKG_TMP_DIR" "$TKG_CHOICE_FILE" 2>/dev/null || true
    ${TKG_ECHO} "${TKG_YELLOW} 🗂️ Create temporary directory...${TKG_RESET}"
    mkdir -p "$TKG_TMP_DIR" 2>/dev/null || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error creating temporary directory: ${TKG_TMP_DIR}${TKG_RESET}"
        return 1
    }

    # Load preview content only for interactive mode
    if [[ "$load_preview" == "true" ]]; then
        ${TKG_ECHO} "${TKG_YELLOW} 📡 Retrieving preview content...${TKG_RESET}"
        _init_preview
    fi

    # Final message
    ${TKG_ECHO} "${TKG_GREEN} 🐸 Starting...${TKG_RESET}"

    # Short delay for better UX
    wait
    sleep 1
}

# =============================================================================
# PREVIEW FUNCTIONS
# =============================================================================

# 📝 Dynamic preview content generator for fzf menus
_get_preview() {
    local preview_choice="$1"
    local frogging_family_preview_url=""
    local tkg_installer_preview_url=""
    
    # Define repository URLs and static previews for each TKG package
    case "$preview_choice" in
        linux)
            tkg_installer_preview_url="${TKG_RAW_URL}/linux.md"
            frogging_family_preview_url="${FROGGING_FAMILY_RAW_URL}/linux-tkg/refs/heads/master/README.md"
            ;;
        nvidia)
            tkg_installer_preview_url="${TKG_RAW_URL}/nvidia.md"
            frogging_family_preview_url="${FROGGING_FAMILY_RAW_URL}/nvidia-all/refs/heads/master/README.md"
            ;;
        mesa)
            tkg_installer_preview_url="${TKG_RAW_URL}/mesa.md"
            frogging_family_preview_url="${FROGGING_FAMILY_RAW_URL}/mesa-git/refs/heads/master/README.md"
            ;;
        wine)
            tkg_installer_preview_url="${TKG_RAW_URL}/wine.md"
            frogging_family_preview_url="${FROGGING_FAMILY_RAW_URL}/wine-tkg-git/refs/heads/master/wine-tkg-git/README.md"
            ;;
        proton)
            tkg_installer_preview_url="${TKG_RAW_URL}/proton.md"
            frogging_family_preview_url="${FROGGING_FAMILY_RAW_URL}/wine-tkg-git/refs/heads/master/proton-tkg/README.md"
            ;;
        config)
            tkg_installer_preview_url="${TKG_RAW_URL}/config.md"
            ;;
        clean)
            tkg_installer_preview_url="${TKG_RAW_URL}/clean.md"
            ;;
        help)
            tkg_installer_preview_url="${TKG_RAW_URL}/help.md"
            ;;
        exit)
            tkg_installer_preview_url="${TKG_RAW_URL}/exit.md"
            ;;
        return)
            tkg_installer_preview_url="${TKG_RAW_URL}/return.md"
            ;;
    esac
       
   # Display TKG-INSTALLER remote preview content
    if [[ -n "$tkg_installer_preview_url" ]]; then
        # Download content
        local tkg_installer_content=""
        tkg_installer_content=$(curl -fsSL --max-time 10 "${tkg_installer_preview_url}" 2>/dev/null)
        # View content 
        if [[ -n "$tkg_installer_content" ]]; then
            ${TKG_ECHO} " "
            ${TKG_ECHO} "$tkg_installer_content" | bat --plain --language=md --wrap character --highlight-line 1 --force-colorization 2>/dev/null
        fi
    fi
       
   # Display FROGGING-FAMILY remote preview content
    if [[ -n "$frogging_family_preview_url" ]]; then
        # Download content
        local frogging_family_content=""
        #frogging_family_content=$(curl -fsSL --max-time 10 "${frogging_family_preview_url}" 2>/dev/null)
        # View content 
        if [[ -n "$frogging_family_content" ]]; then
            ${TKG_ECHO} " "
            ${TKG_ECHO} "$frogging_family_content" | bat --plain --language=md --wrap never --highlight-line 1 --force-colorization 2>/dev/null
        fi
    fi
}

# 📝 Preview content is initialized only for interactive mode
_init_preview() {
    # Dynamic previews from remote
    TKG_PREVIEW_LINUX="$(_get_preview linux)"
    TKG_PREVIEW_NVIDIA="$(_get_preview nvidia)"
    TKG_PREVIEW_MESA="$(_get_preview mesa)"
    TKG_PREVIEW_WINE="$(_get_preview wine)"
    TKG_PREVIEW_PROTON="$(_get_preview proton)"
    TKG_PREVIEW_CONFIG="$(_get_preview config)"
    TKG_PREVIEW_CLEAN="$(_get_preview clean)"
    TKG_PREVIEW_HELP="$(_get_preview help)"
    TKG_PREVIEW_RETURN="$(_get_preview return)"
    TKG_PREVIEW_EXIT="$(_get_preview exit)"

    export TKG_PREVIEW_LINUX TKG_PREVIEW_NVIDIA TKG_PREVIEW_MESA TKG_PREVIEW_WINE TKG_PREVIEW_PROTON
    export TKG_PREVIEW_CONFIG TKG_PREVIEW_CLEAN TKG_PREVIEW_HELP TKG_PREVIEW_RETURN TKG_PREVIEW_EXIT
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# 🛠️ Generic package installation helper
_install_package() {
    local repo_url="$1"
    local package_name="$2"
    local build_command="$3"
    local clean_command="${4:-}"  # Optional clean command after build proton-tkg only
    local work_directory="${5:-}"   # Optional working directory relative to cloned repo

    cd "$TKG_TMP_DIR" || return 1

    # Clone repository
    git clone "$repo_url" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} ❌ Error cloning: $package_name for ${TKG_DISTRO_NAME}${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
        return 1
    }

    # Navigate to the correct directory (assume it's the cloned repo name)
    local repo_dir
    repo_dir=$(basename "$repo_url" .git)
    cd "$repo_dir" || return 1

    # Navigate to working directory if specified
    if [[ -n "$work_directory" ]]; then
        cd "$work_directory" || {
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} ❌ Error: Working directory not found: $work_directory${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
            return 1
        }
    fi

    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-bold --no-art --http-url --email --number-of-authors 6 --text-colors 15 3 15 3 15 11 || true
    fi

    # Build and install
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing $package_name for ${TKG_DISTRO_NAME}, this may take a while... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
    eval "$build_command" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} ❌ Error building: $package_name for ${TKG_DISTRO_NAME}${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
        return 1
    }

    # Optional clean up
    if [[ -n "$clean_command" ]]; then
        ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Clean up build artifacts...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
        eval "$clean_command" || {
            ${TKG_ECHO} "${TKG_YELLOW}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} ✅ Nothing to clean: $package_name${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
            return 1
        }
    fi
}

# 🧠 Linux-TKG installation
_linux_install() {
    local distro_id="${TKG_DISTRO_ID,,}"
    local distro_like="${TKG_DISTRO_ID_LIKE,,}"
    local build_command

    if [[ "${distro_id}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${distro_like}" == *"arch"* ]]; then
        build_command="makepkg -si"
    else
        build_command="chmod +x install.sh && ./install.sh install"
    fi

    _install_package "${FROGGING_FAMILY_REPO}/linux-tkg.git" "linux-tkg" "$build_command"
}

# 🖥️ Nvidia-TKG installation
_nvidia_install() {
    _install_package "${FROGGING_FAMILY_REPO}/nvidia-all.git" "nvidia-all" "makepkg -si"
}

# 🧩 Mesa-TKG installation
_mesa_install() {
    _install_package "${FROGGING_FAMILY_REPO}/mesa-git.git" "mesa-git" "makepkg -si"
}

# 🍷 Wine-TKG installation
_wine_install() {
    local distro_id="${TKG_DISTRO_ID,,}"
    local distro_like="${TKG_DISTRO_ID_LIKE,,}"
    local build_command

    if [[ "${distro_id}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${distro_like}" == *"arch"* ]]; then
        build_command="makepkg -si"
    else
        build_command="chmod +x non-makepkg-build.sh && ./non-makepkg-build.sh"
    fi

    _install_package "${FROGGING_FAMILY_REPO}/wine-tkg-git.git" "wine-tkg-git" "$build_command" "" "wine-tkg-git"
}

# 🎮 Proton-TKG installation
_proton_install() {
    _install_package "${FROGGING_FAMILY_REPO}/wine-tkg-git.git" "wine-tkg-git" "./proton-tkg.sh" "./proton-tkg.sh clean" "proton-tkg"
}

# =============================================================================
# EDITOR MANAGEMENT FUNCTION
# =============================================================================

# 📝 Text editor wrapper with fallback support
_editor() {
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
            ${TKG_ECHO} "${TKG_YELLOW}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} ⚠️ No editor found: please set \$EDITOR environment or install 'nano'.${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
            sleep 2
            return 1
        fi
    fi

    # Execute the editor with the target target_file
    "${editor_parts[@]}" "$target_file"
}

# 🔧 Configuration file editor with interactive menu
_edit_config() {
    while true; do
        local config_choice

        # Ensure configuration directory exists
        if [[ ! -d "${FROGGING_FAMILY_CONFIG_DIR}" ]]; then
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} ❌ Configuration directory not found: ${FROGGING_FAMILY_CONFIG_DIR}${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
            read -r -p "Do you want to create the configuration directory? [y/N]: " create_dir
            echo
            case "$create_dir" in
                y|Y|yes)
                    mkdir -p "${FROGGING_FAMILY_CONFIG_DIR}" || {
                        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} ❌ Error creating configuration directory!${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
                        sleep 3
                        clear
                        return 1
                    }
                    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} ✅ Configuration directory created: ${FROGGING_FAMILY_CONFIG_DIR}${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
                    sleep 3
                    ;;
                *)
                    ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} ⚠️ Directory creation cancelled. Return to Mainmenu...${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
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
        local error_config_not_exist="${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} ❌ Error: No external configuration file found.${TKG_BREAK}${TKG_BREAK} ⚠️ Click to download missing file${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
        
        # Define a reusable bat command for the preview
        local bat_cmd="bat --style=numbers --language=bash --wrap character --highlight-line 1 --force-colorization"

        local preview_command='
            key=$(echo {} | cut -d"|" -f1 | xargs)
            config_file_path="'"${FROGGING_FAMILY_CONFIG_DIR}"'/${key}.cfg"

            # For wine-tkg, the config file name is different
            if [[ "$key" == "wine-tkg" ]]; then
                config_file_path="'"${FROGGING_FAMILY_CONFIG_DIR}"'/wine-tkg.cfg"
            fi
            
            case $key in
                linux-tkg|nvidia-all|mesa-git|wine-tkg|proton-tkg)
                    '"$bat_cmd"' "$config_file_path" 2>/dev/null || '"${TKG_ECHO}"' "'"$error_config_not_exist"'"
                    ;;
                return)
                    $TKG_ECHO "$TKG_PREVIEW_RETURN"
                    ;;
            esac
        '
        local header_text=$'🐸 TKG-Installer ─ Editor menue\n\n   Edit external configuration file\n   Default directory: ~/.config/frogminer/'
        local footer_text=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\n🐸 Frogging-Family: https://github.com/Frogging-Family\n🌐 About: https://github.com/damachine/tkginstaller'
        local border_label_text="${TKG_INSTALLER_VERSION}"
        local preview_window_settings='right:wrap:70%'

        config_choice=$(_fzf_menu "$menu_content" "$preview_command" "$header_text" "$footer_text" "$border_label_text" "$preview_window_settings")

        # Handle cancelled selection
        if [[ -z "$config_choice" ]]; then
            ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} ⏪ Exit editor menu...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
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
                _handle_config \
                    "Linux-TKG" \
                    "${FROGGING_FAMILY_CONFIG_DIR}/linux-tkg.cfg" \
                    "${FROGGING_FAMILY_RAW_URL}/linux-tkg/master/customization.cfg"
                ;;
            nvidia-all)
                _handle_config \
                    "Nvidia-TKG" \
                    "${FROGGING_FAMILY_CONFIG_DIR}/nvidia-all.cfg" \
                    "${FROGGING_FAMILY_RAW_URL}/nvidia-all/master/customization.cfg"
                ;;
            mesa-git)
                _handle_config \
                    "Mesa-TKG" \
                    "${FROGGING_FAMILY_CONFIG_DIR}/mesa-git.cfg" \
                    "${FROGGING_FAMILY_RAW_URL}/mesa-git/master/customization.cfg"
                ;;
            wine-tkg)
                _handle_config \
                    "Wine-TKG" \
                    "${FROGGING_FAMILY_CONFIG_DIR}/wine-tkg.cfg" \
                    "${FROGGING_FAMILY_RAW_URL}/wine-tkg-git/master/wine-tkg-git/customization.cfg"
                ;;
            proton-tkg)
                _handle_config \
                    "Proton-TKG" \
                    "${FROGGING_FAMILY_CONFIG_DIR}/proton-tkg.cfg" \
                    "${FROGGING_FAMILY_RAW_URL}/wine-tkg-git/master/proton-tkg/proton-tkg.cfg"
                ;;
            return)
                ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} ⏪ Exit editor menu...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
                sleep 1
                clear
                return 0
                ;;
            *)
                ${TKG_ECHO} " "
                ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Invalid option: $TKG_CHOICE${TKG_RESET}"
                ${TKG_ECHO} "${TKG_GREEN} Usage:${TKG_RESET} $0 help${TKG_RESET}"
                ${TKG_ECHO} "        $0 [linux|nvidia|mesa|wine|proton]${TKG_BREAK}${TKG_RESET}"
                return 1
                ;;
        esac
    done
}

# 📝 Helper function to handle individual config file editing
_handle_config() {
    local config_name="$1"
    local config_path="$2" 
    local config_url="$3"
    
    ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} 🔧 Opening external $config_name configuration file...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    sleep 1
    clear
    
    if [[ -f "$config_path" ]]; then
        # Edit existing configuration file
        _editor "$config_path" || {
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} ❌ Error opening $config_path configuration!${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
            sleep 3
            clear
            return 1
        }
    else
        # Download and create new configuration file
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} ⚠️ $config_path does not exist.${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
        read -r -p "Do you want to download the default configuration from $config_url? [y/N]: " user_answer
        echo
        case "$user_answer" in
            y|Y|yes)
                mkdir -p "$(dirname "$config_path")"
                if curl -fsSL "$config_url" -o "$config_path" 2>/dev/null; then
                    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} ✅ Configuration ready at $config_path${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
                    sleep 3
                    clear
                    _editor "$config_path" || {
                        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} ❌ Error opening $config_path configuration!${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
                        sleep 3
                        clear
                        return 1
                    }
                else
                    ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} ❌ Error downloading configuration from $config_url${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
                    sleep 3
                    clear
                    return 1
                fi
                ;;
            *)
                ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} ⚠️ Download cancelled. No configuration file created. Return to Mainmenu...${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
                sleep 3
                clear
                return 1
                ;;
        esac

        # Clear screen
        clear
    fi
    
    ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} ✅ Closing external $config_name configuration file...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    sleep 1
    clear
    return 0
}

# =============================================================================
# PROMT MENUE FUNCTIONS
# =============================================================================

# 📋 Combined Linux + Nvidia installation
_linuxnvidia_prompt() {
    SECONDS=0
    _linux_prompt || true
    _nvidia_prompt || true
}

# 🧠 Linux-TKG installation prompt
_linux_prompt() {
    SECONDS=0
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🧠 Fetching Linux-TKG from Frogging-Family repository... ⏳${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    _linux_install || true
    _done
}

# 🖥️ Nvidia-TKG installation prompt
_nvidia_prompt() {
    SECONDS=0
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🖥️ Fetching Nvidia-TKG from Frogging-Family repository... ⏳${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    _nvidia_install || true
    _done
}

# 🧩 Mesa-TKG installation prompt
_mesa_prompt() {
    SECONDS=0
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🧩 Fetching Mesa-TKG from Frogging-Family repository... ⏳${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    _mesa_install || true
    _done
}

# 🍷 Wine-TKG installation prompt
_wine_prompt() {
    SECONDS=0
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🍷 Fetching Wine-TKG from Frogging-Family repository... ⏳${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    _wine_install || true
    _done
}

# 🎮 Proton-TKG installation prompt
_proton_prompt() {
    SECONDS=0
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🎮 Fetching Proton-TKG from Frogging-Family repository... ⏳${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    _proton_install || true
    _done
}

# 🛠️ Configuration editor prompt
_config_prompt() {
    _edit_config || true
}

# =============================================================================
# FZF MAINMENUE FUNCTIONS
# =============================================================================

# 🎛️ Interactive main menu with fzf preview
_menu() {
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
            Linux*) $TKG_ECHO "$TKG_PREVIEW_LINUX" ;;
            Nvidia*) $TKG_ECHO "$TKG_PREVIEW_NVIDIA" ;;
            Mesa*) $TKG_ECHO "$TKG_PREVIEW_MESA" ;;
            Wine*) $TKG_ECHO "$TKG_PREVIEW_WINE" ;;
            Proton*) $TKG_ECHO "$TKG_PREVIEW_PROTON" ;;
            Config*) $TKG_ECHO "$TKG_PREVIEW_CONFIG" ;;
            Clean*) $TKG_ECHO "$TKG_PREVIEW_CLEAN" ;;
            Help*) $TKG_ECHO "$TKG_PREVIEW_HELP" ;;
            Exit*) $TKG_ECHO "$TKG_PREVIEW_EXIT" ;;
        esac
    '
    local header_text=$'🐸 TKG-Installer ─ Select a option\n\n   Manage the popular TKG packages from the Frogging-Family repositories.'
    local footer_text=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\n🐸 Frogging-Family: https://github.com/Frogging-Family\n🌐 About: https://github.com/damachine/tkginstaller'
    local border_label_text="${TKG_INSTALLER_VERSION}"
    local preview_window_settings='right:wrap:60%'

    local main_choice
    main_choice=$(_fzf_menu "$menu_content" "$preview_command" "$header_text" "$footer_text" "$border_label_text" "$preview_window_settings")

    # Handle cancelled selection (ESC pressed)
    if [[ -z "${main_choice:-}" ]]; then
        ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} 👋 Exit TKG-Installer...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
        sleep 1
        clear
        _exit 0
    fi

    # Save selection to temporary file for processing
    echo "$main_choice" | cut -d"|" -f1 | xargs > "$TKG_CHOICE_FILE"
}

# =============================================================================
# MAIN PROGRAM ENTRY POINT
# =============================================================================

# ➡ Handle direct command-line arguments for quick execution
_handle_direct_mode() {
    local arg1="${1,,}"  # Convert to lowercase
    local arg2="${2,,}"  # Convert to lowercase
    
    # Check if second argument exists but is invalid
    if [[ -n "$arg2" && ! "$arg2" =~ ^(config|c|edit|e)$ ]]; then
        # Second argument is invalid
        ${TKG_ECHO} " "
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Invalid second argument: ${2}${TKG_RESET}"
        ${TKG_ECHO} "${TKG_YELLOW}    Valid options:${TKG_RESET} config, c, edit, e"
        ${TKG_ECHO} "${TKG_YELLOW}    Usage:${TKG_RESET} $0 help${TKG_RESET}"
        ${TKG_ECHO} "           $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p]${TKG_RESET}"
        ${TKG_ECHO} "           $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p] [config|c|edit|e]${TKG_BREAK}${TKG_RESET}"
        
        # Disable exit trap before cleanup and exit
        trap - INT TERM EXIT HUP
        
        # Clean exit without triggering _exit cleanup messages. Unset exported all variables
        _clean
        exit 1
    fi
    
    # Check if second argument is config-related
    if [[ -n "$arg2" && "$arg2" =~ ^(config|c|edit|e)$ ]]; then
        # Handle config editing: linux config, l c, config linux, etc.
        local package=""
        case "$arg1" in
            linux|l) package="linux-tkg" ;;
            nvidia|n) package="nvidia-all" ;;
            mesa|m) package="mesa-git" ;;
            wine|w) package="wine-tkg" ;;
            proton|p) package="proton-tkg" ;;
            config|c|edit|e)
                # If first arg is config, check second arg for package
                case "$arg2" in
                    linux|l) package="linux-tkg" ;;
                    nvidia|n) package="nvidia-all" ;;
                    mesa|m) package="mesa-git" ;;
                    wine|w) package="wine-tkg" ;;
                    proton|p) package="proton-tkg" ;;
                esac
                ;;
        esac
        
        if [[ -n "$package" ]]; then
            # Determine config file path and URL based on package
            local config_path="${FROGGING_FAMILY_CONFIG_DIR}/${package}.cfg"
            local config_url=""
            local config_name=""
            
            case "$package" in
                linux-tkg)
                    config_name="Linux-TKG"
                    config_url="${FROGGING_FAMILY_RAW_URL}/linux-tkg/master/customization.cfg"
                    ;;
                nvidia-all)
                    config_name="Nvidia-TKG"
                    config_url="${FROGGING_FAMILY_RAW_URL}/nvidia-all/master/customization.cfg"
                    ;;
                mesa-git)
                    config_name="Mesa-TKG"
                    config_url="${FROGGING_FAMILY_RAW_URL}/mesa-git/master/customization.cfg"
                    ;;
                wine-tkg)
                    config_name="Wine-TKG"
                    config_url="${FROGGING_FAMILY_RAW_URL}/wine-tkg-git/master/wine-tkg-git/customization.cfg"
                    ;;
                proton-tkg)
                    config_name="Proton-TKG"
                    config_url="${FROGGING_FAMILY_RAW_URL}/wine-tkg-git/master/proton-tkg/proton-tkg.cfg"
                    ;;
            esac
            
            # Disable exit trap before handling config
            trap - INT TERM EXIT HUP
            
            # Handle config file
            _handle_config "$config_name" "$config_path" "$config_url"
            
            # Display exit messages
            ${TKG_ECHO} "${TKG_GREEN} 🧹 Cleanup completed!${TKG_RESET}"
            ${TKG_ECHO} "${TKG_GREEN} 👋 TKG-Installer closed!${TKG_RESET}"
            ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
            ${TKG_ECHO} "${TKG_BLUE} 🌐 ${TKG_REPO} 🐸 ${FROGGING_FAMILY_REPO}${TKG_BREAK}${TKG_RESET}"
            
            # Clean exit
            _clean
            exit 0
        fi
    fi
    
    # Handle regular install commands
    case "$arg1" in
        linux|l)
            _pre
            _linux_prompt
            exit 0
            ;;
        nvidia|n)
            _pre
            _nvidia_prompt
            exit 0
            ;;
        mesa|m)
            _pre
            _mesa_prompt
            exit 0
            ;;
        wine|w)
            _pre
            _wine_prompt
            exit 0
            ;;
        proton|p)
            _pre
            _proton_prompt
            exit 0
            ;;
        
        help|h|--help|-h)
            # Disable exit trap before cleanup and exit
            trap - INT TERM EXIT HUP
                
            # Clean exit without triggering _exit cleanup messages. Unset exported all variables
            _clean
            exit 0
            ;;
        *)
            # Invalid argument handling
            ${TKG_ECHO} " "
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Invalid argument: ${1:-}${TKG_RESET}"
            ${TKG_ECHO} "${TKG_YELLOW}    Usage:${TKG_RESET} $0 help${TKG_RESET}"
            ${TKG_ECHO} "           $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p]${TKG_RESET}"
            ${TKG_ECHO} "           $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p] [config|c|edit|e]${TKG_BREAK}${TKG_RESET}"
            
            # Disable exit trap before cleanup and exit
            trap - INT TERM EXIT HUP
            
            # Clean exit without triggering _exit cleanup messages. Unset exported all variables
            _clean
            exit 1
            ;;
    esac
}

# ▶️ Main function for interactive mode
_main_interactive() {
    # Interactive mode - show menu and handle user selection
    _pre true
    clear
    _menu

    # Process user selection from menu
    local user_choice
    user_choice=$(< "$TKG_CHOICE_FILE")
    rm -f "$TKG_CHOICE_FILE"

    case $user_choice in
        Linux)
            _linux_prompt
            ;;
        Nvidia)
            _nvidia_prompt
            ;;
        Mesa)
            _mesa_prompt
            ;;
        Wine)
            _wine_prompt
            ;;
        Proton)
            _proton_prompt
            ;;
        Config)
            _config_prompt
            rm -f "$TKG_LOCKFILE"
            clear
            exec "$0"
            ;;
        Help)
            # Help argument handling
            _help

            # Disable exit trap before cleanup and exit
            trap - INT TERM EXIT HUP
                
            # Clean exit without triggering _exit cleanup messages. Unset exported all variables
            _clean
            exit 0
            ;;
        Clean)
            ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} 🧹 Cleaning temporary files...${TKG_BREAK} 🔁 Restarting...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"      
            _pre >/dev/null 2>&1 || true
            rm -f "$TKG_LOCKFILE" 2>&1 || true
            sleep 1
            clear
            exec "$0" 
            ;;
        Exit)
            ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} 👋 Exit TKG-Installer...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
            sleep 1
            clear
            exit 0
            ;;
    esac
}

# ▶️ Main function - handles command line arguments and menu interaction
_main() {
    # Handle direct command line arguments for automation
    if [[ $# -gt 0 ]]; then
        _handle_direct_mode "$@"
    else
        _main_interactive
    fi
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Start the main program with all provided arguments
_main "$@"
