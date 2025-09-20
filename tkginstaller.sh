#!/usr/bin/env bash

# =============================================================================
# TKG-Installer 🐸 - Install and configure TKG/Frogminer packages with ease
# =============================================================================
# Author:       damachine (christkue79@gmail.com)
# Maintainer:   DAMACHINE <christkue79@gmail.com>
# Website:      https://github.com/damachine/tkginstaller
# Copyright:    (c) 2025 damachine
# License:      MIT
# Version:      1.0
#
# This software is provided "as is", without warranty of any kind, express or implied.
# I do not guarantee that it will work as intended on your system.
#
# Features:
#   • Supports Linux-TKG, Nvidia-TKG, Mesa-TKG, Wine-TKG, Proton-TKG
#   • Configuration editor and cleanup functions
#   • User-friendly menu with previews
#   • Designed for Arch Linux but adaptable to other distributions
#
# Usage:
#   • Do not run as root. Use a dedicated user for security.
#   • Uses color output and Unicode icons for better readability.
#   • See README.md for further details.
# =============================================================================

# 🔒 Safety settings and strict mode
set -euo pipefail

# 📌 Global paths and configuration
readonly LOCKFILE="/tmp/tkginstaller.lock"
readonly TEMP_DIR="$HOME/.cache/tkginstaller"

# 🎨 Color definitions and formatting
readonly BREAK='\n'
readonly BREAKOPT='\n──────────────────────────────────────────────────────────────────────────────────────────\n'
readonly RESET=$'\033[0m'
readonly BOLD=$'\033[1m'
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[0;33m'
readonly BLUE=$'\033[0;34m'

# 🔒 Prevent concurrent execution
if [[ -f "$LOCKFILE" ]]; then
    echo -e "${RED}${BOLD} ❌ Script is already running. Exiting...${RESET}"
    exit 1
fi
touch "$LOCKFILE"

# 🧑‍💻 Detect Linux Distribution
if [[ -f /etc/os-release ]]; then
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
    trap - INT TERM EXIT HUP
    local code=$?
    
    # Remove lockfile
    rm -f "$LOCKFILE"
    
    # Show abort message on error
    [[ $code -ne 0 ]] && echo -e "${BREAK}${RED}${BOLD} 🎯 Script aborted 🎯${RESET}"

    # Clean temporary files
    rm -rf /tmp/tkginstaller_choice "$TEMP_DIR" 2>/dev/null || true

    # Unset exported preview variables
    unset PREVIEW_LINUX PREVIEW_NVIDIA PREVIEW_MESA PREVIEW_WINE PREVIEW_PROTON
    
    echo -e "${GREEN} 🧹 Cleanup completed.${RESET}"
    exit $code
}
trap _on_exit INT TERM EXIT HUP

# 🧼 Pre-installation checks and preparation
_pre() {
    # Check for root execution
    if [[ "$(id -u)" -eq 0 ]]; then
        echo -e "${RED}${BOLD} ❌ Do not run as root!${RESET}"
        exit 1
    fi

    # Check required dependencies
    local required_commands=(fzf gcc git)
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null; then
            echo -e "${RED}${BOLD} ❌ $cmd is not installed! Please install it first.${RESET}"
            exit 1
        fi
    done

    # Setup temporary directory
    if [[ ! -d "$TEMP_DIR" ]]; then
        echo -e "${GREEN} 🧹 Cleaning old temporary files...${RESET}"
        rm -rf /tmp/tkginstaller_choice "$TEMP_DIR" 2>/dev/null || true
        echo -e "${GREEN} ✅ New temporary directory...${RESET}"
        mkdir -p "$TEMP_DIR"
    fi

    echo -e "${BLUE}${BOLD} 🔁 Starting 🐸 TKG-Installer...${RESET}"

    # Update system (Arch Linux specific)
    if command -v pacman &>/dev/null; then
        echo -e "${BLUE}${BOLD} 🔍 Updating $DISTRO_NAME first...${RESET}"
        sudo pacman -Sy || {
            echo -e "${RED}${BOLD} ❌ Error updating $DISTRO_NAME!${RESET}"
            return 1
        }
    fi
}

# 📝 Dynamic preview content generator for fzf menus
_get_preview_content() {
    local repo_type="$1"
    local repo_url=""
    local static_preview=""
    
    # Define repository URLs and static previews for each TKG package
    case "$repo_type" in
        linux)
            repo_url="https://raw.githubusercontent.com/Frogging-Family/linux-tkg/master/README.md"
            static_preview="Note:\n- Use the configuration editor to customize build options.\n- Ensure you have the necessary build dependencies installed.\n- The installer will clone the repository, build the kernel, and install it.\n- After installation, reboot to use the new kernel.\n\nTips:\n- Run 'tkginstaller linux' to skip menu\n- Join the Frogging-Family community for support and updates.\n\n---\n\n🧠 Linux-TKG\n\nSee full documentation at:\nhttps://github.com/Frogging-Family/linux-tkg/blob/master/README.md"
            ;;
        nvidia)
            repo_url="https://raw.githubusercontent.com/Frogging-Family/nvidia-all/master/README.md"
            static_preview="Note:\n- Supports both open-source and proprietary Nvidia drivers.\n- Use the configuration editor to set driver options and patches.\n- Installer will clone the repo, build and install the driver.\n- Reboot after installation for changes to take effect.\n\nTips:\n- Run 'tkginstaller nvidia' to skip menu\n- Check compatibility with your GPU model.\n- Join the Frogging-Family community for troubleshooting.\n\n---\n\n🎮 Nvidia-TKG\n\nSee full documentation at:\nhttps://github.com/Frogging-Family/nvidia-all/blob/master/README.md"
            ;;
        mesa)
            repo_url="https://raw.githubusercontent.com/Frogging-Family/mesa-git/master/README.md"
            static_preview="Note:\n- Open-source graphics drivers for AMD and Intel GPUs.\n- Use the configuration editor for custom build flags.\n- Installer will clone, build, and install Mesa.\n- Reboot or restart X for changes to apply.\n\nTips:\n- Run 'tkginstaller mesa' to skip menu\n- Useful for gaming and Vulkan support.\n- Join the Frogging-Family community for updates.\n\n---\n\n🧩 Mesa-TKG\n\nSee full documentation at:\nhttps://github.com/Frogging-Family/mesa-git/blob/master/README.md"
            ;;
        wine)
            repo_url="https://raw.githubusercontent.com/Frogging-Family/wine-tkg-git/master/README.md"
            static_preview="Note:\n- Custom Wine builds for better compatibility and gaming performance.\n- Use the configuration editor for patches and tweaks.\n- Installer will clone, build, and install Wine-TKG.\n- Configure your prefix after installation.\n\nTips:\n- Run 'tkginstaller wine' to skip menu\n- Ideal for running Windows games and apps.\n- Join the Frogging-Family community for support.\n\n---\n\n🍷 Wine-TKG\n\nSee full documentation at:\nhttps://github.com/Frogging-Family/wine-tkg-git/blob/master/README.md"
            ;;
        proton)
            repo_url="https://raw.githubusercontent.com/Frogging-Family/wine-tkg-git/master/proton-tkg/README.md"
            static_preview="Note:\n- Custom Proton builds for Steam Play and gaming.\n- Use the configuration editor for tweaks and patches.\n- Installer will clone, build, and install Proton-TKG.\n- Select Proton-TKG in Steam after installation.\n\nTips:\n- Run 'tkginstaller proton' to skip menu\n- Great for running Windows games via Steam.\n- Join the Frogging-Family community for updates.\n\n---\n\n🧪 Proton-TKG\n\nSee full documentation at:\nhttps://github.com/Frogging-Family/wine-tkg-git/blob/master/proton-tkg/README.md"
            ;;
        *)
            echo -e "$static_preview"
            return 1
            ;;
    esac
     
    # Always show static preview first
    echo -e "$static_preview"
       
   # Try to display remote content with available tools (glow > bat > plain text)
    if command -v glow >/dev/null 2>&1; then
        glow "$repo_url" 2>/dev/null
    else
        # Download content (wget oder curl)
        local content=""
        if command -v wget >/dev/null 2>&1; then
            content=$(wget -qO- --timeout=5 "$repo_url" 2>/dev/null)
        elif command -v curl >/dev/null 2>&1; then
            content=$(curl -fsSL --max-time 5 "$repo_url" 2>/dev/null)
        fi

        if [[ -n "$content" ]]; then
            if command -v bat >/dev/null 2>&1; then
                echo "$content" | bat --style=plain --color=always --language=markdown 2>/dev/null
            else
                echo "$content"
            fi
        else
            echo -e "$static_preview"
        fi
    fi
}

# 📝 Export preview content for fzf menu (will be unset in _on_exit)
export PREVIEW_LINUX="$(_get_preview_content linux)"
export PREVIEW_NVIDIA="$(_get_preview_content nvidia)"
export PREVIEW_MESA="$(_get_preview_content mesa)"
export PREVIEW_WINE="$(_get_preview_content wine)"
export PREVIEW_PROTON="$(_get_preview_content proton)"

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
            echo -e "${YELLOW} ⚠️ No editor found: please set \$EDITOR or install 'nano'.${RESET}"
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
    git clone https://github.com/Frogging-Family/linux-tkg.git || {
        echo -e "${RED}${BOLD} ❌ Error cloning: linux-tkg${RESET}"
        return 1
    }
    
    cd linux-tkg
    
    # Display repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-color-palette --no-art
    fi
    
    # Build and install
    makepkg -si || {
        echo -e "${RED}${BOLD} ❌ Error building: linux-tkg${RESET}"
        return 1
    }
}

# 🎮 Nvidia-TKG installation
_nvidia_install() {
    cd "$TEMP_DIR"
    
    # Clone repository
    git clone https://github.com/Frogging-Family/nvidia-all.git || {
        echo -e "${RED}${BOLD} ❌ Error cloning: nvidia-all${RESET}"
        return 1
    }
    
    cd nvidia-all
    
    # Display repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-color-palette --no-art
    fi
    
    # Build and install
    makepkg -si || {
        echo -e "${RED}${BOLD} ❌ Error building: nvidia-all${RESET}"
        return 1
    }
}

# 🧩 Mesa-TKG installation
_mesa_install() {
    cd "$TEMP_DIR"
    
    # Clone repository
    git clone https://github.com/Frogging-Family/mesa-git.git || {
        echo -e "${RED}${BOLD} ❌ Error cloning: mesa-git${RESET}"
        return 1
    }
    
    cd mesa-git
    
    # Display repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-color-palette --no-art
    fi
    
    # Build and install
    makepkg -si || {
        echo -e "${RED}${BOLD} ❌ Error building: mesa-git${RESET}"
        return 1
    }
}

# 🍷 Wine-TKG installation
_wine_install() {
    cd "$TEMP_DIR"
    
    # Clone repository
    git clone https://github.com/Frogging-Family/wine-tkg-git.git || {
        echo -e "${RED}${BOLD} ❌ Error cloning: wine-tkg-git${RESET}"
        return 1
    }
    
    cd wine-tkg-git/wine-tkg-git
    
    # Display repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-color-palette --no-art
    fi
    
    # Build and install
    makepkg -si || {
        echo -e "${RED}${BOLD} ❌ Error building: wine-tkg-git${RESET}"
        return 1
    }
    
    # Optional: Set capabilities for better performance
    # Reference: https://claude.ai/chat/72c16a09-64b5-45ed-93e5-2021ddf88d93
    #sudo setcap cap_sys_nice+ep /opt/wine-tkg-git-opt/bin/wineserver
}

# 🧪 Proton-TKG installation
_proton_install() {
    cd "$TEMP_DIR"
    
    # Clone repository
    git clone https://github.com/Frogging-Family/wine-tkg-git.git || {
        echo -e "${RED}${BOLD} ❌ Error cloning: wine-tkg-git${RESET}"
        return 1
    }
    
    cd wine-tkg-git/proton-tkg
    
    # Display repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        onefetch --no-color-palette --no-art
    fi
    
    # Build Proton-TKG
    ./proton-tkg.sh || {
        echo -e "${RED}${BOLD} ❌ Error building: proton-tkg${RESET}"
        return 1
    }
    
    # Clean up build artifacts
    ./proton-tkg.sh clean || {
        echo -e "${RED}${BOLD} ❌ Nothing to clean: proton-tkg${RESET}"
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
        if [[ ! -d ~/.config/frogminer ]]; then
            echo -e "${RED}${BOLD} ❌ Configuration directory not found! Creating it...${RESET}"
            mkdir -p ~/.config/frogminer || {
                echo -e "${RED}${BOLD} ❌ Error creating configuration directory!${RESET}"
                return 1
            }
        fi
        
        # Interactive configuration file selection with preview
        config_choice=$(
            printf "%b\n" \
                "linux-tkg  |🧠 Linux-TKG .cfg" \
                "nvidia-all |🎮 Nvidia-TKG .cfg" \
                "mesa-git   |🧩 Mesa-TKG .cfg" \
                "wine-tkg   |🍷 Wine-TKG .cfg" \
                "proton-tkg |🧪 Proton-TKG .cfg" \
                "back       |⬅️ Back to Main Menu" \
                | fzf \
                    --prompt="❯ Select a config file 🛠️: " \
                    --header="🐸 TKG Configuration Editor – Select a config..." \
                    --layout=reverse \
                    --height="100%" \
                    --ansi \
                    --delimiter="|" \
                    --with-nth="2" \
                    --preview="bash -c \"
                        key=\$(echo {} | cut -d'|' -f1 | xargs)
                        case \\\$key in
                            linux-tkg)
                                (command -v bat >/dev/null 2>&1 && bat --style=numbers --color=always \"\$HOME/.config/frogminer/linux-tkg.cfg\" 2>/dev/null) || (cat \"\$HOME/.config/frogminer/linux-tkg.cfg\" 2>/dev/null) || true ;;
                            nvidia-all)
                                (command -v bat >/dev/null 2>&1 && bat --style=numbers --color=always \"\$HOME/.config/frogminer/nvidia-all.cfg\" 2>/dev/null) || (cat \"\$HOME/.config/frogminer/nvidia-all.cfg\" 2>/dev/null) || true ;;
                            mesa-git)
                                (command -v bat >/dev/null 2>&1 && bat --style=numbers --color=always \"\$HOME/.config/frogminer/mesa-git.cfg\" 2>/dev/null) || (cat \"\$HOME/.config/frogminer/mesa-git.cfg\" 2>/dev/null) || true ;;
                            wine-tkg)
                                (command -v bat >/dev/null 2>&1 && bat --style=numbers --color=always \"\$HOME/.config/frogminer/wine-tkg.cfg\" 2>/dev/null) || (cat \"\$HOME/.config/frogminer/wine-tkg.cfg\" 2>/dev/null) || true ;;
                            proton-tkg)
                                (command -v bat >/dev/null 2>&1 && bat --style=numbers --color=always \"\$HOME/.config/frogminer/proton-tkg.cfg\" 2>/dev/null) || (cat \"\$HOME/.config/frogminer/proton-tkg.cfg\" 2>/dev/null) || true ;;
                            back)
                                echo \\\"👋 Back to Mainmenu!\\\" ;;
                        esac
                    \"" \
                    --preview-window="right:wrap:60%" \
                    --color="header:italic:bold:underline,prompt:italic:bold:green,pointer:green,marker:red" \
                    --pointer="➤ "
        )
        
        # Handle cancelled selection
        if [[ -z "$config_choice" ]]; then
            echo -e "${RED}${BOLD} ❌ Selection cancelled.${RESET}"
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
                    "$HOME/.config/frogminer/linux-tkg.cfg" \
                    "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/master/customization.cfg"
                ;;
            nvidia-all)
                _handle_config_file \
                    "Nvidia-TKG" \
                    "$HOME/.config/frogminer/nvidia-all.cfg" \
                    "https://raw.githubusercontent.com/Frogging-Family/nvidia-all/master/customization.cfg"
                ;;
            mesa-git)
                _handle_config_file \
                    "Mesa-TKG" \
                    "$HOME/.config/frogminer/mesa-git.cfg" \
                    "https://raw.githubusercontent.com/Frogging-Family/mesa-git/master/customization.cfg"
                ;;
            wine-tkg)
                _handle_config_file \
                    "Wine-TKG" \
                    "$HOME/.config/frogminer/wine-tkg.cfg" \
                    "https://github.com/Frogging-Family/wine-tkg-git/tree/master/wine-tkg-git/customization.cfg"
                ;;
            proton-tkg)
                _handle_config_file \
                    "Proton-TKG" \
                    "$HOME/.config/frogminer/proton-tkg.cfg" \
                    "https://github.com/Frogging-Family/wine-tkg-git/blob/master/proton-tkg/proton-tkg.cfg"
                ;;
            back)       
                return 0
                ;;
            *)          
                echo -e "${RED}${BOLD} ❌ Invalid option: $config_file${RESET}"
                ;;
        esac
    done
}

# 📝 Helper function to handle individual config file editing
_handle_config_file() {
    local config_name="$1"
    local config_path="$2" 
    local config_url="$3"
    
    echo -e "${BLUE} 🔧 Opening $config_name configuration...${RESET}"
    
    if [[ -f "$config_path" ]]; then
        # Edit existing configuration file
        _editor "$config_path" || {
            echo -e "${RED}${BOLD} ❌ Error opening $config_path configuration!${RESET}"
            return 1
        }
    else
        # Download and create new configuration file
        mkdir -p "$(dirname "$config_path")"
        
        if wget -qO "$config_path" "$config_url" 2>/dev/null || curl -fsSL "$config_url" -o "$config_path" 2>/dev/null; then
            echo -e "${GREEN} ✅ Configuration ready at $config_path${RESET}"
            _editor "$config_path" || {
                echo -e "${RED}${BOLD} ❌ Error opening $config_path configuration!${RESET}"
                return 1
            }
        else
            echo -e "${RED}${BOLD} ❌ Error downloading configuration from $config_url${RESET}"
            return 1
        fi
    fi

    echo -e "${GREEN} ✅ Configuration saved!${RESET}"
    sleep 1
}

# =============================================================================
# USER INTERFACE AND INTERACTION
# =============================================================================

# ✅ Display completion status with timestamp
_show_done() {
    local status=$?
    echo -e "${BREAKOPT}"
    echo -e "${BOLD} 📝 Action completed: $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    
    if [ $status -eq 0 ]; then
        echo -e "${GREEN} ✅ Status: Successful${RESET}"
    else
        echo -e "${RED}${BOLD} ❌ Status: Error (Code: $status)${RESET}"
    fi
    
    echo -e "${BREAKOPT}"
}

# =============================================================================
# INSTALLATION PROMPT FUNCTIONS
# =============================================================================

# 📋 Combined Linux + Nvidia installation
_linuxnvidia_promt() {
    _linux_promt
    _nvidia_promt
}

# 🧠 Linux-TKG installation prompt
_linux_promt() {
    echo -e "${GREEN}${BREAKOPT} 🧠 Installing Linux-tkg ⏳${BREAKOPT}${RESET}"
    _linux_install
}

# 🎮 Nvidia-TKG installation prompt
_nvidia_promt() {
    echo -e "${GREEN}${BREAKOPT} 🎮 Installing Nvidia-tkg ⏳${BREAKOPT}${RESET}"
    _nvidia_install
}

# 🧩 Mesa-TKG installation prompt
_mesa_promt() {
    echo -e "${GREEN}${BREAKOPT} 🧩 Installing Mesa-tkg ⏳${BREAKOPT}${RESET}"
    _mesa_install
}

# 🍷 Wine-TKG installation prompt
_wine_promt() {
    echo -e "${GREEN}${BREAKOPT} 🍷 Installing Wine-tkg ⏳${BREAKOPT}${RESET}"
    _wine_install
}

# 🧪 Proton-TKG installation prompt
_proton_promt() {
    echo -e "${GREEN}${BREAKOPT} 🧪 Installing Proton-tkg ⏳${BREAKOPT}${RESET}"
    _proton_install
}

# 🛠️ Configuration editor prompt
_config_promt() {
    if _config_edit; then 
        return 0
    fi
}

# ❓ Help information display
_help_promt() {
    echo -e "${BLUE}Usage: $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p|linuxnvidia|ln|nl|linux+nvidia|config|clean|exit]${RESET}"
    echo -e "${BLUE}Shortcuts: l=linux, n=nvidia, m=mesa, w=wine, p=proton, ln/linux+nvidia=Linux+Nvidia combo${RESET}"
    echo -e "${BLUE}Examples:${RESET}"
    echo -e "  $0 linux           # Install Linux-TKG"
    echo -e "  $0 nvidia          # Install Nvidia-TKG"
    echo -e "  $0 mesa            # Install Mesa-TKG"
    echo -e "  $0 wine            # Install Wine-TKG"
    echo -e "  $0 proton          # Install Proton-TKG"
    echo -e "  $0 linuxnvidia     # Install Linux-TKG + Nvidia-TKG"
    echo -e "  $0 ln              # Install Linux-TKG + Nvidia-TKG"
    echo -e "  $0 linux+nvidia    # Install Linux-TKG + Nvidia-TKG"
    echo -e "  $0 exit            # Exit the installer"
    exit 0
}

# 🎛️ Interactive main menu with fzf preview
_menu() {
    local selection
    
    selection=$(
        printf "%b\n" \
            "Linux        |🧠 Linux-TKG     – Linux Kernel" \
            "Nvidia       |🎮 Nvidia-TKG    – Nvidia Open-Source or proprietary graphics driver" \
            "Linux+Nvidia |💻 Linux+Nvidia  - Combo package: Linux-TKG + Nvidia-TKG" \
            "Mesa         |🧩 Mesa-TKG      – Mesa Open-Source graphics driver for AMD and Intel" \
            "Wine         |🍷 Wine-TKG      – Windows compatibility layer" \
            "Proton       |🧪 Proton-TKG    – Windows compatibility layer for Steam / Gaming" \
            "Config       |🛠️ Config-TKG    – Edit TKG configuration files" \
            "Help         |❓ Help" \
            "Clean        |🧹 Clean/Reset" \
            "Exit         |❌ Exit" \
        | fzf \
            --prompt="❯ Choose an option: " \
            --header="🐸 TKG Frogminer Installation – Select a package..." \
            --layout=reverse \
            --height="100%" \
            --ansi \
            --delimiter="|" \
            --with-nth="2" \
            --preview='case {} in \
                Linux*)     echo -e "🧠 Linux-TKG Preview\n\n$PREVIEW_LINUX";; \
                Nvidia*)    echo -e "🎮 Nvidia-TKG Preview\n\n$PREVIEW_NVIDIA";; \
                Mesa*)      echo -e "🧩 Mesa-TKG Preview\n\n$PREVIEW_MESA";; \
                Wine*)      echo -e "🍷 Wine-TKG Preview\n\n$PREVIEW_WINE";; \
                Proton*)    echo -e "🧪 Proton-TKG Preview\n\n$PREVIEW_PROTON";; \
                Config*)    echo -e "🛠️ Config-TKG\n\nConfigure all TKG packages.\n\nSee documentation at:\nhttps://github.com/damachine/tkginstaller#configuration-menue";; \
                Help*)      echo -e "❓ TKG-Installer\n\nShows all Commandline usage.\n\nSee documentation at:\nhttps://github.com/damachine/tkginstaller#usage";; \
                Clean*)     echo -e "🧹 Clean\n\nRemoves temporary files and resets the installer.\n\nSee documentation at:\nhttps://github.com/damachine/tkginstaller#notes";; \
                Exit*)      echo -e "👋 Exit\n\nExits the program.\n\nSee documentation at:\nhttps://github.com/damachine/tkginstaller\n\nIf you like this program and want to support development, ⭐ visit the project on GitHub!";; \
                *)          echo -e "🐸 TKG-Installer\nhttps://github.com/damachine/tkginstaller";; \
            esac' \
            --preview-window="right:wrap:60%" \
            --color="header:italic:bold:underline:green,prompt:italic:bold:green,pointer:green,marker:red" \
            --pointer="➤ "
    )

    # Handle cancelled selection (ESC pressed)
    if [[ -z "$selection" ]]; then
        echo -e " ${RED}${BOLD} ❌ Selection cancelled.${RESET}"
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
            linuxnvidia|ln|linux+nvidia)
                _pre
                _linuxnvidia_promt
                _show_done
                exit
                ;;
            linux|l)
                _pre
                _linux_promt
                _show_done
                exit
                ;;
            nvidia|n)
                _pre
                _nvidia_promt
                _show_done
                exit
                ;;
            mesa|m)
                _pre
                _mesa_promt
                _show_done
                exit
                ;;
            wine|w)
                _pre
                _wine_promt
                _show_done
                exit
                ;;
            proton|p)
                _pre
                _proton_promt
                _show_done
                exit
                ;;
            help|-h|--help)
                echo -e "${BLUE}Usage: $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p|linuxnvidia|ln|nl|linux+nvidia|config|clean|exit]${RESET}"
                echo -e "${BLUE}Shortcuts: l=linux, n=nvidia, m=mesa, w=wine, p=proton, ln/linux+nvidia=Linux+Nvidia combo${RESET}"
                echo -e "${BLUE}Examples:${RESET}"
                echo -e "  $0 linux           # Install Linux-TKG"
                echo -e "  $0 nvidia          # Install Nvidia-TKG"
                echo -e "  $0 mesa            # Install Mesa-TKG"
                echo -e "  $0 wine            # Install Wine-TKG"
                echo -e "  $0 proton          # Install Proton-TKG"
                echo -e "  $0 linuxnvidia     # Install Linux-TKG + Nvidia-TKG"
                echo -e "  $0 ln              # Install Linux-TKG + Nvidia-TKG"
                echo -e "  $0 linux+nvidia    # Install Linux-TKG + Nvidia-TKG"
                echo -e "  $0 exit            # Exit the installer"
                exit 0
                ;;
            *)        
                echo -e "${RED}${BOLD} ❌ Unknown argument: ${1:-}${RESET}"
                echo -e "${BLUE}Usage: $0 [linux|nvidia|mesa|wine|proton]${RESET}"
                exit 1
                ;;
        esac
    fi

    # Interactive mode - show menu and handle user selection
    _pre
    clear
    _menu

    # Process user selection from menu
    local choice
    choice=$(< /tmp/tkginstaller_choice)
    rm -f /tmp/tkginstaller_choice

    case $choice in
        Linux+Nvidia) 
            _linuxnvidia_promt 
            ;;
        Linux)        
            _linux_promt 
            ;;
        Nvidia)       
            _nvidia_promt 
            ;;
        Mesa)         
            _mesa_promt 
            ;;
        Wine)         
            _wine_promt 
            ;;
        Proton)       
            _proton_promt 
            ;;
        Config)       
            if _config_promt; then 
                rm -f "$LOCKFILE"
                exec "$0"
            fi 
            ;;
        Help)         
            _help_promt 
            ;;
        Clean)        
            _pre
            sleep 1
            echo -e "${BLUE} 🔁 Restarting 🐸 TKG Installer ...${RESET}"
            sleep 1
            rm -f "$LOCKFILE"
            exec "$0" 
            ;;
        Exit)         
            echo -e "${BLUE} 👋 Goodbye!${RESET}"
            exit 0 
            ;;
        *)            
            echo -e "${GREEN}${BOLD} ❌ Invalid option: $choice${RESET}"
            ;;
    esac

    _show_done
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Start the main program with all provided arguments
_main "$@"
