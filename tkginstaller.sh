#!/usr/bin/env bash

# Fuzzy finder run in a separate shell and brings SC2016, SC2218 fail warnings. Allow fzf to expand variables in its own shell at runtime
# shellcheck disable=SC2016
# shellcheck disable=SC2218

# TKG-Installer VERSION
readonly TKG_INSTALLER_VERSION="v0.10.9"

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
# ENVIRONMENT SETUP
# =============================================================================

# 🔒 Safety settings and strict mode
#set -euo pipefail

# 🌐 Force standard locale for consistent behavior (sorting, comparisons, messages)
#export LC_ALL=C

# 📌 Global paths and configuration
readonly TKG_INSTALLER_LOCKFILE="/tmp/tkginstaller.lock"
TKG_INSTALLER_REPO="https://github.com/damachine/tkginstaller"
TKG_INSTALLER_RAW="https://raw.githubusercontent.com/damachine/tkginstaller/refs/heads/master/docs"
FROGGING_FAMILY_REPO="https://github.com/Frogging-Family"
FROGGING_FAMILY_RAW="https://raw.githubusercontent.com/Frogging-Family"
TKG_INSTALLER_DIR="$HOME/.cache/tkginstaller"
TKG_INSTALLER_CONFIG_DIR="$HOME/.config/frogminer"
TKG_INSTALLER_CHOICE_FILE="${TKG_INSTALLER_DIR}/choice.tmp"

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
export TKG_INSTALLER_REPO TKG_INSTALLER_RAW FROGGING_FAMILY_REPO FROGGING_FAMILY_RAW TKG_INSTALLER_DIR TKG_INSTALLER_CONFIG_DIR TKG_INSTALLER_CHOICE_FILE
export TKG_ECHO TKG_BREAK TKG_LINE TKG_RESET TKG_BOLD TKG_RED TKG_GREEN TKG_YELLOW TKG_BLUE

# Check for root execution
if [[ "$(id -u)" -eq 0 ]]; then
    ${TKG_ECHO} " "
    ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Do not run as root!${TKG_RESET}"
    ${TKG_ECHO} " "
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
    ${TKG_ECHO} " "
    ${TKG_ECHO} "${TKG_GREEN} Interactive:${TKG_RESET} $0"
    ${TKG_ECHO} "${TKG_GREEN} Commandline:${TKG_RESET} $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p]"
    ${TKG_ECHO} "${TKG_YELLOW} Shortcuts:${TKG_RESET}   l=linux, n=nvidia, m=mesa, w=wine, p=proton"
    ${TKG_ECHO} " "
    ${TKG_ECHO} "${TKG_YELLOW} Example:${TKG_RESET} Run commandline mode directly without menu"
    ${TKG_ECHO} "         $0 linux         # Install Linux-TKG${TKG_RESET}"
    ${TKG_ECHO} "         $0 nvidia        # Install Nvidia-TKG${TKG_RESET}"
    ${TKG_ECHO} "         $0 mesa          # Install Mesa-TKG${TKG_RESET}"
    ${TKG_ECHO} "         $0 wine          # Install Wine-TKG${TKG_RESET}"
    ${TKG_ECHO} "         $0 proton        # Install Proton-TKG${TKG_RESET}"
    ${TKG_ECHO} " "
}

if [[ $# -gt 0 && "${1:-}" =~ ^(help|-h|--help)$ ]]; then
    _help
fi

# 🔒 Prevent concurrent execution (after help check)
if [[ -f "$TKG_INSTALLER_LOCKFILE" ]]; then
    # Check if the process is still running
    if [[ -r "$TKG_INSTALLER_LOCKFILE" ]]; then
        OLD_PID=$(cat "$TKG_INSTALLER_LOCKFILE" 2>/dev/null || echo "")
        if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
            ${TKG_ECHO} " "
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Script is already running (PID: $OLD_PID). Exiting...${TKG_RESET}"
            ${TKG_ECHO} "${TKG_YELLOW}${TKG_BOLD} 🔁 If the script was unexpectedly terminated, remove the lock file manually:${TKG_RESET}${TKG_BREAK}${TKG_BREAK}    rm -f $TKG_INSTALLER_LOCKFILE${TKG_BREAK}${TKG_RESET}"
            exit 1
        else
            ${TKG_ECHO} " "
            ${TKG_ECHO} "${TKG_YELLOW} 🔁 Removing stale lock file...${TKG_BREAK}${TKG_RESET}"
            rm -f "$TKG_INSTALLER_LOCKFILE" 2>/dev/null || {
                ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error removing stale lock file! Exiting...${TKG_RESET}"
                exit 1
            }
        fi
    fi
fi
echo $$ > "$TKG_INSTALLER_LOCKFILE"

# =============================================================================
# CORE UTILITY FUNCTIONS
# =============================================================================

# 🧹 Cleanup handler for graceful exit

# Cleanup function to remove temporary files and lockfile
_clean() {
    rm -f "$TKG_INSTALLER_LOCKFILE" 2>/dev/null || true
    rm -f "$TKG_INSTALLER_CHOICE_FILE" 2>/dev/null || true
    rm -rf "$TKG_INSTALLER_DIR" 2>/dev/null || true

    # Unset exported variables
    unset TKG_INSTALLER_REPO TKG_INSTALLER_RAW FROGGING_FAMILY_REPO FROGGING_FAMILY_RAW TKG_INSTALLER_DIR TKG_INSTALLER_CONFIG_DIR TKG_INSTALLER_CHOICE_FILE
    unset TKG_ECHO TKG_BREAK TKG_LINE TKG_RESET TKG_BOLD TKG_RED TKG_GREEN TKG_YELLOW TKG_BLUE
    unset TKG_PREVIEW_LINUX TKG_PREVIEW_NVIDIA TKG_PREVIEW_MESA TKG_PREVIEW_WINE TKG_PREVIEW_PROTON
 }

_exit() {
    local code=${1:-$?}
    trap - INT TERM EXIT HUP

    # Message handling
    if [[ $code -ne 0 ]]; then
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} 🎯 ERROR 🎯 TKG-Installer aborted! Exiting...${TKG_BREAK}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
    else
        ${TKG_ECHO} "${TKG_GREEN} 🌐${TKG_RESET}${TKG_BLUE} ${TKG_INSTALLER_REPO} 🐸 ${FROGGING_FAMILY_REPO}${TKG_RESET}"
        ${TKG_ECHO} " "
        ${TKG_ECHO} "${TKG_GREEN} 🧹 Cleanup completed!${TKG_RESET}"
        ${TKG_ECHO} "${TKG_GREEN} 👋 TKG-Installer closed!${TKG_RESET}"
        ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
    fi

    # Perform cleanup
    _clean
    wait
    exit "$code"
}
# Setup exit trap for cleanup on script termination
trap _exit INT TERM EXIT HUP

# 🧩 Fuzzy finder menu wrapper function
_fzf_menu() {
    local menu_content="$1"
    local preview_cmd="$2"
    local header="$3"
    local footer="$4"
    local border_label="${5:-$TKG_INSTALLER_VERSION}"
    local preview_window="${6:-right:nowrap:60%}"

    fzf \
        --with-shell='bash -c' \
        --style minimal \
        --color='header:#00ff00,pointer:#00ff00,marker:#00ff00' \
        --border=none \
        --border-label="${border_label}" \
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
        --header="${header}" \
        --header-border=line \
        --header-label="${border_label}" \
        --header-label-pos=256 \
        --header-first \
        --footer="${footer}" \
        --footer-border=line \
        --preview-window="${preview_window}" \
        --preview="${preview_cmd}" \
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

    # Welcome message
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🐸 TKG-Installer ${TKG_INSTALLER_VERSION} for ${TKG_DISTRO_NAME}${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    ${TKG_ECHO} "${TKG_YELLOW} 🔁 Pre-checks starting...${TKG_RESET}"

    # Check required dependencies
    local TKG_DEPENDENCIES=(bat curl fzf git)
    for TKG_REQUIRED in "${TKG_DEPENDENCIES[@]}"; do
        if ! command -v "$TKG_REQUIRED" >/dev/null; then
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ $TKG_REQUIRED is not installed! Please install it first.${TKG_RESET}"
            ${TKG_ECHO} "${TKG_YELLOW}${TKG_BOLD} 🔁 Run: pacman -S ${TKG_REQUIRED}${TKG_RESET}"            
            exit 1
        fi
    done

    # Setup temporary directory
    ${TKG_ECHO} "${TKG_YELLOW} 🧹 Cleaning old temporary files...${TKG_RESET}"
    rm -rf "$TKG_INSTALLER_DIR" "$TKG_INSTALLER_CHOICE_FILE" 2>/dev/null || true
    ${TKG_ECHO} "${TKG_YELLOW} 🗂️ Create temporary directory...${TKG_RESET}"
    mkdir -p "$TKG_INSTALLER_DIR" 2>/dev/null || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error creating temporary directory: ${TKG_INSTALLER_DIR}${TKG_RESET}"
        return 1
    }

    # Message for preview section
    ${TKG_ECHO} "${TKG_YELLOW} 📡 Retrieving content...${TKG_RESET}"

    # Final message
    ${TKG_ECHO} "${TKG_GREEN} 🐸 Starting...${TKG_RESET}"
    sleep 1
}

# =============================================================================
# PREVIEW FUNCTIONS
# =============================================================================

# 📝 Dynamic preview content generator for fzf menus
_get_preview() {
    local TKG_PREVIEW_CHOICE="$1"
    local FROGGING_FAMILY_PREVIEW_URL=""
    local TKG_INSTALLER_PREVIEW_URL=""
    
    # Define repository URLs and static previews for each TKG package
    case "$TKG_PREVIEW_CHOICE" in
        linux)
            TKG_INSTALLER_PREVIEW_URL="${TKG_INSTALLER_RAW}/linux.md"
            FROGGING_FAMILY_PREVIEW_URL="${FROGGING_FAMILY_RAW}/linux-tkg/refs/heads/master/README.md"
            ;;
        nvidia)
            TKG_INSTALLER_PREVIEW_URL="${TKG_INSTALLER_RAW}/nvidia.md"
            FROGGING_FAMILY_PREVIEW_URL="${FROGGING_FAMILY_RAW}/nvidia-all/refs/heads/master/README.md"
            ;;
        mesa)
            TKG_INSTALLER_PREVIEW_URL="${TKG_INSTALLER_RAW}/mesa.md"
            FROGGING_FAMILY_PREVIEW_URL="${FROGGING_FAMILY_RAW}/mesa-git/refs/heads/master/README.md"
            ;;
        wine)
            TKG_INSTALLER_PREVIEW_URL="${TKG_INSTALLER_RAW}/wine.md"
            FROGGING_FAMILY_PREVIEW_URL="${FROGGING_FAMILY_RAW}/wine-tkg-git/refs/heads/master/wine-tkg-git/README.md"
            ;;
        proton)
            TKG_INSTALLER_PREVIEW_URL="${TKG_INSTALLER_RAW}/proton.md"
            FROGGING_FAMILY_PREVIEW_URL="${FROGGING_FAMILY_RAW}/wine-tkg-git/refs/heads/master/proton-tkg/README.md"
            ;;
    esac
       
   # Display TKG-INSTALLER remote preview content
    if [[ -n "$TKG_INSTALLER_PREVIEW_URL" ]]; then
        # Download content
        local tkg_installer_content=""
        if command -v curl >/dev/null 2>&1; then
            tkg_installer_content=$(curl -fsSL --max-time 10 "${TKG_INSTALLER_PREVIEW_URL}" 2>/dev/null)
        fi
        # View content 
        if [[ -n "$tkg_installer_content" ]]; then
            if command -v bat >/dev/null 2>&1; then
                ${TKG_ECHO} " "
                ${TKG_ECHO} "$tkg_installer_content" | bat --plain --language=md --wrap never --highlight-line 1 --force-colorization 2>/dev/null
            fi
        fi
    fi
       
   # Display FROGGING-FAMILY remote preview content
    if [[ -n "$FROGGING_FAMILY_PREVIEW_URL" ]]; then
        # Download content
        local frogging_family_content=""
        if command -v curl >/dev/null 2>&1; then
            frogging_family_content=$(curl -fsSL --max-time 10 "${FROGGING_FAMILY_PREVIEW_URL}" 2>/dev/null)
        fi
        # View content 
        if [[ -n "$frogging_family_content" ]]; then
            if command -v bat >/dev/null 2>&1; then
                ${TKG_ECHO} " "
                ${TKG_ECHO} "$frogging_family_content" | bat --plain --language=md --wrap never --highlight-line 1 --force-colorization 2>/dev/null
            fi
        fi
    fi
}

# 📝 Preview content is initialized only for interactive mode
_init_preview() {
    TKG_PREVIEW_LINUX="$(_get_preview linux)"
    TKG_PREVIEW_NVIDIA="$(_get_preview nvidia)"
    TKG_PREVIEW_MESA="$(_get_preview mesa)"
    TKG_PREVIEW_WINE="$(_get_preview wine)"
    TKG_PREVIEW_PROTON="$(_get_preview proton)"
    export TKG_PREVIEW_LINUX TKG_PREVIEW_NVIDIA TKG_PREVIEW_MESA TKG_PREVIEW_WINE TKG_PREVIEW_PROTON
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# 🧠 Linux-TKG installation
_linux_install() {
    cd "$TKG_INSTALLER_DIR" || return 1
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/linux-tkg.git" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error cloning: linux-tkg for ${TKG_DISTRO_NAME}${TKG_RESET}"
        return 1
    }
    
    cd linux-tkg || return 1
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --email --number-of-authors 6 --text-colors 3 15 3 3 15 3 || true
    fi
    
    # Build and install based on distribution
    local DISTRO_ID="${TKG_DISTRO_ID,,}"
    local DISTRO_LIKE="${TKG_DISTRO_ID_LIKE,,}"
    
    if [[ "${DISTRO_ID}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${DISTRO_LIKE}" == *"arch"* ]]; then
        ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Linux-TKG package for ${TKG_DISTRO_NAME}, this may take a while... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
        makepkg -si || {
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: linux-tkg for ${TKG_DISTRO_NAME}${TKG_RESET}"
            return 1
        }
    else
        ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Linux-TKG for ${TKG_DISTRO_NAME}, this may take a while... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
        chmod +x install.sh 2>/dev/null || true
        ./install.sh install || {
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: linux-tkg for ${TKG_DISTRO_NAME}${TKG_RESET}"
            return 1
        }
    fi
}

# 🖥️ Nvidia-TKG installation
_nvidia_install() {
    cd "$TKG_INSTALLER_DIR" || return 1
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/nvidia-all.git" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error cloning: nvidia-all for ${TKG_DISTRO_NAME}${TKG_RESET}"
        return 1
    }
    
    cd nvidia-all || return 1
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --email --number-of-authors 6 --text-colors 3 15 3 3 15 3 || true
    fi
    
    # Build and install 
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Nvidia-TKG package for ${TKG_DISTRO_NAME}, this may take a while... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
    makepkg -si || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: nvidia-all for ${TKG_DISTRO_NAME}${TKG_RESET}"
        return 1
    }
}

# 🧩 Mesa-TKG installation
_mesa_install() {
    cd "$TKG_INSTALLER_DIR" || return 1
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/mesa-git.git" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error cloning: mesa-git for ${TKG_DISTRO_NAME}${TKG_RESET}"
        return 1
    }
    
    cd mesa-git || return 1
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --email --number-of-authors 6 --text-colors 3 15 3 3 15 3 || true
    fi
    
    # Build and install 
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Mesa-TKG package for ${TKG_DISTRO_NAME}, this may take a while... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
    makepkg -si || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: mesa-tkg for ${TKG_DISTRO_NAME}${TKG_RESET}"
        return 1
    }
}

# 🍷 Wine-TKG installation
_wine_install() {
    cd "$TKG_INSTALLER_DIR" || return 1
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/wine-tkg-git.git" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error cloning: wine-tkg-git for ${TKG_DISTRO_NAME}${TKG_RESET}"
        return 1
    }
    
    cd wine-tkg-git/wine-tkg-git || return 1
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --email --number-of-authors 6 --text-colors 3 15 3 3 15 3 || true
    fi
    
    # Build and install 
    local DISTRO_ID="${TKG_DISTRO_ID,,}"
    local DISTRO_LIKE="${TKG_DISTRO_ID_LIKE,,}"

    if [[ "${DISTRO_ID}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${DISTRO_LIKE}" == *"arch"* ]]; then
        ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Wine-TKG package for ${TKG_DISTRO_NAME}... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
        makepkg -si || {
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: wine-tkg for ${TKG_DISTRO_NAME}${TKG_RESET}"
            return 1
        }
    else
        ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building Wine-TKG for ${TKG_DISTRO_NAME}... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
        chmod +x non-makepkg-build.sh 2>/dev/null || true
        ./non-makepkg-build.sh || {
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: wine-tkg for ${TKG_DISTRO_NAME}${TKG_RESET}"
            return 1
        }
    fi
}

# 🎮 Proton-TKG installation
_proton_install() {
    cd "$TKG_INSTALLER_DIR" || return 1
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/wine-tkg-git.git" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error cloning: wine-tkg-git for ${TKG_DISTRO_NAME}${TKG_RESET}"
        return 1
    }
    
    cd wine-tkg-git/proton-tkg || return 1
    
    # Display repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --email --number-of-authors 6 --text-colors 3 15 3 3 15 3 || true
    fi
    
    # Build Proton-TKG
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Proton-TKG package for ${TKG_DISTRO_NAME}, this may take a while... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
    ./proton-tkg.sh || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: proton-tkg for ${TKG_DISTRO_NAME}${TKG_RESET}"
        return 1
    }
    
    # Clean up build artifacts
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Clean up build artifacts...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    ./proton-tkg.sh clean || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Nothing to clean: proton-tkg${TKG_RESET}"
        return 1
    }
}

# =============================================================================
# EDITOR MANAGEMENT FUNCTION
# =============================================================================

# 📝 Text editor wrapper with fallback support
_editor() {
    local TKG_FILE="$1"

    # Parse $EDITOR variable (may contain arguments)
    local TKG_EDITOR_RAW="${EDITOR-}"
    local TKG_EDITOR_PARTS=()
    IFS=' ' read -r -a TKG_EDITOR_PARTS <<< "$TKG_EDITOR_RAW" || true

    # Fallback to nano if no editor configured or not executable
    if [[ -z "${TKG_EDITOR_PARTS[0]:-}" ]] || ! command -v "${TKG_EDITOR_PARTS[0]}" >/dev/null 2>&1; then
        if command -v nano >/dev/null 2>&1; then
            TKG_EDITOR_PARTS=(nano)
        else
            ${TKG_ECHO} "${TKG_YELLOW} ⚠️ No editor found: please set \$EDITOR environment or install 'nano'.${TKG_RESET}"
            return 1
        fi
    fi

    # Execute the editor with the target TKG_FILE
    "${TKG_EDITOR_PARTS[@]}" "$TKG_FILE"
}

# 🔧 Configuration file editor with interactive menu
_edit_config() {
    while true; do
        local TKG_CONFIG_CHOICE

        # Ensure configuration directory exists
        if [[ ! -d "${TKG_INSTALLER_CONFIG_DIR}" ]]; then
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Configuration directory not found: ${TKG_INSTALLER_CONFIG_DIR}${TKG_RESET}"
            read -r -p "Do you want to create the configuration directory? [y/N]:" create_dir
            case "$create_dir" in
                y|Y|yes)
                    mkdir -p "${TKG_INSTALLER_CONFIG_DIR}" || {
                        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error creating configuration directory!${TKG_RESET}"
                        return 1
                    }
                    ;;
                n|N|no)
                    ${TKG_ECHO} "${TKG_YELLOW} ⚠️ Directory creation cancelled. Returning to menu.${TKG_RESET}"
                    sleep 1
                    return 0
                    ;;
                *)
                    ${TKG_ECHO} "${TKG_YELLOW} ⚠️ Invalid input. Returning to menu.${TKG_RESET}"
                    sleep 1
                    return 0
                    ;;
            esac
        fi

        local menu_content=$'linux-tkg  |🧠 Linux   ─ 📝 linux-tkg.cfg\nnvidia-all |🎮 Nvidia  ─ 📝 nvidia-all.cfg\nmesa-git   |🧩 Mesa    ─ 📝 mesa-git.cfg\nwine-tkg   |🍷 Wine    ─ 📝 wine-tkg.cfg\nproton-tkg |🎮 Proton  ─ 📝 proton-tkg.cfg\nreturn     |⏪ Return'
        local preview_cmd='
            key=$(echo {} | cut -d"|" -f1 | xargs)
            case $key in
                linux-tkg)
                    bat --style=numbers --language=bash --wrap never --highlight-line 1 --force-colorization "'"${TKG_INSTALLER_CONFIG_DIR}/linux-tkg.cfg"'" 2>/dev/null || '"${TKG_ECHO}"' "'"${TKG_RED}${TKG_BOLD} ❌ Error: No external configuration file found${TKG_RESET}"'"
                    ;;
                nvidia-all)
                    bat --style=numbers --language=bash --wrap never --highlight-line 1 --force-colorization "'"${TKG_INSTALLER_CONFIG_DIR}/nvidia-all.cfg"'" 2>/dev/null || '"${TKG_ECHO}"' "'"${TKG_RED}${TKG_BOLD} ❌ Error: No external configuration file found${TKG_RESET}"'"
                    ;;
                mesa-git)
                    bat --style=numbers --language=bash --wrap never --highlight-line 1 --force-colorization "'"${TKG_INSTALLER_CONFIG_DIR}/mesa-git.cfg"'" 2>/dev/null || '"${TKG_ECHO}"' "'"${TKG_RED}${TKG_BOLD} ❌ Error: No external configuration file found${TKG_RESET}"'"
                    ;;
                wine-tkg)
                    bat --style=numbers --language=bash --wrap never --highlight-line 1 --force-colorization "'"${TKG_INSTALLER_CONFIG_DIR}/wine-tkg.cfg"'" 2>/dev/null || '"${TKG_ECHO}"' "'"${TKG_RED}${TKG_BOLD} ❌ Error: No external configuration file found${TKG_RESET}"'"
                    ;;
                proton-tkg)
                    bat --style=numbers --language=bash --wrap never --highlight-line 1 --force-colorization "'"${TKG_INSTALLER_CONFIG_DIR}/proton-tkg.cfg"'" 2>/dev/null || '"${TKG_ECHO}"' "'"${TKG_RED}${TKG_BOLD} ❌ Error: No external configuration file found${TKG_RESET}"'"
                    ;;
                return)
                    '"${TKG_ECHO}"' "'"${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}⏪ Return to Mainmenu - Exit editor menu${TKG_BREAK}${TKG_LINE}${TKG_RESET}"'"
                    ;;
            esac
        '
        local header=$'🐸 TKG-Installer ─ Editor menue\n\n   Edit external configuration file\n   Default directory: ~/.config/frogminer/'
        local footer=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\n🐸 Frogging-Family: https://github.com/Frogging-Family\n🌐 About: https://github.com/damachine/tkginstaller'
        local border_label="${TKG_INSTALLER_VERSION}"
        local preview_window='right:nowrap:70%'

        TKG_CONFIG_CHOICE=$(_fzf_menu "$menu_content" "$preview_cmd" "$header" "$footer" "$border_label" "$preview_window")

        # Handle cancelled selection
        if [[ -z "$TKG_CONFIG_CHOICE" ]]; then
            ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} ⏪ Exit editor menu...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
            sleep 1
            clear
            return 0
        fi
        
        # Extract selected configuration type
        local TKG_CONFIG_FILE
        TKG_CONFIG_FILE=$(echo "$TKG_CONFIG_CHOICE" | cut -d"|" -f1 | xargs)
        
        # Handle configuration file editing
        case $TKG_CONFIG_FILE in
            linux-tkg)
                _handle_confg \
                    "Linux-TKG" \
                    "${TKG_INSTALLER_CONFIG_DIR}/linux-tkg.cfg" \
                    "${FROGGING_FAMILY_RAW}/linux-tkg/master/customization.cfg"
                ;;
            nvidia-all)
                _handle_confg \
                    "Nvidia-TKG" \
                    "${TKG_INSTALLER_CONFIG_DIR}/nvidia-all.cfg" \
                    "${FROGGING_FAMILY_RAW}/nvidia-all/master/customization.cfg"
                ;;
            mesa-git)
                _handle_confg \
                    "Mesa-TKG" \
                    "${TKG_INSTALLER_CONFIG_DIR}/mesa-git.cfg" \
                    "${FROGGING_FAMILY_RAW}/mesa-git/master/customization.cfg"
                ;;
            wine-tkg)
                _handle_confg \
                    "Wine-TKG" \
                    "${TKG_INSTALLER_CONFIG_DIR}/wine-tkg.cfg" \
                    "${FROGGING_FAMILY_RAW}/wine-tkg-git/master/wine-tkg-git/customization.cfg"
                ;;
            proton-tkg)
                _handle_confg \
                    "Proton-TKG" \
                    "${TKG_INSTALLER_CONFIG_DIR}/proton-tkg.cfg" \
                    "${FROGGING_FAMILY_RAW}/wine-tkg-git/master/proton-tkg/proton-tkg.cfg"
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
_handle_confg() {
    local TKG_CONFIG_NAME="$1"
    local TKG_CONFIG_PATCH="$2" 
    local TKG_CONFIG_URL="$3"
    
    ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} 🔧 Opening external $TKG_CONFIG_NAME configuration file...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    sleep 1
    clear
    
    if [[ -f "$TKG_CONFIG_PATCH" ]]; then
        # Edit existing configuration file
        _editor "$TKG_CONFIG_PATCH" || {
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error opening $TKG_CONFIG_PATCH configuration!${TKG_RESET}"
            return 1
        }
    else
        # Download and create new configuration file
        ${TKG_ECHO} "${TKG_YELLOW}${TKG_BOLD} ⚠️ $TKG_CONFIG_PATCH does not exist.${TKG_RESET}"
        read -r -p "Do you want to download the default configuration from $TKG_CONFIG_URL? [y/N]: " answer
        case "$answer" in
            y|Y|yes)
                mkdir -p "$(dirname "$TKG_CONFIG_PATCH")"
                if curl -fsSL "$TKG_CONFIG_URL" -o "$TKG_CONFIG_PATCH" 2>/dev/null; then
                    ${TKG_ECHO} "${TKG_GREEN} ✅ Configuration ready at $TKG_CONFIG_PATCH${TKG_RESET}"
                    _editor "$TKG_CONFIG_PATCH" || {
                        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error opening $TKG_CONFIG_PATCH configuration!${TKG_RESET}"
                        return 1
                    }
                else
                    ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error downloading configuration from $TKG_CONFIG_URL${TKG_RESET}"
                    return 1
                fi
                ;;
            *)
                ${TKG_ECHO} "${TKG_YELLOW} ⚠️ Download cancelled. No configuration file created.${TKG_RESET}"
                return 1
                ;;
        esac
    fi
    
    ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} ✅ Closing external $TKG_CONFIG_NAME configuration file...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
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
    local menu_content=$'Linux  |🧠 Kernel  ─ Linux-TKG custom kernels\nNvidia |🖥️ Nvidia  ─ Nvidia Open-Source or proprietary graphics driver\nMesa   |🧩 Mesa    ─ Open-Source graphics driver for AMD and Intel\nWine   |🍷 Wine    ─ Windows compatibility layer\nProton |🎮 Proton  ─ Windows compatibility layer for Steam / Gaming\nConfig |🛠️ Config  ─ Edit external TKG configuration files\nClean  |🧹 Clean   ─ Clean downloaded files\nHelp   |❓ Help    ─ Shows all commands\nExit   |❌ Exit'
    local preview_cmd='
        key=$(echo {} | cut -d"|" -f1 | xargs)
        case $key in
            Linux*) $TKG_ECHO "$TKG_PREVIEW_LINUX" ;;
            Nvidia*) $TKG_ECHO "$TKG_PREVIEW_NVIDIA" ;;
            Mesa*) $TKG_ECHO "$TKG_PREVIEW_MESA" ;;
            Wine*) $TKG_ECHO "$TKG_PREVIEW_WINE" ;;
            Proton*) $TKG_ECHO "$TKG_PREVIEW_PROTON" ;;
            Config*) $TKG_ECHO "${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🛠️ TKG external configuration files ➡️${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}Edit all external TKG configuration files${TKG_BREAK}📝 Default directory: ~/.config/frogminer/${TKG_BREAK}${TKG_BREAK}See full documentation at:${TKG_BREAK}🌐 ${TKG_INSTALLER_REPO}${TKG_BREAK}🐸 Frogging-Family: ${FROGGING_FAMILY_REPO}" ;;
            Clean*) $TKG_ECHO "${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🧹 TKG-Installer - Cleaning${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}Removes temporary files in ~/.cache/tkginstaller and resets the installer.${TKG_BREAK}${TKG_BREAK}See full documentation at:${TKG_BREAK}🌐 ${TKG_INSTALLER_REPO}" ;;
            Help*) $TKG_ECHO "${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}❓ TKG-Installer - Help${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}Shows all Commandline usage.${TKG_BREAK}${TKG_BREAK}See full documentation at:${TKG_BREAK}🌐 ${TKG_INSTALLER_REPO}${TKG_BREAK}🐸 Frogging-Family: ${FROGGING_FAMILY_REPO}" ;;
            Exit*) $TKG_ECHO "${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}👋 Exit the program and removes temporary files${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}💖 Thank you for using TKG-Installer! 💖${TKG_BREAK}${TKG_BREAK}If you like this program, please support the project on GitHub ⭐ ⭐ ⭐${TKG_BREAK}${TKG_BREAK}🌐 See: ${TKG_INSTALLER_REPO}${TKG_BREAK}🐸 Frogging-Family: ${FROGGING_FAMILY_REPO}" ;;
        esac
    '
    local header=$'🐸 TKG-Installer ─ Select a option\n\n   Manage the popular TKG packages from the Frogging-Family repositories.'
    local footer=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\n🐸 Frogging-Family: https://github.com/Frogging-Family\n🌐 About: https://github.com/damachine/tkginstaller'
    local border_label="${TKG_INSTALLER_VERSION}"
    local preview_window='right:nowrap:60%'

    local TKG_MAIN_CHOICE
    TKG_MAIN_CHOICE=$(_fzf_menu "$menu_content" "$preview_cmd" "$header" "$footer" "$border_label" "$preview_window")

    # Handle cancelled selection (ESC pressed)
    if [[ -z "${TKG_MAIN_CHOICE:-}" ]]; then
        ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} 👋 Exit TKG-Installer...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
        sleep 1
        clear
        _exit 0
    fi

    # Save selection to temporary file for processing
    echo "$TKG_MAIN_CHOICE" | cut -d"|" -f1 | xargs > "$TKG_INSTALLER_CHOICE_FILE"
}

# =============================================================================
# MAIN PROGRAM ENTRY POINT
# =============================================================================

# ▶️ Main function - handles command line arguments and menu interaction
_main() {
    # Handle direct command line arguments for automation
    if [[ $# -gt 0 ]]; then
        case "${1:-}" in
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
            
            help|h)
                # Disable exit trap before cleanup and exit
                trap - INT TERM EXIT HUP
                    
                # Clean exit without triggering _exit cleanup messages. Unset exported all variables
                _clean
                exit 0
                ;;
            *)
                # Invalid argument handling
                ${TKG_ECHO} " "
                ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Unknown argument: ${1:-}${TKG_RESET}"
                ${TKG_ECHO} "${TKG_YELLOW}    Usage:${TKG_RESET} $0 help${TKG_RESET}"
                ${TKG_ECHO} "           $0 [linux|nvidia|mesa|wine|proton]${TKG_BREAK}${TKG_RESET}"
                
                # Disable exit trap before cleanup and exit
                trap - INT TERM EXIT HUP
                
                # Clean exit without triggering _exit cleanup messages. Unset exported all variables
                _clean
                exit 1
                ;;
        esac
    fi

    # Interactive mode - show menu and handle user selection
    _init_preview
    _pre
    clear
    _menu

    # Process user selection from menu
    local TKG_CHOICE
    TKG_CHOICE=$(< "$TKG_INSTALLER_CHOICE_FILE")
    rm -f "$TKG_INSTALLER_CHOICE_FILE"

    case $TKG_CHOICE in
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
            rm -f "$TKG_INSTALLER_LOCKFILE"
            exec "$0"
            ;;
        Help)
            # Display goodbye message and cleanup
            ${TKG_ECHO} "${TKG_GREEN} 💖 Thank you for using TKG-Installer 🌐${TKG_RESET}${TKG_BLUE} ${TKG_INSTALLER_REPO}${TKG_RESET}"
            ${TKG_ECHO} "${TKG_GREEN}                                      🐸${TKG_RESET}${TKG_BLUE} ${FROGGING_FAMILY_REPO}${TKG_RESET}"
            ${TKG_ECHO} "${TKG_GREEN} 🧹 Cleanup completed!${TKG_RESET}"
            ${TKG_ECHO} "${TKG_GREEN} 👋 Closed!${TKG_RESET}"
            ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
            
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
            rm -f "$TKG_INSTALLER_LOCKFILE" 2>&1 || true
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

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Start the main program with all provided arguments
_main "$@"
