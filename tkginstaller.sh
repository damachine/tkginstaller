#!/usr/bin/env bash

# TKG-Installer VERSION
readonly VERSION="v0.7.4"

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
readonly LOCKFILE="/tmp/tkginstaller.lock"
readonly TEMP_DIR="$HOME/.cache/tkginstaller"
readonly CONFIG_DIR="$HOME/.config/frogminer"
readonly FROGGING_FAMILY_REPO="https://github.com/Frogging-Family"
readonly FROGGING_FAMILY_RAW="https://raw.githubusercontent.com/Frogging-Family"

# 🎨 Formatting and color definitions
ECHO="echo -e"
BREAK="\n"
LINE="──────────────────────────────────────────────────────────────────────────────────────────"
RESET=$"\033[0m"
BOLD=$"\033[1m"
RED=$"\033[0;31m"
GREEN=$"\033[0;32m"
YELLOW=$"\033[0;33m"
BLUE=$"\033[0;34m"

# 📝 Export variables for fzf subshells (unset _on_exit run)
export ECHO BREAK LINE RESET BOLD RED GREEN YELLOW BLUE

# 🔒 Prevent concurrent execution
if [[ -f "$LOCKFILE" ]]; then
    ${ECHO} "${RED}${BOLD} ❌ Script is already running. Exiting...${RESET}"
    ${ECHO} "${YELLOW}${BOLD} 🔁 If the script was unexpectedly terminated, remove the lock file manually: rm $LOCKFILE${RESET}"
    exit 1
fi
touch "$LOCKFILE"

# 🧑‍💻 Detect Linux Distribution
if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    readonly DISTRO_NAME="$NAME"
else
    readonly DISTRO_NAME="Unknown"
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
        ${ECHO} "${RED}${BOLD}${LINE}${BREAK} 🎯 ERROR 🎯 TKG-Installer aborted! Exiting...${BREAK}${LINE}${RESET}"
    else
        # Final cleanup message
        ${ECHO} "${GREEN} 💖 Thank you for using TKG-Installer 🌐 https://github.com/damachine/tkginstaller${RESET}"
        ${ECHO} "${GREEN}                                      🐸 https://github.com/Frogging-Family${RESET}"
        ${ECHO} "${GREEN} 🧹 Cleanup completed${RESET}"
        ${ECHO} "${GREEN} 👋 Closed!${RESET}"
        ${ECHO} "${GREEN}${LINE}${BREAK}${RESET}"
    fi
    
    # Remove lockfile
    rm -f "$LOCKFILE" 2>/dev/null || true

    # Clean temporary files
    rm -rf /tmp/tkginstaller_choice "$TEMP_DIR" 2>/dev/null || true

    # Unset exported all variables
    unset PREVIEW_LINUX PREVIEW_NVIDIA PREVIEW_MESA PREVIEW_WINE PREVIEW_PROTON ECHO BREAK LINE RESET BOLD RED GREEN YELLOW BLUE

    # Exit with original exit code
    wait
    exit $code
}
# Setup exit trap for cleanup on script termination
trap _on_exit INT TERM EXIT HUP

# 🧼 Pre-installation checks and preparation
_pre() {

    # Welcome message
    ${ECHO} "${GREEN}${LINE}${BREAK} 🐸 TKG-Installer ${VERSION} for $DISTRO_NAME${BREAK}${LINE}${RESET}"
    ${ECHO} "${GREEN} 🔁 Starting...${RESET}"

    # Check for root execution
    if [[ "$(id -u)" -eq 0 ]]; then
        ${ECHO} "${RED}${BOLD} ❌ Do not run as root!${RESET}"
        exit 1
    fi

    # Check required dependencies
    local required_commands=(fzf bat curl git glow)
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null; then
            ${ECHO} "${RED}${BOLD} ❌ $cmd is not installed! Please install it first.${RESET}"
            ${ECHO} "${YELLOW}${BOLD} 🔁 Run: pacman -S $cmd${RESET}"            
            exit 1
        fi
    done

    # Setup temporary directory
    ${ECHO} "${YELLOW} 🧹 Cleaning old temporary files...${RESET}"
    rm -rf "$TEMP_DIR" /tmp/tkginstaller_choice 2>/dev/null || true
    ${ECHO} "${GREEN} ✅ Create temporary directory...${RESET}"
    mkdir -p "$TEMP_DIR" 2>/dev/null || {
        ${ECHO} "${RED}${BOLD} ❌ Error creating temporary directory: $TEMP_DIR${RESET}"
        return 1
    }

    # Message for preview section
    ${ECHO} "${BLUE} 📡 Retrieving content from Frogging-Family repo...${RESET}"

    # Update system (Arch Linux specific)
    if command -v pacman &>/dev/null; then
        ${ECHO} "${BLUE} 🔍 Updating $DISTRO_NAME mirrors...${RESET}"
        if ! sudo -n pacman -Sy >/dev/null 2>&1; then
            ${ECHO} "${YELLOW} ⚠️ Password required for mirror update. You can skip this step.${RESET}"
            read -r -p "Do you want to update mirrors now? [y/N]: " update_mirrors
            case "$update_mirrors" in
                y|Y|yes)
                    sudo pacman -Sy >/dev/null 2>&1 || {
                        ${ECHO} "${YELLOW} ⚠️ Mirror update failed or cancelled. Continuing without update...${RESET}"
                    }
                    ;;
                *)
                    ${ECHO} "${YELLOW} ⚠️ Mirror update skipped. Continuing...${RESET}"
                    ;;
            esac
        fi
    fi

    # Final message
    ${ECHO} "${GREEN}${LINE}${BREAK} ✅ Pre-checks completed${BREAK}${LINE}${RESET}"
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

    ${ECHO} "${GREEN}${LINE}${BREAK} 📝 Action completed: $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    
    if [[ $status -eq 0 ]]; then
        ${ECHO} "${GREEN} ✅ Status: Successful${RESET}"
    else
        ${ECHO} "${RED}${BOLD} ❌ Status: Error (Code: $status)${RESET}"
    fi

    ${ECHO} "${YELLOW} ⏱️ Duration: ${minutes} min ${seconds} sec${RESET}${GREEN}${BREAK}${LINE}${RESET}"
}

# ❓ Help information display
_help_prompt() {
    ${ECHO} "${GREEN}${LINE}${BREAK}No arguments: Launch interactive menu${RESET}"
    ${ECHO} "${GREEN}Commandline usage: $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p|linuxnvidia|ln|nl|combo]${RESET}"
    ${ECHO} "${BLUE}Shortcuts: l=linux, n=nvidia, m=mesa, w=wine, p=proton, ln/combo=combo combo${RESET}"
    ${ECHO} " "
    ${ECHO} "${YELLOW}Example:${RESET}"
    ${ECHO} "${YELLOW}  $0 linux         # Install Linux-TKG${RESET}"
    ${ECHO} "${YELLOW}  $0 nvidia        # Install Nvidia-TKG${RESET}"
    ${ECHO} "${YELLOW}  $0 mesa          # Install Mesa-TKG${RESET}"
    ${ECHO} "${YELLOW}  $0 wine          # Install Wine-TKG${RESET}"
    ${ECHO} "${YELLOW}  $0 proton        # Install Proton-TKG${RESET}"
    ${ECHO} "${YELLOW}  $0 combo         # Install Linux-TKG + Nvidia-TKG${RESET}"
    ${ECHO} "${YELLOW}  See all shortcuts${RESET}"
    ${ECHO} "${GREEN}${LINE}${RESET}"

    # Disable exit trap before cleanup and exit
    trap - INT TERM EXIT HUP
    
    # Clean exit without triggering _on_exit cleanup messages
    rm -f "$LOCKFILE" 2>/dev/null || true
    rm -rf /tmp/tkginstaller_choice "$TEMP_DIR" 2>/dev/null || true
    unset PREVIEW_LINUX PREVIEW_NVIDIA PREVIEW_MESA PREVIEW_WINE PREVIEW_PROTON ECHO BREAK LINE RESET BOLD RED GREEN YELLOW BLUE 2>/dev/null || true
    
    exit 0
}

# 📝 Dynamic preview content generator for fzf menus
_get_preview_content() {
    local repo_type="$1"
    local repo_url=""
    local static_preview=""
    
    # Define repository URLs and static previews for each TKG package
    case "$repo_type" in
        linux)
            repo_url="${FROGGING_FAMILY_RAW}/linux-tkg/master/README.md"
            static_preview="Note:${BREAK}- Use the configuration editor to customize build options.${BREAK}- Ensure you have the necessary build dependencies installed.${BREAK}- The installer will clone the repository, build the kernel, and install it.${BREAK}- After installation, reboot to use the new kernel.${BREAK}${BREAK}Tips:${BREAK}- Run 'tkginstaller linux' to skip menu${BREAK}- Join the Frogging-Family community for support and updates.${BREAK}${BREAK}${GREEN}${BOLD}${LINE}${BREAK}🧠 Online Preview${BREAK}${BREAK} - See full documentation at:${BREAK} - ${FROGGING_FAMILY_REPO}/linux-tkg/blob/master/README.md${BREAK}${LINE}${RESET}"
            ;;
        nvidia)
            repo_url="${FROGGING_FAMILY_RAW}/nvidia-all/master/README.md"
            static_preview="Note:${BREAK}- Supports both open-source and proprietary Nvidia drivers.${BREAK}- Use the configuration editor to set driver options and patches.${BREAK}- Installer will clone the repo, build and install the driver.${BREAK}- Reboot after installation for changes to take effect.${BREAK}${BREAK}Tips:${BREAK}- Run 'tkginstaller nvidia' to skip menu${BREAK}- Check compatibility with your GPU model.${BREAK}- Join the Frogging-Family community for troubleshooting.${BREAK}${BREAK}${GREEN}${BOLD}${LINE}${BREAK}🖥️ Online Preview${BREAK}${BREAK} - See full documentation at:${BREAK} - ${FROGGING_FAMILY_REPO}/nvidia-all/blob/master/README.md${BREAK}${LINE}${RESET}"
            ;;
        mesa)
            repo_url="${FROGGING_FAMILY_RAW}/mesa-git/master/README.md"
            static_preview="Note:${BREAK}- Open-source graphics drivers for AMD and Intel GPUs.${BREAK}- Use the configuration editor for custom build flags.${BREAK}- Installer will clone, build, and install Mesa.${BREAK}- Reboot or restart X for changes to apply.${BREAK}${BREAK}Tips:${BREAK}- Run 'tkginstaller mesa' to skip menu${BREAK}- Useful for gaming and Vulkan support.${BREAK}- Join the Frogging-Family community for updates.${BREAK}${BREAK}${GREEN}${BOLD}${LINE}${BREAK}🧩 Online Preview${BREAK}${BREAK} - See full documentation at:${BREAK} - ${FROGGING_FAMILY_REPO}/mesa-git/blob/master/README.md${BREAK}${LINE}${RESET}"
            ;;
        wine)
            repo_url="${FROGGING_FAMILY_RAW}/wine-tkg-git/master/README.md"
            static_preview="Note:${BREAK}- Custom Wine builds for better compatibility and gaming performance.${BREAK}- Use the configuration editor for patches and tweaks.${BREAK}- Installer will clone, build, and install Wine-TKG.${BREAK}- Configure your prefix after installation.${BREAK}${BREAK}Tips:${BREAK}- Run 'tkginstaller wine' to skip menu${BREAK}- Ideal for running Windows games and apps.${BREAK}- Join the Frogging-Family community for support.${BREAK}${BREAK}${GREEN}${BOLD}${LINE}${BREAK}🍷 Online Preview${BREAK}${BREAK} - See full documentation at:${BREAK} - ${FROGGING_FAMILY_REPO}/wine-tkg-git/blob/master/README.md${BREAK}${LINE}${RESET}"
            ;;
        proton)
            repo_url="${FROGGING_FAMILY_RAW}/wine-tkg-git/master/proton-tkg/README.md"
            static_preview="Note:${BREAK}- Custom Proton builds for Steam Play and gaming.${BREAK}- Use the configuration editor for tweaks and patches.${BREAK}- Installer will clone, build, and install Proton-TKG.${BREAK}- Select Proton-TKG in Steam after installation.${BREAK}${BREAK}Tips:${BREAK}- Run 'tkginstaller proton' to skip menu${BREAK}- Great for running Windows games via Steam.${BREAK}- Join the Frogging-Family community for updates.${BREAK}${BREAK}${GREEN}${BOLD}${LINE}${BREAK}🎮 Online Preview${BREAK}${BREAK} - See full documentation at:${BREAK} - ${FROGGING_FAMILY_REPO}/wine-tkg-git/blob/master/proton-tkg/README.md${BREAK}${LINE}${RESET}"
            ;;
    esac

    # Always show static preview first
    ${ECHO} "$static_preview"
       
   # Try to display remote content with available tools (glow > bat > plain text)
    if command -v glow >/dev/null 2>&1; then
        FORCE_COLOR=1 CLICOLOR_FORCE=1 TERM=xterm-256color glow --style=dark --width=80 "$repo_url" 2>/dev/null
    else
        # Download content
        local content=""
        if command -v curl >/dev/null 2>&1; then
            content=$(curl -fsSL --max-time 5 "$repo_url" 2>/dev/null)
        fi

        if [[ -n "$content" ]]; then
            if command -v bat >/dev/null 2>&1; then
                echo "$content" | bat --style=plain --color=always --language=markdown 2>/dev/null
            else
                echo "$content"
            fi
        fi
    fi
}

# 📝 Export preview content for fzf menu (will be unset in _on_exit)
PREVIEW_LINUX="$(_get_preview_content linux)"
export PREVIEW_LINUX
PREVIEW_NVIDIA="$(_get_preview_content nvidia)"
export PREVIEW_NVIDIA
PREVIEW_MESA="$(_get_preview_content mesa)"
export PREVIEW_MESA
PREVIEW_WINE="$(_get_preview_content wine)"
export PREVIEW_WINE
PREVIEW_PROTON="$(_get_preview_content proton)"
export PREVIEW_PROTON

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
            ${ECHO} "${YELLOW} ⚠️ No editor found: please set \$EDITOR or install 'nano'.${RESET}"
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
    cd "$TEMP_DIR"
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/linux-tkg.git" || {
        ${ECHO} "${RED}${BOLD} ❌ Error cloning: linux-tkg${RESET}"
        return 1
    }
    
    cd linux-tkg
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --number-of-authors 6
    fi
    
    # Build and install 
    ${ECHO} "${GREEN}${LINE}${BREAK} 🏗️ Building and installing Linux-TKG package, this may take a while... ⏳${BREAK}${YELLOW} 💡 Tip: If you adjust the config file, you can skip prompted questions during installation.${BREAK}${GREEN}${LINE}${RESET}"
    makepkg -si || {
        ${ECHO} "${RED}${BOLD} ❌ Error building: linux-tkg${RESET}"
        return 1
    }
}

# 🖥️ Nvidia-TKG installation
_nvidia_install() {
    cd "$TEMP_DIR"
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/nvidia-all.git" || {
        ${ECHO} "${RED}${BOLD} ❌ Error cloning: nvidia-all${RESET}"
        return 1
    }
    
    cd nvidia-all
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --number-of-authors 6
    fi
    
    # Build and install 
    ${ECHO} "${GREEN}${LINE}${BREAK} 🏗️ Building and installing Nvidia-TKG package, this may take a while... ⏳${BREAK}${YELLOW} 💡 Tip: If you adjust the config file, you can skip prompted questions during installation.${BREAK}${GREEN}${LINE}${RESET}"
    makepkg -si || {
        ${ECHO} "${RED}${BOLD} ❌ Error building: nvidia-all${RESET}"
        return 1
    }
}

# 🧩 Mesa-TKG installation
_mesa_install() {
    cd "$TEMP_DIR"
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/mesa-git.git" || {
        ${ECHO} "${RED}${BOLD} ❌ Error cloning: mesa-git${RESET}"
        return 1
    }
    
    cd mesa-git
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --number-of-authors 6
    fi
    
    # Build and install 
    ${ECHO} "${GREEN}${LINE}${BREAK} 🏗️ Building and installing Mesa-TKG package, this may take a while... ⏳${BREAK}${YELLOW} 💡 Tip: If you adjust the config file, you can skip prompted questions during installation.${BREAK}${GREEN}${LINE}${RESET}"
    makepkg -si || {
        ${ECHO} "${RED}${BOLD} ❌ Error building: mesa-tkg${RESET}"
        return 1
    }
}

# 🍷 Wine-TKG installation
_wine_install() {
    cd "$TEMP_DIR"
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/wine-tkg-git.git" || {
        ${ECHO} "${RED}${BOLD} ❌ Error cloning: wine-tkg-git${RESET}"
        return 1
    }
    
    cd wine-tkg-git/wine-tkg-git
    
    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --number-of-authors 6
    fi
    
    # Build and install 
    ${ECHO} "${GREEN}${LINE}${BREAK} 🏗️ Building and installing Wine-TKG package, this may take a while... ⏳${BREAK}${YELLOW} 💡 Tip: If you adjust the config file, you can skip prompted questions during installation.${BREAK}${GREEN}${LINE}${RESET}"
    makepkg -si || {
        ${ECHO} "${RED}${BOLD} ❌ Error building: wine-tkg${RESET}"
        return 1
    }
}

# 🎮 Proton-TKG installation
_proton_install() {
    cd "$TEMP_DIR"
    
    # Clone repository
    git clone "${FROGGING_FAMILY_REPO}/wine-tkg-git.git" || {
        ${ECHO} "${RED}${BOLD} ❌ Error cloning: wine-tkg-git${RESET}"
        return 1
    }
    
    cd wine-tkg-git/proton-tkg
    
    # Display repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-art --http-url --number-of-authors 6
    fi
    
    # Build Proton-TKG
    ${ECHO} "${GREEN}${LINE}${BREAK} 🏗️ Building and installing Proton-TKG package, this may take a while... ⏳${BREAK}${YELLOW} 💡 Tip: If you adjust the config file, you can skip prompted questions during installation.${BREAK}${GREEN}${LINE}${RESET}"
    ./proton-tkg.sh || {
        ${ECHO} "${RED}${BOLD} ❌ Error building: proton-tkg${RESET}"
        return 1
    }
    
    # Clean up build artifacts
    ${ECHO} "${GREEN}${LINE}${BREAK} 🏗️ Clean up build artifacts...${BREAK}${LINE}${RESET}"
    ./proton-tkg.sh clean || {
        ${ECHO} "${RED}${BOLD} ❌ Nothing to clean: proton-tkg${RESET}"
        return 1
    }
}

# =============================================================================
# CONFIGURATION MANAGEMENT
# =============================================================================

# 🔧 Configuration file editor with interactive menu
_config_edit() {
    while true; do
        local config_choice
        
        # Ensure configuration directory exists
        if [[ ! -d "${CONFIG_DIR}" ]]; then
            ${ECHO} "${RED}${BOLD} ❌ Configuration directory not found: ${CONFIG_DIR}${RESET}"
            read -r -p "Do you want to create the configuration directory? [y/N]:" create_dir
            case "$create_dir" in
                y|Y|yes)
                    mkdir -p "${CONFIG_DIR}" || {
                        ${ECHO} "${RED}${BOLD} ❌ Error creating configuration directory!${RESET}"
                        return 1
                    }
                    ;;
                n|N|no)
                    ${ECHO} "${YELLOW} ⚠️ Directory creation cancelled. Returning to menu.${RESET}"
                    return 0
                    ;;
                *)
                    ${ECHO} "${YELLOW} ⚠️ Invalid input. Returning to menu.${RESET}"
                    return 0
                    ;;
            esac
        fi
        
        # Interactive configuration file selection with preview
        # shellcheck disable=SC2016  # allow fzf to expand variables in its own shell at runtime
        config_choice=$(
            fzf \
                --with-shell="bash -c" \
                --style full:thinblock \
                --border=none \
                --layout=reverse \
                --highlight-line \
                --height="-1" \
                --ansi \
                --delimiter="|" \
                --with-nth="2" \
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
                            bat --style=numbers --color=always \"${CONFIG_DIR}/linux-tkg.cfg\" 2>/dev/null || ${ECHO} \"${RED}${BOLD} ❌ Error: No external configuration file found${RESET}\" ;;
                        nvidia-all)
                            bat --style=numbers --color=always \"${CONFIG_DIR}/nvidia-all.cfg\" 2>/dev/null || ${ECHO} \"${RED}${BOLD} ❌ Error: No external configuration file found${RESET}\" ;;
                        mesa-git)
                            bat --style=numbers --color=always \"${CONFIG_DIR}/mesa-git.cfg\" 2>/dev/null || ${ECHO} \"${RED}${BOLD} ❌ Error: No external configuration file found${RESET}\" ;;
                        wine-tkg)
                            bat --style=numbers --color=always \"${CONFIG_DIR}/wine-tkg.cfg\" 2>/dev/null || ${ECHO} \"${RED}${BOLD} ❌ Error: No external configuration file found${RESET}\" ;;
                        proton-tkg)
                            bat --style=numbers --color=always \"${CONFIG_DIR}/proton-tkg.cfg\" 2>/dev/null || ${ECHO} \"${RED}${BOLD} ❌ Error: No external configuration file found${RESET}\" ;;
                        back)
                            ${ECHO} \"${GREEN}${BOLD}👋 Back to Mainmenu!${RESET}\" ;;
                    esac
                " \
                --preview-label="Preview" \
                --preview-window="right:nowrap:60%" \
                --preview-border=thinblock \
                --color='header:green,pointer:green,marker:green'<<'MENU'
linux-tkg  |🧠 Linux   ─ Edit file:📝 ~/.config/frogminer/linux-tkg.cfg
nvidia-all |🎮 Nvidia  ─ Edit file:📝 ~/.config/frogminer/nvidia-all.cfg
mesa-git   |🧩 Mesa    ─ Edit file:📝 ~/.config/frogminer/mesa-git.cfg
wine-tkg   |🍷 Wine    ─ Edit file:📝 ~/.config/frogminer//wine-tkg.cfg
proton-tkg |🎮 Proton  ─ Edit file:📝 ~/.config/frogminer/proton-tkg.cfg
back       |⏪ Back
MENU
        )
        
        # Handle cancelled selection
        if [[ -z "$config_choice" ]]; then
            ${ECHO} "${RED}${BOLD} ❌ Selection cancelled.${RESET}"
            return 1
        fi
        
        # Extract selected configuration type
        local config_file
        config_file=$(echo "$config_choice" | cut -d"|" -f1 | xargs)
        
        # Handle configuration file editing
        case $config_file in
            linux-tkg)
                _handle_config_file \
                    "Linux-TKG" \
                    "${CONFIG_DIR}/linux-tkg.cfg" \
                    "${FROGGING_FAMILY_RAW}/linux-tkg/master/customization.cfg"
                ;;
            nvidia-all)
                _handle_config_file \
                    "Nvidia-TKG" \
                    "${CONFIG_DIR}/nvidia-all.cfg" \
                    "${FROGGING_FAMILY_RAW}/nvidia-all/master/customization.cfg"
                ;;
            mesa-git)
                _handle_config_file \
                    "Mesa-TKG" \
                    "${CONFIG_DIR}/mesa-git.cfg" \
                    "${FROGGING_FAMILY_RAW}/mesa-git/master/customization.cfg"
                ;;
            wine-tkg)
                _handle_config_file \
                    "Wine-TKG" \
                    "${CONFIG_DIR}/wine-tkg.cfg" \
                    "${FROGGING_FAMILY_RAW}/wine-tkg-git/master/wine-tkg-git/customization.cfg"
                ;;
            proton-tkg)
                _handle_config_file \
                    "Proton-TKG" \
                    "${CONFIG_DIR}/proton-tkg.cfg" \
                    "${FROGGING_FAMILY_RAW}/wine-tkg-git/master/proton-tkg/proton-tkg.cfg"
                ;;
            back)       
                return 0
                ;;
            *)          
                ${ECHO} "${RED}${BOLD} ❌ Invalid option: $config_file${RESET}"
                ;;
        esac
    done
}

# 📝 Helper function to handle individual config file editing
_handle_config_file() {
    local config_name="$1"
    local config_path="$2" 
    local config_url="$3"
    
    ${ECHO} "${BLUE} 🔧 Opening external $config_name configuration...${RESET}"
    
    if [[ -f "$config_path" ]]; then
        # Edit existing configuration file
        _editor "$config_path" || {
            ${ECHO} "${RED}${BOLD} ❌ Error opening $config_path configuration!${RESET}"
            return 1
        }
    else
        # Download and create new configuration file
        ${ECHO} "${YELLOW}${BOLD} ⚠️ $config_path does not exist.${RESET}"
        read -r -p "Do you want to download the default configuration from $config_url? [y/N]: " answer
        case "$answer" in
            y|Y|yes)
                mkdir -p "$(dirname "$config_path")"
                if curl -fsSL "$config_url" -o "$config_path" 2>/dev/null; then
                    ${ECHO} "${GREEN} ✅ Configuration ready at $config_path${RESET}"
                    _editor "$config_path" || {
                        ${ECHO} "${RED}${BOLD} ❌ Error opening $config_path configuration!${RESET}"
                        return 1
                    }
                else
                    ${ECHO} "${RED}${BOLD} ❌ Error downloading configuration from $config_url${RESET}"
                    return 1
                fi
                ;;
            *)
                ${ECHO} "${YELLOW} ⚠️ Download cancelled. No configuration file created.${RESET}"
                return 1
                ;;
        esac
    fi

    ${ECHO} "${GREEN} ✅ Configuration saved!${RESET}"
    sleep 1
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
    ${ECHO} "${GREEN}${LINE}${BREAK} 🧠 Fetching Linux-TKG from Frogging-Family repository... ⏳${BREAK}${LINE}${RESET}"
    _linux_install
}

# 🖥️ Nvidia-TKG installation prompt
_nvidia_prompt() {
    SECONDS=0
    ${ECHO} "${GREEN}${LINE}${BREAK} 🖥️ Fetching Nvidia-TKG from Frogging-Family repository... ⏳${BREAK}${LINE}${RESET}"
    _nvidia_install
}

# 🧩 Mesa-TKG installation prompt
_mesa_prompt() {
    SECONDS=0
    ${ECHO} "${GREEN}${LINE}${BREAK} 🧩 Fetching Mesa-TKG from Frogging-Family repository... ⏳${BREAK}${LINE}${RESET}"
    _mesa_install
}

# 🍷 Wine-TKG installation prompt
_wine_prompt() {
    SECONDS=0
    ${ECHO} "${GREEN}${LINE}${BREAK} 🍷 Fetching Wine-TKG from Frogging-Family repository... ⏳${BREAK}${LINE}${RESET}"
    _wine_install
}

# 🎮 Proton-TKG installation prompt
_proton_prompt() {
    SECONDS=0
    ${ECHO} "${GREEN}${LINE}${BREAK} 🎮 Fetching Proton-TKG from Frogging-Family repository... ⏳${BREAK}${LINE}${RESET}"
    _proton_install
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
            --with-shell="bash -c" \
            --style full:thinblock \
            --border=none \
            --layout=reverse \
            --highlight-line \
            --height="-1" \
            --ansi \
            --delimiter="|" \
            --with-nth="2" \
            --no-input \
            --no-multi \
            --no-multi-line \
            --header="🐸 🐸 🐸 TKG-Installer ── Select a package 🐸 🐸 🐸" \
            --header-border=thinblock \
            --header-label="$VERSION" \
            --header-label-pos=2 \
            --header-first \
            --footer=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\n🐸 Frogging-Family: https://github.com/Frogging-Family\n🌐 About: https://github.com/damachine/tkginstaller' \
            --footer-border=thinblock \
            --preview='case {} in \
                Linux*)     ${ECHO} "${BLUE}${BOLD}${LINE}${BREAK}🧠 Linux-TKG ─ Custom Linux kernels${BREAK}${LINE}${RESET}${BREAK}${BREAK}$PREVIEW_LINUX";; \
                Nvidia*)    ${ECHO} "${BLUE}${BOLD}${LINE}${BREAK}🖥️ Nvidia-TKG ─ Open-Source or proprietary graphics driver${BREAK}${LINE}${RESET}${BREAK}${BREAK}$PREVIEW_NVIDIA";; \
                Combo*)     ${ECHO} "${BLUE}${BOLD}${LINE}${BREAK}🧬 Combo package: 🟦Linux-TKG ✚ 🟩Nvidia-TKG${BREAK}${LINE}${RESET}${BREAK}${BREAK}$PREVIEW_LINUX${BREAK}${BREAK}$PREVIEW_NVIDIA";; \
                Mesa*)      ${ECHO} "${BLUE}${BOLD}${LINE}${BREAK}🧩 Mesa-TKG ─ Open-Source graphics driver for AMD and Intel${BREAK}${LINE}${RESET}${BREAK}${BREAK}$PREVIEW_MESA";; \
                Wine*)      ${ECHO} "${BLUE}${BOLD}${LINE}${BREAK}🍷 Wine-TKG ─ Windows compatibility layer${BREAK}${LINE}${RESET}${BREAK}${BREAK}$PREVIEW_WINE";; \
                Proton*)    ${ECHO} "${BLUE}${BOLD}${LINE}${BREAK}🎮 Proton-TKG ─ Windows compatibility layer for Steam / Gaming${BREAK}${LINE}${RESET}${BREAK}${BREAK}$PREVIEW_PROTON";; \
                Config*)    ${ECHO} "${BLUE}${BOLD}${LINE}${BREAK}🛠️ TKG external configuration files ➡️${BREAK}${LINE}${RESET}${BREAK}${BREAK}Edit all external TKG configuration files${BREAK}📝 Default directory: ~/.config/frogminer/${BREAK}${BREAK}See full documentation at:${BREAK}🌐 https://github.com/damachine/tkginstaller${BREAK}🐸 Frogging-Family: https://github.com/Frogging-Family";; \
                Clean*)     ${ECHO} "${BLUE}${BOLD}${LINE}${BREAK}🧹 TKG-Installer - Cleaning${BREAK}${LINE}${RESET}${BREAK}${BREAK}Removes temporary files in ~/.cache/tkginstaller and resets the installer.${BREAK}${BREAK}See full documentation at:${BREAK}🌐 https://github.com/damachine/tkginstaller";; \
                Help*)      ${ECHO} "${BLUE}${BOLD}${LINE}${BREAK}❓ TKG-Installer - Help${BREAK}${LINE}${RESET}${BREAK}${BREAK}Shows all Commandline usage.${BREAK}${BREAK}See full documentation at:${BREAK}🌐 https://github.com/damachine/tkginstaller${BREAK}🐸 Frogging-Family: https://github.com/Frogging-Family";; \
                Exit*)      ${ECHO} "${BLUE}${BOLD}${LINE}${BREAK}👋 Exit the program and removes temporary files${BREAK}${LINE}${RESET}${BREAK}${BREAK}💖 Thank you for using TKG-Installer! 💖${BREAK}${BREAK}If you like this program, please support the project on GitHub ⭐ ⭐ ⭐${BREAK}${BREAK}🌐 See: https://github.com/damachine/tkginstaller${BREAK}🐸 Frogging-Family: https://github.com/Frogging-Family";; \
                esac' \
            --preview-label="Preview" \
            --preview-window="right:nowrap:60%" \
            --preview-border=thinblock \
            --color='header:green,pointer:green,marker:green' <<'MENU'
Linux  |🧠 Kernel    ─ Linux-TKG custom kernels
Nvidia |🖥️ Nvidia    ─ Nvidia Open-Source or proprietary graphics driver
Combo  |🧬 Combo➕   ─ Combo package: 🟦Linux-TKG ✚ 🟩Nvidia-TKG
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
        ${ECHO} " ${RED}${BOLD} ❌ Selection cancelled.${RESET}"
        _on_exit
    fi

    # Save selection to temporary file for processing
    echo "$selection" | cut -d"|" -f1 | xargs > /tmp/tkginstaller_choice
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
                _show_done
                exit 0
                ;;
            linux|l)
                _pre
                _linux_prompt
                _show_done
                exit 0
                ;;
            nvidia|n)
                _pre
                _nvidia_prompt
                _show_done
                exit 0
                ;;
            mesa|m)
                _pre
                _mesa_prompt
                _show_done
                exit 0
                ;;
            wine|w)
                _pre
                _wine_prompt
                _show_done
                exit 0
                ;;
            proton|p)
                _pre
                _proton_prompt
                _show_done
                exit 0
                ;;
            help|-h|--help)
                _help_prompt
                ;;
            *)
                ${ECHO} "${RED}${BOLD} ❌ Unknown argument: ${1:-}${RESET}"
                ${ECHO} "${GREEN} 📝 Usage: $0 help${RESET}"
                ${ECHO} "${GREEN}           $0 [linux|nvidia|mesa|wine|proton]${RESET}"
                exit 1
                ;;
        esac
    fi

    # Interactive mode - show menu and handle user selection
    _pre
    clear
    # shellcheck disable=SC2218  # fzf is not a regular command
    _menu

    # Process user selection from menu
    local choice
    choice=$(< /tmp/tkginstaller_choice)
    rm -f /tmp/tkginstaller_choice

    case $choice in
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
                rm -f "$LOCKFILE"
                exec "$0"
            fi 
            ;;
        Help)
            _help_prompt
            ;;
        Clean)
            _pre
            sleep 1
            ${ECHO} "${YELLOW}${LINE}${BREAK} 🔁 Restarting 🐸 TKG-Installer...${BREAK}${LINE}${RESET}"
            rm -f "$LOCKFILE"
            sleep 2
            clear
            exec "$0" 
            ;;
        Exit)
            _on_exit
            ;;
        *)
            ${ECHO} "${GREEN}${BOLD} ❌ Invalid option: $choice${RESET}"
            ;;
    esac

    _show_done
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Start the main program with all provided arguments
_main "$@"
