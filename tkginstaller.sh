#!/usr/bin/env bash

# TKG-Installer VERSION
readonly TKG_INSTALLER_VERSION="v0.9.5"

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
# 	TKG-Installer 🐸
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

# 🌐 Force standard locale for consistent behavior (sorting, comparisons, messages)
#export LC_ALL=C

# 🔒 Safety settings and strict mode
set -euo pipefail

# 📌 Global paths and configuration
readonly TKG_LOCKFILE="/tmp/tkginstaller.lock"
TKG_INSTALLER_REPO="https://github.com/damachine/tkginstaller"
FROGGING_FAMILY_REPO="https://github.com/Frogging-Family"
FROGGING_FAMILY_RAW="https://raw.githubusercontent.com/Frogging-Family"
TKG_TEMP_DIR="$HOME/.cache/tkginstaller"
TKG_CONFIG_DIR="$HOME/.config/frogminer"

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
export TKG_INSTALLER_REPO FROGGING_FAMILY_REPO FROGGING_FAMILY_RAW TKG_TEMP_DIR TKG_CONFIG_DIR
export TKG_ECHO TKG_BREAK TKG_LINE TKG_RESET TKG_BOLD TKG_RED TKG_GREEN TKG_YELLOW TKG_BLUE

# 🔒 Prevent concurrent execution
if [[ -f "$TKG_LOCKFILE" ]]; then
    ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Script is already running. Exiting...${TKG_RESET}"
    ${TKG_ECHO} "${TKG_YELLOW}${TKG_BOLD} 🔁 If the script was unexpectedly terminated, remove the lock file manually: rm $TKG_LOCKFILE${TKG_RESET}"
    exit 1
fi
touch "$TKG_LOCKFILE"

# 🧑‍💻 Detect Linux Distribution
if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    readonly TKG_DISTRO_NAME="$NAME"
    readonly TKG_DISTRO_ID="${ID:-unknown}"
    readonly TKG_DISTRO_ID_LIKE="${ID_LIKE:-}"
else
    readonly TKG_DISTRO_NAME="Unknown"
    readonly TKG_DISTRO_ID="unknown"
    readonly TKG_DISTRO_ID_LIKE=""
fi

# =============================================================================
# CORE UTILITY FUNCTIONS
# =============================================================================

# 🧹 Cleanup handler for graceful exit
_exit() {
    local code=$?
    trap - INT TERM EXIT HUP
    
    # Message handling
    if [[ $code -ne 0 ]]; then
        # Show abort message on error FIRST
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} 🎯 ERROR 🎯 TKG-Installer aborted! Exiting...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
        ${TKG_ECHO} " "
    else
        # Final cleanup message
        ${TKG_ECHO} "${TKG_GREEN} 💖 Thank you for using TKG-Installer 🌐${TKG_RESET}${TKG_BLUE} ${TKG_INSTALLER_REPO}${TKG_RESET}"
        ${TKG_ECHO} "${TKG_GREEN}                                      🐸${TKG_RESET}${TKG_BLUE} ${FROGGING_FAMILY_REPO}${TKG_RESET}"
        ${TKG_ECHO} "${TKG_GREEN} 🧹 Cleanup completed!${TKG_RESET}"
        ${TKG_ECHO} "${TKG_GREEN} 👋 Closed!${TKG_RESET}"
        ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
    fi
    
    # Remove TKG_LOCKFILE
    rm -f "$TKG_LOCKFILE" 2>/dev/null || true

    # Remove temporary choice file
    rm -rf /tmp/tkginstaller.choice 2>/dev/null || true

    # Clean temporary files
    rm -rf "$TKG_TEMP_DIR" 2>/dev/null || true

    # Unset exported all variables
    unset TKG_INSTALLER_REPO FROGGING_FAMILY_REPO FROGGING_FAMILY_RAW TKG_TEMP_DIR TKG_CONFIG_DIR TKG_ECHO TKG_BREAK TKG_LINE TKG_RESET TKG_BOLD TKG_RED TKG_GREEN TKG_YELLOW TKG_BLUE TKG_PREVIEW_LINUX TKG_PREVIEW_NVIDIA TKG_PREVIEW_MESA TKG_PREVIEW_WINE TKG_PREVIEW_PROTON 

    # Exit with original exit code
    wait
    exit $code
}
# Setup exit trap for cleanup on script termination
trap _exit INT TERM EXIT HUP

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

    # Check for root execution
    if [[ "$(id -u)" -eq 0 ]]; then
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Do not run as root!${TKG_RESET}"
        exit 1
    fi

    # Check required dependencies
    local TKG_DEPENDENCIES=(fzf bat curl fmt git)
    for TKG_REQUIRED in "${TKG_DEPENDENCIES[@]}"; do
        if ! command -v "$TKG_REQUIRED" >/dev/null; then
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ $TKG_REQUIRED is not installed! Please install it first.${TKG_RESET}"
            ${TKG_ECHO} "${TKG_YELLOW}${TKG_BOLD} 🔁 Run: pacman -S ${TKG_REQUIRED}${TKG_RESET}"            
            exit 1
        fi
    done

    # Setup temporary directory
    ${TKG_ECHO} "${TKG_YELLOW} 🧹 Cleaning old temporary files...${TKG_RESET}"
    rm -rf "$TKG_TEMP_DIR" /tmp/tkginstaller.choice 2>/dev/null || true
    ${TKG_ECHO} "${TKG_YELLOW} 🗂️ Create temporary directory...${TKG_RESET}"
    mkdir -p "$TKG_TEMP_DIR" 2>/dev/null || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error creating temporary directory: ${TKG_TEMP_DIR}${TKG_RESET}"
        return 1
    }

    # Message for preview section
    ${TKG_ECHO} "${TKG_YELLOW} 📡 Retrieving content...${TKG_RESET}"

    # Final message
    ${TKG_ECHO} "${TKG_GREEN} 🐸 Starting...${TKG_RESET}"
    sleep 2
}

# ❓ Help information display
_help() {
    ${TKG_ECHO} " "
    ${TKG_ECHO} "${TKG_GREEN} Interactive:${TKG_RESET} $0"
    ${TKG_ECHO} "${TKG_GREEN} Commandline:${TKG_RESET} $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p|linuxnvidia|ln|combo]"
    ${TKG_ECHO} "${TKG_GREEN} Shortcuts:${TKG_RESET} l=linux, n=nvidia, m=mesa, w=wine, p=proton, ln/combo=combo"
    ${TKG_ECHO} " "
    ${TKG_ECHO} "${TKG_GREEN} Example:${TKG_RESET} Run commandline mode directly without menu"
    ${TKG_ECHO} "         $0 linux         # Install Linux-TKG${TKG_RESET}"
    ${TKG_ECHO} "         $0 nvidia        # Install Nvidia-TKG${TKG_RESET}"
    ${TKG_ECHO} "         $0 mesa          # Install Mesa-TKG${TKG_RESET}"
    ${TKG_ECHO} "         $0 wine          # Install Wine-TKG${TKG_RESET}"
    ${TKG_ECHO} "         $0 proton        # Install Proton-TKG${TKG_RESET}"
    ${TKG_ECHO} "         $0 combo         # Install Linux-TKG + Nvidia-TKG${TKG_RESET}"
    ${TKG_ECHO} " "

    # Disable exit trap before cleanup and exit
    trap - INT TERM EXIT HUP
    
    # Clean exit without triggering _exit cleanup messages
    rm -f "$TKG_LOCKFILE" 2>/dev/null || true
    rm -rf /tmp/tkginstaller.choice "${TKG_TEMP_DIR}" 2>/dev/null || true
    unset TKG_PREVIEW_LINUX TKG_PREVIEW_NVIDIA TKG_PREVIEW_MESA TKG_PREVIEW_WINE TKG_PREVIEW_PROTON TKG_ECHO TKG_BREAK TKG_LINE TKG_RESET TKG_BOLD TKG_RED TKG_GREEN TKG_YELLOW TKG_BLUE FROGGING_FAMILY_REPO FROGGING_FAMILY_RAW TKG_TEMP_DIR TKG_CONFIG_DIR 2>/dev/null || true
    
    exit 0
}

# 📝 Dynamic preview content generator for fzf menus
_get_preview() {
    local TKG_PREVIEW_CHOICE="$1"
    local TKG_PREVIEW_URL=""
    local TKG_PREVIEW_STATIC=""
    
    # Define repository URLs and static previews for each TKG package
    case "$TKG_PREVIEW_CHOICE" in
        linux)
            TKG_PREVIEW_URL="${FROGGING_FAMILY_RAW}/linux-tkg/refs/heads/master/README.md"
            TKG_PREVIEW_STATIC="Note:${TKG_BREAK}- Use the configuration editor to customize build options.${TKG_BREAK}- Ensure you have the necessary build TKG_DEPENDENCIES installed.${TKG_BREAK}- The installer will clone the repository, build the kernel, and install it.${TKG_BREAK}- After installation, reboot to use the new kernel.${TKG_BREAK}${TKG_BREAK}Tips:${TKG_BREAK}- Run 'tkginstaller linux' to skip menu${TKG_BREAK}- Join the Frogging-Family community for support and updates.${TKG_BREAK}${TKG_BREAK}${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🧠 Online Preview${TKG_BREAK}${TKG_BREAK} - See full documentation at:${TKG_BREAK} - ${FROGGING_FAMILY_REPO}/linux-tkg/blob/master/README.md${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
            ;;
        nvidia)
            TKG_PREVIEW_URL="${FROGGING_FAMILY_RAW}/nvidia-all/refs/heads/master/README.md"
            TKG_PREVIEW_STATIC="Note:${TKG_BREAK}- Supports both open-source and proprietary Nvidia drivers.${TKG_BREAK}- Use the configuration editor to set driver options and patches.${TKG_BREAK}- Installer will clone the repo, build and install the driver.${TKG_BREAK}- Reboot after installation for changes to take effect.${TKG_BREAK}${TKG_BREAK}Tips:${TKG_BREAK}- Run 'tkginstaller nvidia' to skip menu${TKG_BREAK}- Check compatibility with your GPU model.${TKG_BREAK}- Join the Frogging-Family community for troubleshooting.${TKG_BREAK}${TKG_BREAK}${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🖥️ Online Preview${TKG_BREAK}${TKG_BREAK} - See full documentation at:${TKG_BREAK} - ${FROGGING_FAMILY_REPO}/nvidia-all/blob/master/README.md${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
            ;;
        mesa)
            TKG_PREVIEW_URL="${FROGGING_FAMILY_RAW}/mesa-git/refs/heads/master/README.md"
            TKG_PREVIEW_STATIC="Note:${TKG_BREAK}- Open-source graphics drivers for AMD and Intel GPUs.${TKG_BREAK}- Use the configuration editor for custom build flags.${TKG_BREAK}- Installer will clone, build, and install Mesa.${TKG_BREAK}- Reboot or restart X for changes to apply.${TKG_BREAK}${TKG_BREAK}Tips:${TKG_BREAK}- Run 'tkginstaller mesa' to skip menu${TKG_BREAK}- Useful for gaming and Vulkan support.${TKG_BREAK}- Join the Frogging-Family community for updates.${TKG_BREAK}${TKG_BREAK}${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🧩 Online Preview${TKG_BREAK}${TKG_BREAK} - See full documentation at:${TKG_BREAK} - ${FROGGING_FAMILY_REPO}/mesa-git/blob/master/README.md${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
            ;;
        wine)
            TKG_PREVIEW_URL="${FROGGING_FAMILY_RAW}/wine-tkg-git/refs/heads/master/wine-tkg-git/README.md"
            TKG_PREVIEW_STATIC="Note:${TKG_BREAK}- Custom Wine builds for better compatibility and gaming performance.${TKG_BREAK}- Use the configuration editor for patches and tweaks.${TKG_BREAK}- Installer will clone, build, and install Wine-TKG.${TKG_BREAK}- Configure your prefix after installation.${TKG_BREAK}${TKG_BREAK}Tips:${TKG_BREAK}- Run 'tkginstaller wine' to skip menu${TKG_BREAK}- Ideal for running Windows games and apps.${TKG_BREAK}- Join the Frogging-Family community for support.${TKG_BREAK}${TKG_BREAK}${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🍷 Online Preview${TKG_BREAK}${TKG_BREAK} - See full documentation at:${TKG_BREAK} - ${FROGGING_FAMILY_REPO}/wine-tkg-git/blob/master/README.md${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
            ;;
        proton)
            TKG_PREVIEW_URL="${FROGGING_FAMILY_RAW}/wine-tkg-git/refs/heads/master/proton-tkg/README.md"
            TKG_PREVIEW_STATIC="Note:${TKG_BREAK}- Custom Proton builds for Steam Play and gaming.${TKG_BREAK}- Use the configuration editor for tweaks and patches.${TKG_BREAK}- Installer will clone, build, and install Proton-TKG.${TKG_BREAK}- Select Proton-TKG in Steam after installation.${TKG_BREAK}${TKG_BREAK}Tips:${TKG_BREAK}- Run 'tkginstaller proton' to skip menu${TKG_BREAK}- Great for running Windows games via Steam.${TKG_BREAK}- Join the Frogging-Family community for updates.${TKG_BREAK}${TKG_BREAK}${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🎮 Online Preview${TKG_BREAK}${TKG_BREAK} - See full documentation at:${TKG_BREAK} - ${FROGGING_FAMILY_REPO}/wine-tkg-git/blob/master/proton-tkg/README.md${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
            ;;
    esac

    # Always show static preview first
    ${TKG_ECHO} "$TKG_PREVIEW_STATIC"
       
   # Display remote content with available tools (bat > plain text)
    if [[ -n "$TKG_PREVIEW_URL" ]]; then
        # Download content
        local content=""
        if command -v curl >/dev/null 2>&1; then
            content=$(curl -fsSL --max-time 5 "${TKG_PREVIEW_URL}" 2>/dev/null)
        fi

        # View content with fallback to static preview
        if [[ -n "$content" ]]; then
            if command -v bat >/dev/null 2>&1; then
                ${TKG_ECHO} " "
                ${TKG_ECHO} "$content" | fmt -w 99 | bat --style=plain --paging=never --language=md --wrap never --highlight-line 1 --force-colorization 2>/dev/null
            else
                ${TKG_ECHO} " "
                ${TKG_ECHO} "$content"
            fi
        fi
    fi
}

# 📝 Preview content is initialized only for interactive mode
_init_preview() {
    # shellcheck disable=SC2218  # Function is defined earlier
    TKG_PREVIEW_LINUX="$(_get_preview linux)"
    # shellcheck disable=SC2218  # Function is defined earlier
    TKG_PREVIEW_NVIDIA="$(_get_preview nvidia)"
    # shellcheck disable=SC2218  # Function is defined earlier
    TKG_PREVIEW_MESA="$(_get_preview mesa)"
    # shellcheck disable=SC2218  # Function is defined earlier
    TKG_PREVIEW_WINE="$(_get_preview wine)"
    TKG_PREVIEW_PROTON="$(_get_preview proton)"
    export TKG_PREVIEW_LINUX TKG_PREVIEW_NVIDIA TKG_PREVIEW_MESA TKG_PREVIEW_WINE TKG_PREVIEW_PROTON
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# 🧠 Linux-TKG installation
_linux_install() {
    cd "$TKG_TEMP_DIR"
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/linux-tkg.git" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error cloning: linux-tkg for $TKG_DISTRO_NAME${TKG_RESET}"
        return 1
    }
    
    cd linux-tkg
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --number-of-authors 6
    fi
    
    # Build and install based on distribution
    local DISTRO_ID="${TKG_DISTRO_ID,,}"
    local DISTRO_LIKE="${TKG_DISTRO_ID_LIKE,,}"
    
    if [[ "${DISTRO_ID}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${DISTRO_LIKE}" == *"arch"* ]]; then
        ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Linux-TKG package for $TKG_DISTRO_NAME, this may take a while... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
        makepkg -si || {
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: linux-tkg for $TKG_DISTRO_NAME${TKG_RESET}"
            return 1
        }
    else
        ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Linux-TKG for $TKG_DISTRO_NAME, this may take a while... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
        chmod +x install.sh 2>/dev/null || true
        ./install.sh install || {
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: linux-tkg for $TKG_DISTRO_NAME${TKG_RESET}"
            return 1
        }
    fi
}

# 🖥️ Nvidia-TKG installation
_nvidia_install() {
    cd "$TKG_TEMP_DIR"
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/nvidia-all.git" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error cloning: nvidia-all for $TKG_DISTRO_NAME${TKG_RESET}"
        return 1
    }
    
    cd nvidia-all
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --number-of-authors 6
    fi
    
    # Build and install 
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Nvidia-TKG package for $TKG_DISTRO_NAME, this may take a while... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
    makepkg -si || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: nvidia-all for $TKG_DISTRO_NAME${TKG_RESET}"
        return 1
    }
}

# 🧩 Mesa-TKG installation
_mesa_install() {
    cd "$TKG_TEMP_DIR"
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/mesa-git.git" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error cloning: mesa-git for $TKG_DISTRO_NAME${TKG_RESET}"
        return 1
    }
    
    cd mesa-git
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --number-of-authors 6
    fi
    
    # Build and install 
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Mesa-TKG package for $TKG_DISTRO_NAME, this may take a while... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
    makepkg -si || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: mesa-tkg for $TKG_DISTRO_NAME${TKG_RESET}"
        return 1
    }
}

# 🍷 Wine-TKG installation
_wine_install() {
    cd "$TKG_TEMP_DIR"
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/wine-tkg-git.git" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error cloning: wine-tkg-git for $TKG_DISTRO_NAME${TKG_RESET}"
        return 1
    }
    
    cd wine-tkg-git/wine-tkg-git
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --number-of-authors 6
    fi
    
    # Build and install 
    local DISTRO_ID="${TKG_DISTRO_ID,,}"
    local DISTRO_LIKE="${TKG_DISTRO_ID_LIKE,,}"

    if [[ "${DISTRO_ID}" =~ ^(arch|cachyos|manjaro|endeavo1uros)$ || "${DISTRO_LIKE}" == *"arch"* ]]; then
        ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Wine-TKG package for $TKG_DISTRO_NAME... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
        makepkg -si || {
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: wine-tkg for $TKG_DISTRO_NAME${TKG_RESET}"
            return 1
        }
    else
        ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building Wine-TKG for $TKG_DISTRO_NAME... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
        chmod +x non-makepkg-build.sh 2>/dev/null || true
        ./non-makepkg-build.sh || {
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: wine-tkg for $TKG_DISTRO_NAME${TKG_RESET}"
            return 1
        }
    fi
}

# 🎮 Proton-TKG installation
_proton_install() {
    cd "$TKG_TEMP_DIR"
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/wine-tkg-git.git" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error cloning: wine-tkg-git for $TKG_DISTRO_NAME${TKG_RESET}"
        return 1
    }
    
    cd wine-tkg-git/proton-tkg
    
    # Display repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --number-of-authors 6
    fi
    
    # Build Proton-TKG
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Proton-TKG package for $TKG_DISTRO_NAME, this may take a while... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust external configuration file to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
    ./proton-tkg.sh || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: proton-tkg for $TKG_DISTRO_NAME${TKG_RESET}"
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
        if [[ ! -d "${TKG_CONFIG_DIR}" ]]; then
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Configuration directory not found: ${TKG_CONFIG_DIR}${TKG_RESET}"
            read -r -p "Do you want to create the configuration directory? [y/N]:" create_dir
            case "$create_dir" in
                y|Y|yes)
                    mkdir -p "${TKG_CONFIG_DIR}" || {
                        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error creating configuration directory!${TKG_RESET}"
                        return 1
                    }
                    ;;
                n|N|no)
                    ${TKG_ECHO} "${TKG_YELLOW} ⚠️ Directory creation cancelled. Returning to menu.${TKG_RESET}"
                    return 0
                    ;;
                *)
                    ${TKG_ECHO} "${TKG_YELLOW} ⚠️ Invalid input. Returning to menu.${TKG_RESET}"
                    return 0
                    ;;
            esac
        fi
        
        # Interactive configuration file selection with preview
        # shellcheck disable=SC2016  # allow fzf to expand variables in its own shell at runtime
        TKG_CONFIG_CHOICE=$(
            fzf \
                --with-shell='bash -c' \
                --style full:thinblock \
                --border=none \
                --layout=reverse \
                --highlight-line \
                --height='-1' \
                --ansi \
                --delimiter='|' \
                --with-nth='2' \
                --no-extended \
                --no-input \
                --no-multi \
                --no-multi-line \
                --header=$'🐸 TKG-Installer ─ Editor menue\n🛠️ Edit external configuration file\n📝 Default directory: ~/.config/frogminer/' \
                --header-border=thinblock \
                --header-label="${TKG_INSTALLER_VERSION}" \
                --header-label-pos=2 \
                --header-first \
                --footer=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\nℹ️ Usage: Editor nano is fallback if environment $EDITOR is not set\n🌐 See: https://wiki.archlinux.org/title/Environment_variables' \
                --footer-border=thinblock \
                --preview="
                    key=\$(echo {} | cut -d'|' -f1 | xargs)
                    case \$key in
                        linux-tkg)
                            bat --style=numbers --paging=never --language=bash --wrap never --highlight-line 1 --force-colorization \"${TKG_CONFIG_DIR}/linux-tkg.cfg\" 2>/dev/null || ${TKG_ECHO} \"${TKG_RED}${TKG_BOLD} ❌ Error: No external configuration file found${TKG_RESET}\" ;;
                        nvidia-all)
                            bat --style=numbers --paging=never --language=bash --wrap never --highlight-line 1 --force-colorization \"${TKG_CONFIG_DIR}/nvidia-all.cfg\" 2>/dev/null || ${TKG_ECHO} \"${TKG_RED}${TKG_BOLD} ❌ Error: No external configuration file found${TKG_RESET}\" ;;
                        mesa-git)
                            bat --style=numbers --paging=never --language=bash --wrap never --highlight-line 1 --force-colorization \"${TKG_CONFIG_DIR}/mesa-git.cfg\" 2>/dev/null || ${TKG_ECHO} \"${TKG_RED}${TKG_BOLD} ❌ Error: No external configuration file found${TKG_RESET}\" ;;
                        wine-tkg)
                            bat --style=numbers --paging=never --language=bash --wrap never --highlight-line 1 --force-colorization \"${TKG_CONFIG_DIR}/wine-tkg.cfg\" 2>/dev/null || ${TKG_ECHO} \"${TKG_RED}${TKG_BOLD} ❌ Error: No external configuration file found${TKG_RESET}\" ;;
                        proton-tkg)
                            bat --style=numbers --paging=never --language=bash --wrap never --highlight-line 1 --force-colorization \"${TKG_CONFIG_DIR}/proton-tkg.cfg\" 2>/dev/null || ${TKG_ECHO} \"${TKG_RED}${TKG_BOLD} ❌ Error: No external configuration file found${TKG_RESET}\" ;;
                        return)
                            ${TKG_ECHO} \"${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}⏪ Return to Mainmenu - Exit editor menu${TKG_BREAK}${TKG_LINE}${TKG_RESET}\" ;;
                    esac" \
                --preview-label='🐸 🐸 🐸 🐸 🐸 🐸 🐸 🐸 🐸 🐸' \
                --preview-window='right:nowrap:60%' \
                --preview-border=thinblock \
                --pointer='🐸' \
                --disabled \
                --color='header:green,pointer:green,marker:green' <<'MENU'
linux-tkg  |🧠 Linux   ─ 📝: ~/.config/frogminer/linux-tkg.cfg
nvidia-all |🎮 Nvidia  ─ ➡️                      nvidia-all.cfg
mesa-git   |🧩 Mesa    ─ ➡️                      mesa-git.cfg
wine-tkg   |🍷 Wine    ─ ➡️                      wine-tkg.cfg
proton-tkg |🎮 Proton  ─ ➡️                      proton-tkg.cfg
return     |⏪ Return
MENU
        )
        
        # Handle cancelled selection
        if [[ -z "$TKG_CONFIG_CHOICE" ]]; then
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Selection cancelled.${TKG_RESET}"
            return 1
        fi
        
        # Extract selected configuration type
        local TKG_CONFIG_FILE
        TKG_CONFIG_FILE=$(echo "$TKG_CONFIG_CHOICE" | cut -d"|" -f1 | xargs)
        
        # Handle configuration file editing
        case $TKG_CONFIG_FILE in
            linux-tkg)
                _handle_confg \
                    "Linux-TKG" \
                    "${TKG_CONFIG_DIR}/linux-tkg.cfg" \
                    "${FROGGING_FAMILY_RAW}/linux-tkg/master/customization.cfg"
                ;;
            nvidia-all)
                _handle_confg \
                    "Nvidia-TKG" \
                    "${TKG_CONFIG_DIR}/nvidia-all.cfg" \
                    "${FROGGING_FAMILY_RAW}/nvidia-all/master/customization.cfg"
                ;;
            mesa-git)
                _handle_confg \
                    "Mesa-TKG" \
                    "${TKG_CONFIG_DIR}/mesa-git.cfg" \
                    "${FROGGING_FAMILY_RAW}/mesa-git/master/customization.cfg"
                ;;
            wine-tkg)
                _handle_confg \
                    "Wine-TKG" \
                    "${TKG_CONFIG_DIR}/wine-tkg.cfg" \
                    "${FROGGING_FAMILY_RAW}/wine-tkg-git/master/wine-tkg-git/customization.cfg"
                ;;
            proton-tkg)
                _handle_confg \
                    "Proton-TKG" \
                    "${TKG_CONFIG_DIR}/proton-tkg.cfg" \
                    "${FROGGING_FAMILY_RAW}/wine-tkg-git/master/proton-tkg/proton-tkg.cfg"
                ;;
            return)
                ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} 👋 Exit editor menu...${TKG_BREAK} ⏪ Return to Mainmenu${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
                sleep 2
                clear
                return 0
                ;;
            *)          
                ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Invalid option: $TKG_CONFIG_FILE${TKG_RESET}"
                ;;
        esac
    done
}

# 📝 Helper function to handle individual config file editing
_handle_confg() {
    local TKG_CONFIG_NAME="$1"
    local TKG_CONFIG_PATCH="$2" 
    local TKG_CONFIG_URL="$3"
    
    ${TKG_ECHO} "${TKG_BLUE} 🔧 Opening external $TKG_CONFIG_NAME configuration...${TKG_RESET}"
    
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

    ${TKG_ECHO} "${TKG_GREEN} ✅ Configuration closed!${TKG_RESET}"
    sleep 2
    clear
    return 0
}

# =============================================================================
# PROMT MENUE FUNCTIONS
# =============================================================================

# 📋 Combined Linux + Nvidia installation
_linuxnvidia_prompt() {
    SECONDS=0
    _linux_prompt
    _nvidia_prompt
}

# 🧠 Linux-TKG installation prompt
_linux_prompt() {
    SECONDS=0
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🧠 Fetching Linux-TKG from Frogging-Family repository... ⏳${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    _linux_install
    _done
}

# 🖥️ Nvidia-TKG installation prompt
_nvidia_prompt() {
    SECONDS=0
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🖥️ Fetching Nvidia-TKG from Frogging-Family repository... ⏳${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    _nvidia_install
    _done
}

# 🧩 Mesa-TKG installation prompt
_mesa_prompt() {
    SECONDS=0
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🧩 Fetching Mesa-TKG from Frogging-Family repository... ⏳${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    _mesa_install
    _done
}

# 🍷 Wine-TKG installation prompt
_wine_prompt() {
    SECONDS=0
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🍷 Fetching Wine-TKG from Frogging-Family repository... ⏳${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    _wine_install
    _done
}

# 🎮 Proton-TKG installation prompt
_proton_prompt() {
    SECONDS=0
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🎮 Fetching Proton-TKG from Frogging-Family repository... ⏳${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    _proton_install
    _done
}

# 🛠️ Configuration editor prompt
_config_prompt() {
    if _edit_config; then 
        return 0
    fi
}

# =============================================================================
# FZF MAINMENUE FUNCTIONS
# =============================================================================

# 🎛️ Interactive main menu with fzf preview
_menu() {
    local selection
    
    # shellcheck disable=SC2016  # allow fzf to expand variables in its own shell at runtime
    selection=$(
        fzf \
            --with-shell='bash -c' \
            --style full:thinblock \
            --border=none \
            --layout=reverse \
            --highlight-line \
            --height='-1' \
            --delimiter='|' \
            --with-nth='2' \
            --no-extended \
            --no-input \
            --no-multi \
            --no-multi-line \
            --header='🐸 🐸 🐸 TKG-Installer ── Select a package 🐸 🐸 🐸' \
            --header-border=thinblock \
            --header-label="${TKG_INSTALLER_VERSION}" \
            --header-label-pos=2 \
            --header-first \
            --footer=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\n🐸 Frogging-Family: https://github.com/Frogging-Family\n🌐 About: https://github.com/damachine/tkginstaller' \
            --footer-border=thinblock \
            --preview='case {} in \
                Linux*)
                    ${TKG_ECHO} "${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🧠 Linux-TKG ─ Custom Linux kernels${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}$TKG_PREVIEW_LINUX";; \
                Nvidia*)
                    ${TKG_ECHO} "${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🖥️ Nvidia-TKG ─ Open-Source or proprietary graphics driver${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}$TKG_PREVIEW_NVIDIA";; \
                Combo*)
                    ${TKG_ECHO} "${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🧬 Combo package: 🟥🟦Linux-TKG ✚ 🟩Nvidia-TKG${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}$TKG_PREVIEW_LINUX${TKG_BREAK}${TKG_BREAK}$TKG_PREVIEW_NVIDIA";; \
                Mesa*)
                    ${TKG_ECHO} "${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🧩 Mesa-TKG ─ Open-Source graphics driver for AMD and Intel${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}$TKG_PREVIEW_MESA";; \
                Wine*)
                    ${TKG_ECHO} "${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🍷 Wine-TKG ─ Windows compatibility layer${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}$TKG_PREVIEW_WINE";; \
                Proton*)
                    ${TKG_ECHO} "${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🎮 Proton-TKG ─ Windows compatibility layer for Steam / Gaming${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}$TKG_PREVIEW_PROTON";; \
                Config*)
                    ${TKG_ECHO} "${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🛠️ TKG external configuration files ➡️${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}Edit all external TKG configuration files${TKG_BREAK}📝 Default directory: ~/.config/frogminer/${TKG_BREAK}${TKG_BREAK}See full documentation at:${TKG_BREAK}🌐 ${TKG_INSTALLER_REPO}${TKG_BREAK}🐸 Frogging-Family: ${FROGGING_FAMILY_REPO}";; \
                Clean*)
                    ${TKG_ECHO} "${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🧹 TKG-Installer - Cleaning${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}Removes temporary files in ~/.cache/tkginstaller and resets the installer.${TKG_BREAK}${TKG_BREAK}See full documentation at:${TKG_BREAK}🌐 ${TKG_INSTALLER_REPO}";; \
                Help*)
                    ${TKG_ECHO} "${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}❓ TKG-Installer - Help${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}Shows all Commandline usage.${TKG_BREAK}${TKG_BREAK}See full documentation at:${TKG_BREAK}🌐 ${TKG_INSTALLER_REPO}${TKG_BREAK}🐸 Frogging-Family: ${FROGGING_FAMILY_REPO}";; \
                Exit*)
                    ${TKG_ECHO} "${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}👋 Exit the program and removes temporary files${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}💖 Thank you for using TKG-Installer! 💖${TKG_BREAK}${TKG_BREAK}If you like this program, please support the project on GitHub ⭐ ⭐ ⭐${TKG_BREAK}${TKG_BREAK}🌐 See: ${TKG_INSTALLER_REPO}${TKG_BREAK}🐸 Frogging-Family: ${FROGGING_FAMILY_REPO}";; \
                esac' \
            --preview-label='🐸 🐸 🐸 🐸 🐸 🐸 🐸 🐸 🐸 🐸' \
            --preview-window='right:nowrap:60%' \
            --preview-border=thinblock \
            --pointer='🐸' \
            --disabled \
            --color='header:green,pointer:green,marker:green'\ <<'MENU'
Linux  |🧠 Kernel    ─ Linux-TKG custom kernels
Nvidia |🖥️ Nvidia    ─ Nvidia Open-Source or proprietary graphics driver
Combo  |🧬 Combo➕   ─ Combo package: 🟥🟦Linux-TKG ✚ 🟩Nvidia-TKG
Mesa   |🧩 Mesa      ─ Open-Source graphics driver for AMD and Intel
Wine   |🍷 Wine      ─ Windows compatibility layer
Proton |🎮 Proton    ─ Windows compatibility layer for Steam / Gaming
Config |🛠️ Config➡️  ─ Sub-menu:➡️ Edit external TKG configuration files
Clean  |🧹 Clean     ─ Clean downloaded files
Help   |❓ Help      ─ Shows all commands
Exit   |❌ Exit
MENU
)

    # Handle cancelled selection (ESC pressed)
    if [[ -z "$selection" ]]; then
        ${TKG_ECHO} " ${TKG_RED}${TKG_BOLD}❌ Selection cancelled.${TKG_RESET}"
        _exit
    fi

    # Save selection to temporary file for processing
    echo "$selection" | cut -d"|" -f1 | xargs > /tmp/tkginstaller.choice
}

# =============================================================================
# MAIN PROGRAM ENTRY POINT
# =============================================================================

# ▶️ Main function - handles command line arguments and menu interaction
_main() {
    # Handle direct command line arguments for automation
    if [[ $# -gt 0 ]]; then
        case "${1:-}" in
            linuxnvidia|ln|combo)
                _pre
                _linuxnvidia_prompt
                exit 0
                ;;
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
            help|-h|--help)
                # shellcheck disable=SC2218  # Function is defined earlier
                _help
                ;;
            *)
                ${TKG_ECHO} " "
                ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Unknown argument: ${1:-}${TKG_RESET}"
                ${TKG_ECHO} "${TKG_GREEN} Usage:${TKG_RESET} $0 help${TKG_RESET}"
                ${TKG_ECHO} "        $0 [linux|nvidia|mesa|wine|proton]${TKG_RESET}"
                ${TKG_ECHO} " "
                
                # Disable exit trap before cleanup and exit
                trap - INT TERM EXIT HUP
                
                # Clean exit without triggering _exit cleanup messages
                rm -f "$TKG_LOCKFILE" 2>/dev/null || true
                rm -rf /tmp/tkginstaller.choice "$TKG_TEMP_DIR" 2>/dev/null || true
                unset TKG_PREVIEW_LINUX TKG_PREVIEW_NVIDIA TKG_PREVIEW_MESA TKG_PREVIEW_WINE TKG_PREVIEW_PROTON TKG_ECHO TKG_BREAK TKG_LINE TKG_RESET TKG_BOLD TKG_RED TKG_GREEN TKG_YELLOW TKG_BLUE FROGGING_FAMILY_REPO FROGGING_FAMILY_RAW TKG_TEMP_DIR TKG_CONFIG_DIR 2>/dev/null || true
                
                exit 1
                ;;
        esac
    fi

    # Interactive mode - show menu and handle user selection
    # shellcheck disable=SC2218  # Function is defined earlier
    _init_preview
    # shellcheck disable=SC2218  # Function is defined earlier
    _pre
    clear
    # shellcheck disable=SC2218  # fzf is not a regular command
    _menu

    # Process user selection from menu
    local TKG_CHOICE
    TKG_CHOICE=$(< /tmp/tkginstaller.choice)
    rm -f /tmp/tkginstaller.choice

    case $TKG_CHOICE in
        Combo)
            _linuxnvidia_prompt
            ;;
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
            if _config_prompt; then
                rm -f "$TKG_LOCKFILE"
                exec "$0"
            fi 
            ;;
        Help)
            _help
            ;;
        Clean)
            ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} 🔁 Restarting...${TKG_BREAK} 🧹 Cleaning temporary files...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"      
            _pre >/dev/null 2>&1 || true
            rm -f "$TKG_LOCKFILE"
            sleep 2
            clear
            exec "$0" 
            ;;
        Exit)
            _exit
            ;;
        *)
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Invalid option: $TKG_CHOICE${TKG_RESET}"
            ;;
    esac
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Start the main program with all provided arguments
_main "$@"
