#!/usr/bin/env bash

# TKG-Installer VERSION
readonly VERSION="v0.8.4"

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

# 📝 Export variables for fzf subshells (unset _on_exit run)
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
    readonly DISTRO_NAME="$NAME"
    readonly DISTRO_ID="${ID:-unknown}"
    readonly DISTRO_ID_LIKE="${ID_LIKE:-}"
else
    readonly DISTRO_NAME="Unknown"
    readonly DISTRO_ID="unknown"
    readonly DISTRO_ID_LIKE=""
fi

# =============================================================================
# CORE UTILITY FUNCTIONS
# =============================================================================

# 🧹 Cleanup handler for graceful exit
_on_exit() {
    local code=$?
    trap - INT TERM EXIT HUP
    
    # Message handling
    if [[ $code -ne 0 ]]; then
        # Show abort message on error FIRST
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD}${TKG_LINE}${TKG_BREAK} 🎯 ERROR 🎯 TKG-Installer aborted! Exiting...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    else
        # Final cleanup message
        ${TKG_ECHO} "${TKG_GREEN} 💖 Thank you for using TKG-Installer 🌐 ${TKG_INSTALLER_REPO}${TKG_RESET}"
        ${TKG_ECHO} "${TKG_GREEN}                                      🐸 ${FROGGING_FAMILY_REPO}${TKG_RESET}"
        ${TKG_ECHO} "${TKG_GREEN} 🧹 Cleanup completed${TKG_RESET}"
        ${TKG_ECHO} "${TKG_GREEN} 👋 Closed!${TKG_RESET}"
        ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK}${TKG_RESET}"
    fi
    
    # Remove TKG_LOCKFILE
    rm -f "$TKG_LOCKFILE" 2>/dev/null || true

    # Clean temporary files
    rm -rf /tmp/tkginstaller.choice "$TKG_TEMP_DIR" 2>/dev/null || true

    # Unset exported all variables
    unset TKG_INSTALLER_REPO FROGGING_FAMILY_REPO FROGGING_FAMILY_RAW TKG_TEMP_DIR TKG_CONFIG_DIR TKG_PREVIEW_LINUX TKG_PREVIEW_NVIDIA TKG_PREVIEW_MESA TKG_PREVIEW_WINE TKG_PREVIEW_PROTON TKG_ECHO TKG_BREAK TKG_LINE TKG_RESET TKG_BOLD TKG_RED TKG_GREEN TKG_YELLOW TKG_BLUE

    # Exit with original exit code
    wait
    exit $code
}
# Setup exit trap for cleanup on script termination
trap _on_exit INT TERM EXIT HUP

# 🧼 Pre-installation checks and preparation
_pre() {

    # Welcome message
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🐸 TKG-Installer ${VERSION} for $DISTRO_NAME${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    ${TKG_ECHO} "${TKG_GREEN} 🔁 Starting...${TKG_RESET}"

    # Check for root execution
    if [[ "$(id -u)" -eq 0 ]]; then
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Do not run as root!${TKG_RESET}"
        exit 1
    fi

    # Check required dependencies
    local dependencies=(fzf bat curl fmt git)
    for required in "${dependencies[@]}"; do
        if ! command -v "$required" >/dev/null; then
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ $required is not installed! Please install it first.${TKG_RESET}"
            ${TKG_ECHO} "${TKG_YELLOW}${TKG_BOLD} 🔁 Run: pacman -S $required${TKG_RESET}"            
            exit 1
        fi
    done

    # Setup temporary directory
    ${TKG_ECHO} "${TKG_YELLOW} 🧹 Cleaning old temporary files...${TKG_RESET}"
    rm -rf "$TKG_TEMP_DIR" /tmp/tkginstaller.choice 2>/dev/null || true
    ${TKG_ECHO} "${TKG_GREEN} ✅ Create temporary directory...${TKG_RESET}"
    mkdir -p "$TKG_TEMP_DIR" 2>/dev/null || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error creating temporary directory: $TKG_TEMP_DIR${TKG_RESET}"
        return 1
    }

    # Message for preview section
    ${TKG_ECHO} "${TKG_BLUE} 📡 Retrieving content from Frogging-Family repo...${TKG_RESET}"

    # Final message
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} ✅ Pre-checks completed${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    sleep 2
}

# =============================================================================
# USER INTERFACE AND INTERACTION
# =============================================================================

# ✅ Display completion status with timestamp
_show_done() {
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
}

# ❓ Help information display
_help_prompt() {
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK}No arguments: Launch interactive menu${TKG_RESET}"
    ${TKG_ECHO} "${TKG_GREEN}Commandline usage: $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p|linuxnvidia|ln|nl|combo]${TKG_RESET}"
    ${TKG_ECHO} "${TKG_BLUE}Shortcuts: l=linux, n=nvidia, m=mesa, w=wine, p=proton, ln/combo=combo combo${TKG_RESET}"
    ${TKG_ECHO} " "
    ${TKG_ECHO} "${TKG_YELLOW}Example:${TKG_RESET}"
    ${TKG_ECHO} "${TKG_YELLOW}  $0 linux         # Install Linux-TKG${TKG_RESET}"
    ${TKG_ECHO} "${TKG_YELLOW}  $0 nvidia        # Install Nvidia-TKG${TKG_RESET}"
    ${TKG_ECHO} "${TKG_YELLOW}  $0 mesa          # Install Mesa-TKG${TKG_RESET}"
    ${TKG_ECHO} "${TKG_YELLOW}  $0 wine          # Install Wine-TKG${TKG_RESET}"
    ${TKG_ECHO} "${TKG_YELLOW}  $0 proton        # Install Proton-TKG${TKG_RESET}"
    ${TKG_ECHO} "${TKG_YELLOW}  $0 combo         # Install Linux-TKG + Nvidia-TKG${TKG_RESET}"
    ${TKG_ECHO} "${TKG_YELLOW}  See all shortcuts${TKG_RESET}"
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_RESET}"

    # Disable exit trap before cleanup and exit
    trap - INT TERM EXIT HUP
    
    # Clean exit without triggering _on_exit cleanup messages
    rm -f "$TKG_LOCKFILE" 2>/dev/null || true
    rm -rf /tmp/tkginstaller.choice "$TKG_TEMP_DIR" 2>/dev/null || true
    unset TKG_PREVIEW_LINUX TKG_PREVIEW_NVIDIA TKG_PREVIEW_MESA TKG_PREVIEW_WINE TKG_PREVIEW_PROTON TKG_ECHO TKG_BREAK TKG_LINE TKG_RESET TKG_BOLD TKG_RED TKG_GREEN TKG_YELLOW TKG_BLUE FROGGING_FAMILY_REPO FROGGING_FAMILY_RAW TKG_TEMP_DIR TKG_CONFIG_DIR 2>/dev/null || true
    
    exit 0
}

# 📝 Dynamic preview content generator for fzf menus
_get_preview_content() {
    local TKG_PREVIEW_CHOICE="$1"
    local TKG_PREVIEW_URL=""
    local TKG_PREVIEW_STATIC=""
    
    # Define repository URLs and static previews for each TKG package
    case "$TKG_PREVIEW_CHOICE" in
        linux)
            TKG_PREVIEW_URL="${FROGGING_FAMILY_RAW}/linux-tkg/master/README.md"
            TKG_PREVIEW_STATIC="Note:${TKG_BREAK}- Use the configuration editor to customize build options.${TKG_BREAK}- Ensure you have the necessary build dependencies installed.${TKG_BREAK}- The installer will clone the repository, build the kernel, and install it.${TKG_BREAK}- After installation, reboot to use the new kernel.${TKG_BREAK}${TKG_BREAK}Tips:${TKG_BREAK}- Run 'tkginstaller linux' to skip menu${TKG_BREAK}- Join the Frogging-Family community for support and updates.${TKG_BREAK}${TKG_BREAK}${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🧠 Online Preview${TKG_BREAK}${TKG_BREAK} - See full documentation at:${TKG_BREAK} - ${FROGGING_FAMILY_REPO}/linux-tkg/blob/master/README.md${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
            ;;
        nvidia)
            TKG_PREVIEW_URL="${FROGGING_FAMILY_RAW}/nvidia-all/master/README.md"
            TKG_PREVIEW_STATIC="Note:${TKG_BREAK}- Supports both open-source and proprietary Nvidia drivers.${TKG_BREAK}- Use the configuration editor to set driver options and patches.${TKG_BREAK}- Installer will clone the repo, build and install the driver.${TKG_BREAK}- Reboot after installation for changes to take effect.${TKG_BREAK}${TKG_BREAK}Tips:${TKG_BREAK}- Run 'tkginstaller nvidia' to skip menu${TKG_BREAK}- Check compatibility with your GPU model.${TKG_BREAK}- Join the Frogging-Family community for troubleshooting.${TKG_BREAK}${TKG_BREAK}${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🖥️ Online Preview${TKG_BREAK}${TKG_BREAK} - See full documentation at:${TKG_BREAK} - ${FROGGING_FAMILY_REPO}/nvidia-all/blob/master/README.md${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
            ;;
        mesa)
            TKG_PREVIEW_URL="${FROGGING_FAMILY_RAW}/mesa-git/master/README.md"
            TKG_PREVIEW_STATIC="Note:${TKG_BREAK}- Open-source graphics drivers for AMD and Intel GPUs.${TKG_BREAK}- Use the configuration editor for custom build flags.${TKG_BREAK}- Installer will clone, build, and install Mesa.${TKG_BREAK}- Reboot or restart X for changes to apply.${TKG_BREAK}${TKG_BREAK}Tips:${TKG_BREAK}- Run 'tkginstaller mesa' to skip menu${TKG_BREAK}- Useful for gaming and Vulkan support.${TKG_BREAK}- Join the Frogging-Family community for updates.${TKG_BREAK}${TKG_BREAK}${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🧩 Online Preview${TKG_BREAK}${TKG_BREAK} - See full documentation at:${TKG_BREAK} - ${FROGGING_FAMILY_REPO}/mesa-git/blob/master/README.md${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
            ;;
        wine)
            TKG_PREVIEW_URL="${FROGGING_FAMILY_RAW}/wine-tkg-git/master/README.md"
            TKG_PREVIEW_STATIC="Note:${TKG_BREAK}- Custom Wine builds for better compatibility and gaming performance.${TKG_BREAK}- Use the configuration editor for patches and tweaks.${TKG_BREAK}- Installer will clone, build, and install Wine-TKG.${TKG_BREAK}- Configure your prefix after installation.${TKG_BREAK}${TKG_BREAK}Tips:${TKG_BREAK}- Run 'tkginstaller wine' to skip menu${TKG_BREAK}- Ideal for running Windows games and apps.${TKG_BREAK}- Join the Frogging-Family community for support.${TKG_BREAK}${TKG_BREAK}${TKG_GREEN}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🍷 Online Preview${TKG_BREAK}${TKG_BREAK} - See full documentation at:${TKG_BREAK} - ${FROGGING_FAMILY_REPO}/wine-tkg-git/blob/master/README.md${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
            ;;
        proton)
            TKG_PREVIEW_URL="${FROGGING_FAMILY_RAW}/wine-tkg-git/master/proton-tkg/README.md"
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
            content=$(curl -fsSL --max-time 5 "$TKG_PREVIEW_URL" 2>/dev/null)
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
_init_previews() {
    TKG_PREVIEW_LINUX="$(_get_preview_content linux)"
    TKG_PREVIEW_NVIDIA="$(_get_preview_content nvidia)"
    TKG_PREVIEW_MESA="$(_get_preview_content mesa)"
    TKG_PREVIEW_WINE="$(_get_preview_content wine)"
    TKG_PREVIEW_PROTON="$(_get_preview_content proton)"
    export TKG_PREVIEW_LINUX TKG_PREVIEW_NVIDIA TKG_PREVIEW_MESA TKG_PREVIEW_WINE TKG_PREVIEW_PROTON
}

# 📝 Text editor wrapper with fallback support
_editor() {
    local file="$1"

    # Parse $EDITOR variable (may contain arguments)
    local _editor_raw="${EDITOR-}"
    local _editor_parts=()
    IFS=' ' read -r -a _editor_parts <<< "$_editor_raw" || true

    # Fallback to nano if no editor configured or not executable
    if [[ -z "${_editor_parts[0]:-}" ]] || ! command -v "${_editor_parts[0]}" >/dev/null 2>&1; then
        if command -v nano >/dev/null 2>&1; then
            _editor_parts=(nano)
        else
            ${TKG_ECHO} "${TKG_YELLOW} ⚠️ No editor found: please set \$EDITOR or install 'nano'.${TKG_RESET}"
            return 1
        fi
    fi

    # Execute the editor with the target file
    "${_editor_parts[@]}" "$file"
}
# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# 🧠 Linux-TKG installation
_linux_install() {
    cd "$TKG_TEMP_DIR"
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/linux-tkg.git" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error cloning: linux-tkg${TKG_RESET}"
        return 1
    }
    
    cd linux-tkg
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --number-of-authors 6
    fi
    
    # Build and install based on distribution
    local distro_id="${DISTRO_ID,,}"
    local distro_like="${DISTRO_ID_LIKE,,}"
    
    if [[ "${distro_id}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${distro_like}" == *"arch"* ]]; then
        ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Linux-TKG package with makepkg... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Adjust customization.cfg to skip prompts.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
        makepkg -si || {
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: linux-tkg${TKG_RESET}"
            return 1
        }
    else
        ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building Linux-TKG via install.sh... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: Review customization.cfg before continuing.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
        chmod +x install.sh 2>/dev/null || true
        ./install.sh install || {
            ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error running install.sh for linux-tkg${TKG_RESET}"
            return 1
        }
    fi
}

# 🖥️ Nvidia-TKG installation
_nvidia_install() {
    cd "$TKG_TEMP_DIR"
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/nvidia-all.git" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error cloning: nvidia-all${TKG_RESET}"
        return 1
    }
    
    cd nvidia-all
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --number-of-authors 6
    fi
    
    # Build and install 
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Nvidia-TKG package, this may take a while... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: If you adjust the config file, you can skip prompted questions during installation.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
    makepkg -si || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: nvidia-all${TKG_RESET}"
        return 1
    }
}

# 🧩 Mesa-TKG installation
_mesa_install() {
    cd "$TKG_TEMP_DIR"
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/mesa-git.git" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error cloning: mesa-git${TKG_RESET}"
        return 1
    }
    
    cd mesa-git
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --number-of-authors 6
    fi
    
    # Build and install 
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Mesa-TKG package, this may take a while... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: If you adjust the config file, you can skip prompted questions during installation.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
    makepkg -si || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: mesa-tkg${TKG_RESET}"
        return 1
    }
}

# 🍷 Wine-TKG installation
_wine_install() {
    cd "$TKG_TEMP_DIR"
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/wine-tkg-git.git" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error cloning: wine-tkg-git${TKG_RESET}"
        return 1
    }
    
    cd wine-tkg-git/wine-tkg-git
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --number-of-authors 6
    fi
    
    # Build and install 
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Wine-TKG package, this may take a while... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: If you adjust the config file, you can skip prompted questions during installation.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
    makepkg -si || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: wine-tkg${TKG_RESET}"
        return 1
    }
}

# 🎮 Proton-TKG installation
_proton_install() {
    cd "$TKG_TEMP_DIR"
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/wine-tkg-git.git" || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error cloning: wine-tkg-git${TKG_RESET}"
        return 1
    }
    
    cd wine-tkg-git/proton-tkg
    
    # Display repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --number-of-authors 6
    fi
    
    # Build Proton-TKG
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🏗️ Building and installing Proton-TKG package, this may take a while... ⏳${TKG_BREAK}${TKG_YELLOW} 💡 Tip: If you adjust the config file, you can skip prompted questions during installation.${TKG_BREAK}${TKG_GREEN}${TKG_LINE}${TKG_RESET}"
    ./proton-tkg.sh || {
        ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Error building: proton-tkg${TKG_RESET}"
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
# CONFIGURATION MANAGEMENT
# =============================================================================

# 🔧 Configuration file editor with interactive menu
_config_edit() {
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
                --header=$'🐸 TKG Configuration Editor ── External configuration file\n📝 Default directory: ~/.config/frogminer/' \
                --header-border=thinblock \
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
                        back)
                            ${TKG_ECHO} \"${TKG_GREEN}${TKG_BOLD}⏪ Back to Mainmenu!${TKG_RESET}\" ;;
                    esac
                " \
                --preview-label='Preview' \
                --preview-window='right:nowrap:60%' \
                --preview-border=thinblock \
                --pointer='🐸' \
                --disabled \
                --color='header:green,pointer:green,marker:green' <<'MENU'
linux-tkg  |🧠 Linux   ─ Ext. 🛠️ 📝: ~/.config/frogminer/linux-tkg.cfg
nvidia-all |🎮 Nvidia  ─ ➡️        : ➡️                  nvidia-all.cfg
mesa-git   |🧩 Mesa    ─ ➡️        : ➡️                  mesa-git.cfg
wine-tkg   |🍷 Wine    ─ ➡️        : ➡️                  wine-tkg.cfg
proton-tkg |🎮 Proton  ─ ➡️        : ➡️                  proton-tkg.cfg
back       |⏪ Back
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
                _handle_TKG_CONFIG_FILE \
                    "Linux-TKG" \
                    "${TKG_CONFIG_DIR}/linux-tkg.cfg" \
                    "${FROGGING_FAMILY_RAW}/linux-tkg/master/customization.cfg"
                ;;
            nvidia-all)
                _handle_TKG_CONFIG_FILE \
                    "Nvidia-TKG" \
                    "${TKG_CONFIG_DIR}/nvidia-all.cfg" \
                    "${FROGGING_FAMILY_RAW}/nvidia-all/master/customization.cfg"
                ;;
            mesa-git)
                _handle_TKG_CONFIG_FILE \
                    "Mesa-TKG" \
                    "${TKG_CONFIG_DIR}/mesa-git.cfg" \
                    "${FROGGING_FAMILY_RAW}/mesa-git/master/customization.cfg"
                ;;
            wine-tkg)
                _handle_TKG_CONFIG_FILE \
                    "Wine-TKG" \
                    "${TKG_CONFIG_DIR}/wine-tkg.cfg" \
                    "${FROGGING_FAMILY_RAW}/wine-tkg-git/master/wine-tkg-git/customization.cfg"
                ;;
            proton-tkg)
                _handle_TKG_CONFIG_FILE \
                    "Proton-TKG" \
                    "${TKG_CONFIG_DIR}/proton-tkg.cfg" \
                    "${FROGGING_FAMILY_RAW}/wine-tkg-git/master/proton-tkg/proton-tkg.cfg"
                ;;
            back)
                ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} ⏪ Exit editor menue...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"      
                return 0
                ;;
            *)          
                ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Invalid option: $TKG_CONFIG_FILE${TKG_RESET}"
                ;;
        esac
    done
}

# 📝 Helper function to handle individual config file editing
_handle_TKG_CONFIG_FILE() {
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
# INSTALLATION PROMPT FUNCTIONS
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
    _show_done
}

# 🖥️ Nvidia-TKG installation prompt
_nvidia_prompt() {
    SECONDS=0
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🖥️ Fetching Nvidia-TKG from Frogging-Family repository... ⏳${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    _nvidia_install
    _show_done
}

# 🧩 Mesa-TKG installation prompt
_mesa_prompt() {
    SECONDS=0
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🧩 Fetching Mesa-TKG from Frogging-Family repository... ⏳${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    _mesa_install
    _show_done
}

# 🍷 Wine-TKG installation prompt
_wine_prompt() {
    SECONDS=0
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🍷 Fetching Wine-TKG from Frogging-Family repository... ⏳${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    _wine_install
    _show_done
}

# 🎮 Proton-TKG installation prompt
_proton_prompt() {
    SECONDS=0
    ${TKG_ECHO} "${TKG_GREEN}${TKG_LINE}${TKG_BREAK} 🎮 Fetching Proton-TKG from Frogging-Family repository... ⏳${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
    _proton_install
    _show_done
}

# 🛠️ Configuration editor prompt
_config_prompt() {
    if _config_edit; then 
        return 0
    fi
}

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
            --header-label="$VERSION" \
            --header-label-pos=2 \
            --header-first \
            --footer=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\n🐸 Frogging-Family: https://github.com/Frogging-Family\n🌐 About: https://github.com/damachine/tkginstaller' \
            --footer-border=thinblock \
            --preview='case {} in \
                Linux*)
                    ${TKG_ECHO} "${TKG_BLUE}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🧠 Linux-TKG ─ Custom Linux kernels${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}$TKG_PREVIEW_LINUX";; \
                Nvidia*)
                    ${TKG_ECHO} "${TKG_BLUE}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🖥️ Nvidia-TKG ─ Open-Source or proprietary graphics driver${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}$TKG_PREVIEW_NVIDIA";; \
                Combo*)
                    ${TKG_ECHO} "${TKG_BLUE}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🧬 Combo package: 🟥🟦Linux-TKG ✚ 🟩Nvidia-TKG${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}$TKG_PREVIEW_LINUX${TKG_BREAK}${TKG_BREAK}$TKG_PREVIEW_NVIDIA";; \
                Mesa*)
                    ${TKG_ECHO} "${TKG_BLUE}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🧩 Mesa-TKG ─ Open-Source graphics driver for AMD and Intel${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}$TKG_PREVIEW_MESA";; \
                Wine*)
                    ${TKG_ECHO} "${TKG_BLUE}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🍷 Wine-TKG ─ Windows compatibility layer${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}$TKG_PREVIEW_WINE";; \
                Proton*)
                    ${TKG_ECHO} "${TKG_BLUE}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🎮 Proton-TKG ─ Windows compatibility layer for Steam / Gaming${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}$TKG_PREVIEW_PROTON";; \
                Config*)
                    ${TKG_ECHO} "${TKG_BLUE}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🛠️ TKG external configuration files ➡️${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}Edit all external TKG configuration files${TKG_BREAK}📝 Default directory: ~/.config/frogminer/${TKG_BREAK}${TKG_BREAK}See full documentation at:${TKG_BREAK}🌐 ${TKG_INSTALLER_REPO}${TKG_BREAK}🐸 Frogging-Family: ${FROGGING_FAMILY_REPO}";; \
                Clean*)
                    ${TKG_ECHO} "${TKG_BLUE}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}🧹 TKG-Installer - Cleaning${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}Removes temporary files in ~/.cache/tkginstaller and resets the installer.${TKG_BREAK}${TKG_BREAK}See full documentation at:${TKG_BREAK}🌐 ${TKG_INSTALLER_REPO}";; \
                Help*)
                    ${TKG_ECHO} "${TKG_BLUE}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}❓ TKG-Installer - Help${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}Shows all Commandline usage.${TKG_BREAK}${TKG_BREAK}See full documentation at:${TKG_BREAK}🌐 ${TKG_INSTALLER_REPO}${TKG_BREAK}🐸 Frogging-Family: ${FROGGING_FAMILY_REPO}";; \
                Exit*)
                    ${TKG_ECHO} "${TKG_BLUE}${TKG_BOLD}${TKG_LINE}${TKG_BREAK}👋 Exit the program and removes temporary files${TKG_BREAK}${TKG_LINE}${TKG_RESET}${TKG_BREAK}${TKG_BREAK}💖 Thank you for using TKG-Installer! 💖${TKG_BREAK}${TKG_BREAK}If you like this program, please support the project on GitHub ⭐ ⭐ ⭐${TKG_BREAK}${TKG_BREAK}🌐 See: ${TKG_INSTALLER_REPO}${TKG_BREAK}🐸 Frogging-Family: ${FROGGING_FAMILY_REPO}";; \
                esac' \
            --preview-label='Preview' \
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
        _on_exit
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
                _help_prompt
                ;;
            *)
                ${TKG_ECHO} "${TKG_RED}${TKG_BOLD} ❌ Unknown argument: ${1:-}${TKG_RESET}"
                ${TKG_ECHO} "${TKG_GREEN} 📝 Usage: $0 help${TKG_RESET}"
                ${TKG_ECHO} "${TKG_GREEN}           $0 [linux|nvidia|mesa|wine|proton]${TKG_RESET}"
                exit 1
                ;;
        esac
    fi

    # Interactive mode - show menu and handle user selection
    _init_previews
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
            _help_prompt
            ;;
        Clean)
            ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} 🧹 Cleaning temporary files...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"      
            _pre
            sleep 1
            ${TKG_ECHO} "${TKG_YELLOW}${TKG_LINE}${TKG_BREAK} 🔁 Restarting 🐸 TKG-Installer...${TKG_BREAK}${TKG_LINE}${TKG_RESET}"
            rm -f "$TKG_LOCKFILE"
            sleep 2
            clear
            exec "$0" 
            ;;
        Exit)
            _on_exit
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
