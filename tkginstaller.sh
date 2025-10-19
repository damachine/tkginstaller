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

# Safety settings and strict mode
#set -euo pipefail # Uncomment to enable strict mode (may cause issues with some commands)

# Force standard locale for consistent behavior (sorting, comparisons, messages)
#export LC_ALL=C # Uncomment if locale issues arise

# Fuzzy finder run in a separate shell (subshell) - export variables for fzf
# shellcheck disable=SC2016
# shellcheck disable=SC2218

# TKG-Installer VERSION definition
readonly _tkg_version="v0.14.0"

# Lock file to prevent concurrent execution of the script
readonly _lock_file="/tmp/tkginstaller.lock"

# =============================================================================
# INITIALIZATION FUNCTIONS
# =============================================================================

# Initialize global variables, paths, and configurations
__init_globals() {
    # Global paths and configuration variables
    _tmp_dir="$HOME/.cache/tkginstaller"
    _choice_file="${_tmp_dir}/choice.tmp"
    _config_dir="$HOME/.config/frogminer"
    _tkg_repo_url="https://github.com/damachine/tkginstaller"
    _tkg_raw_url="https://raw.githubusercontent.com/damachine/tkginstaller/refs/heads/master/docs"
    _frog_repo_url="https://github.com/Frogging-Family"
    _frog_raw_url="https://raw.githubusercontent.com/Frogging-Family"

    # Export variables for fzf subshells (unset __exit run)
    export _tmp_dir _choice_file _config_dir _tkg_repo_url _tkg_raw_url _frog_repo_url _frog_raw_url
}

# Initialize color and formatting definitions
__init_colors() {
    # Formatting and color definitions for output
    _print="printf %b\n"
    _break="\n"
    _line="───────────────────────────────────────────────────────────────────────────────────────────────"
    _reset=$"\033[0m"
    _red=$"\033[0;31m"
    _green=$"\033[0;32m"
    _orange=$"\033[0;33m"
    _blue=$"\033[0;34m"

    # Export variables for fzf subshells (unset __exit run)
    export _print _break _line _reset _red _green _orange _blue
}

# =============================================================================
# ENVIRONMENT SETUP
# =============================================================================

# Initialize globals and colors
__init_globals
__init_colors

# Print message in normal formatting
__msg() {
    ${_print} "$*"
}

# Print info message in green
__msg_info() {
    ${_print} "${_green}${_line}${_break} $*${_break}${_line}${_reset}"
}

# Print success message in green
__msg_success() {
    ${_print} "${_green}${_line}${_break} ✅ $*${_break}${_line}${_reset}"
}

# Print warning message in yellow
__msg_warning() {
    ${_print} "${_orange}${_line}${_break} ⚠️ Warning: $*${_break}${_line}${_break}${_reset}"
}

# Print failed message in red
__msg_failed() {
    ${_print} "${_red}${_line}${_break} ❌ Failed: $*${_break}${_line}${_break}${_reset}"
}

# Print error message in red
__msg_error() {
    ${_print} "${_red}${_line}${_break} 🎯 ERROR 🎯 $*${_break}${_line}${_break}${_reset}"
}

# Check for root execution and warn the user
if [[ "$(id -u)" -eq 0 ]]; then
    __msg_warning "You are running as root!"
    read -r -p "Do you really want to continue as root? [y/N]: " allow_root
    echo ""
    if [[ ! "$allow_root" =~ ^(y|Y|yes|Yes|YES)$ ]]; then
        __msg "Aborted. Running as root is not recommended for security reasons."
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
    # Remove exit trap to avoid cleanup during help display
    trap - INT TERM EXIT HUP

    # Display help message
    __msg "${_line}${_break}${_green} 🛈 TKG-Installer Help${_break}${_reset}"
    __msg "${_blue} Run interactive fzf finder menu.${_reset}"
    __msg "${_green} Interactive:${_reset} $0"
    __msg ""
    __msg "${_blue} Run directly without entering the menu.${_reset}"
    __msg "${_green} Syntax:${_reset} $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p]"
    __msg "${_orange} Example:${_reset}"
    __msg "  $0 linux         # Install Linux-TKG"
    __msg "  $0 nvidia        # Install Nvidia-TKG"
    __msg "  $0 mesa          # Install Mesa-TKG"
    __msg "  $0 wine          # Install Wine-TKG"
    __msg "  $0 proton        # Install Proton-TKG"
    __msg ""
    __msg "${_blue} Access configuration files directly without entering the menu.${_reset}"
    __msg "${_green} Syntax:${_reset} $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p] [config|c|edit|e]"
    __msg "${_green}        ${_reset} $0 [config|c|edit|e] [linux|l|nvidia|n|mesa|m|wine|w|proton|p]"
    __msg "${_orange} Example:${_reset}"
    __msg "  $0 linux config  # Edit Linux-TKG config"
    __msg "  $0 config linux  # Edit Linux-TKG config"
    __msg ""
    __msg "${_orange} Shortcuts:${_reset} l=linux, n=nvidia, m=mesa, w=wine, p=proton, c=config, e=edit"
    __msg "${_line}${_reset}"

    # Show help information and exit
    exit 0
}

# Help can show always!
if [[ $# -gt 0 && "${1:-}" =~ ^(help|h|-h|--help)$ ]]; then
    __help
fi

# Prevent concurrent execution (after help check)
if [[ -f "$_lock_file" ]]; then
    # Check if the process is still running
    if [[ -r "$_lock_file" ]]; then
        # Get old PID from lock file and check if process is running
        _old_pid=$(cat "$_lock_file" 2>/dev/null || echo "")
        if [[ -n "$_old_pid" ]] && kill -0 "$_old_pid" 2>/dev/null; then
            ${_print} ""
            __msg_failed "Script is already running (PID: $_old_pid). Exiting..."
            __msg_warning "Remove the lock file manually.${_break}${_break}    ${_reset}${_orange}    tkginstaller clean${_reset}${_break}${_break}${_orange}    If the script was unexpectedly terminated before run:"
            exit 1
        else
            ${_print} ""
            __msg_warning "Removing stale lock file..."
            rm -f "$_lock_file" 2>/dev/null || {
                __msg_failed "Failed to remove stale lock file."
                exit 1
            }
        fi
    fi
fi
echo $$ > "$_lock_file"

# =============================================================================
# CORE UTILITY FUNCTIONS
# =============================================================================

# Cleanup handler for graceful exit
__clean() {
    # Remove temporary files and directories created during execution
    rm -f "$_lock_file" 2>/dev/null || true
    rm -f "$_choice_file" 2>/dev/null || true
    rm -rf "$_tmp_dir" 2>/dev/null || true

    # Unset exported variables
    unset _tmp_dir _choice_file _config_dir _tkg_repo_url _tkg_raw_url _frog_repo_url _frog_raw_url
    unset _print _break _line _reset _red _green _orange _blue
    unset _preview_linux _preview_nvidia _preview_mesa _preview_wine _preview_proton
    unset _preview_config _preview_clean _preview_help _preview_return _preview_exit _glow_style
    unset _distro_name _distro_id _distro_like
 }

# Setup exit trap for cleanup on script termination and errors
__exit() {
    # Get exit code or use passed code
    local _exit_code=${1:-$?}

    # Remove exit trap to avoid recursion
    trap - INT TERM EXIT HUP

    # Message handling on exit based on exit code
    if [[ $_exit_code -ne 0 ]]; then
        __msg_error "TKG-Installer aborted! Exiting..."
    else
        __msg "${_green} 🧹 Cleanup completed!${_reset}"
        __msg "${_green} 👋 TKG-Installer closed!${_reset}"
        __msg "${_green}${_line}${_break}${_reset}"
    fi

    # Perform cleanup
    __clean
    wait
    exit "$_exit_code"
}

# Set exit traps for various termination signals
trap __exit INT TERM EXIT HUP

# Fuzzy finder menu wrapper function
__fzf_menu() {
    # Parameters:
    # $1 = menu content (string with options)
    # $2 = preview command (string)
    # $3 = header text (string)
    # $4 = footer text (string)
    # $5 = border label text (string, optional, default: TKG version)
    # $6 = preview window settings (string, optional, default: right:nowrap:60%)
    # Returns:
    #   Selected menu option from fzf menu
    # Usage:
    #   __fzf_menu "$menu_content" "$preview_command" "$header_text" "$footer_text" "[border_label_text]" "[preview_window_settings]"
    # Example:
    #   selected_option=$(__fzf_menu "$menu_content" "$preview_command" "$header_text" "$footer_text" "Custom Label" "right:nowrap:70%")
    local _menu_content="$1"
    local _preview_command="$2"
    local _header_text="$3"
    local _footer_text="$4"
    local _border_label_text="${5:-$_tkg_version}"
    local _preview_window_settings="${6:-right:nowrap:60%}"

    # Run fzf with provided parameters and predefined settings
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
    # Get status code and duration
    local _status=${1:-$?} # Use passed status, fallback to $? for compatibility
    local _duration="${SECONDS:-0}"
    local _minutes=$((_duration / 60))
    local _seconds=$((_duration % 60))

    # Display completion message
    __msg "${_green}${_line}${_break}${_reset}${_orange} 📝 Action completed: $(date '+%Y-%m-%d %H:%M:%S')${_reset}"

    # Display success or failure status
    if [[ $_status -eq 0 ]]; then
        __msg "${_green} ✅ Status: Successfully${_reset}"
    else
        __msg "${_red} ❌ Status: Failed (Code: $_status)${_reset}"
    fi

    # Display duration
    __msg "${_orange} ⏱️ Duration:${_reset} ${_minutes} min ${_seconds} sec${_reset}"

    # Return status code
    return "$_status"
}

# Pre-installation checks and preparation
__pre() {
    # Parameters:
    # $1 = load preview content (boolean, optional, default: false)
    # Returns:
    #   Performs pre-checks and setup for installation
    # Usage:
    #   __pre true  # Load preview content for interactive mode
    #   __pre false # Skip preview content for direct mode
    # Example:
    #   __pre true
    local _load_preview="${1:-false}"

    # Welcome message and pre-checks
    __msg "${_green}${_line}${_break} 🐸 TKG-Installer ${_tkg_version} for ${_distro_name}${_break}${_line}${_reset}"
    __msg "${_orange} 🔁 Pre-checks starting...${_reset}"

    # Check required dependencies
    local _dep=(git)
    if [[ "$_load_preview" == "true" ]]; then
        _dep+=(bat curl glow fzf)
    fi

    # Define package names per distro
    declare -A _pkg_map_dep=(
        [git]=git
        [bat]=bat
        [curl]=curl
        [glow]=glow
        [fzf]=fzf
    )

    # Set install command je nach Distro
    case "${_distro_id,,}" in
        arch|manjaro|endeavouros|cachyos)
            _install_cmd_dep="pacman -S"
            ;;
        fedora)
            _install_cmd_dep="dnf install"
            ;;
        opensuse*|suse*)
            _install_cmd_dep="zypper install"
            ;;
        gentoo)
            _pkg_map_dep=(
                [git]=dev-vcs/git
                [bat]=app-misc/bat
                [curl]=net-misc/curl
                [glow]=app-text/glow
                [fzf]=app-misc/fzf
            )
            _install_cmd_dep="emerge"
            ;;
        ubuntu|debian|linuxmint|pop|elementary)
            _install_cmd_dep="apt install"
            ;;
        *)
            _install_cmd_dep="your-package-manager install"
            ;;
    esac

    # Check for missing dependencies
    local _missing_dep=()
    for _required_dep in "${_dep[@]}"; do
        if ! command -v "$_required_dep" >/dev/null; then
            _missing_dep+=("$_required_dep")
        fi
    done

    # Exit if any dependencies are missing with installation instructions
    if [[ ${#_missing_dep[@]} -gt 0 ]]; then
        __msg "${_red} ❌ Missing dependencies detected.${_reset}"
        __msg "${_blue}    Please install the following dependencies first:${_break}${_reset}"

        # Map dependencies to package names for installation
        local _pkg_name_dep=()
        for _dependency in "${_missing_dep[@]}"; do
            _pkg_name_dep+=("${_pkg_map_dep[$_dependency]:-$_dependency}")
        done

        # Display installation command with missing packages
        __msg "${_blue}    ${_install_cmd_dep} ${_pkg_name_dep[*]}${_break}${_reset}"
        exit 1
    fi

    # Setup temporary directory and files
    __msg "${_orange} 🧹 Cleaning old temporary files...${_reset}"
    # Remove old temporary files and directories
    rm -rf "$_tmp_dir" "$_choice_file" 2>/dev/null || true
    __msg "${_orange} 🗂️ Create temporary directory...${_reset}"
    # Create necessary subdirectories
    mkdir -p "$_tmp_dir" 2>/dev/null || {
        __msg "${_red} ❌ ERROR: creating temporary directory: ${_tmp_dir}${_reset}"
        return 1
    }

    # Load preview content only for interactive mode
    if [[ "$_load_preview" == "true" ]]; then
        __msg "${_orange} 📡 Retrieving preview content...${_reset}"
        __init_preview || {
            __msg "${_red} ❌ ERROR: initializing preview content.${_reset}"
            return 1
        }
    fi

    # Final message
    __msg "${_green} 🐸 Starting...${_reset}"

    # Short delay for better UX
    wait
    sleep 1
}

# =============================================================================
# PREVIEW FUNCTIONS
# =============================================================================

# Dynamic preview content generator for fzf menus
__get_preview() {
    # Parameters:
    # $1 = preview choice (string)
    # Returns:
    #   Displays preview content using glow command
    # Usage:
    #   __get_preview "linux"  # For Linux-TKG preview
    # Example:
    #   __get_preview "nvidia" # For Nvidia-TKG preview
    local _preview_choice="$1"
    local _frogging_family_preview_url=""
    local _tkg_installer_preview_url=""

    # Define repository URLs and static previews for each TKG package
    case "$_preview_choice" in
        linux)
            _tkg_installer_preview_url="${_tkg_raw_url}/linux.md"
            _frogging_family_preview_url="${_frog_raw_url}/linux-tkg/refs/heads/master/README.md"
            ;;
        nvidia)
            _tkg_installer_preview_url="${_tkg_raw_url}/nvidia.md"
            _frogging_family_preview_url="${_frog_raw_url}/nvidia-all/refs/heads/master/README.md"
            ;;
        mesa)
            _tkg_installer_preview_url="${_tkg_raw_url}/mesa.md"
            _frogging_family_preview_url="${_frog_raw_url}/mesa-git/refs/heads/master/README.md"
            ;;
        wine)
            _tkg_installer_preview_url="${_tkg_raw_url}/wine.md"
            _frogging_family_preview_url="${_frog_raw_url}/wine-tkg-git/refs/heads/master/wine-tkg-git/README.md"
            ;;
        proton)
            _tkg_installer_preview_url="${_tkg_raw_url}/proton.md"
            _frogging_family_preview_url="${_frog_raw_url}/wine-tkg-git/refs/heads/master/proton-tkg/README.md"
            ;;
        config)
            _tkg_installer_preview_url="${_tkg_raw_url}/config.md"
            ;;
        clean)
            _tkg_installer_preview_url="${_tkg_raw_url}/clean.md"
            ;;
        help)
            _tkg_installer_preview_url="${_tkg_raw_url}/help.md"
            ;;
        exit)
            _tkg_installer_preview_url="${_tkg_raw_url}/exit.md"
            ;;
        return)
            _tkg_installer_preview_url="${_tkg_raw_url}/return.md"
            ;;
    esac

    # Glow style detection (auto-detect based on COLORTERM/TERM, or use env override)
    if [[ -z "${_glow_style:-}" ]]; then
        # Detect terminal color scheme
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
        # Display preview content using glow command
        glow --pager --width 80 --style "${_glow_style:-dark}" "$_tkg_installer_preview_url"
    fi

    # Display FROGGING-FAMILY remote preview content
    if [[ -n "$_frogging_family_preview_url" ]]; then
        # Display preview content using glow command
        glow --pager --width 80 --style "${_glow_style:-dark}" "$_frogging_family_preview_url"
    fi
}

# Preview content is initialized only for interactive mode
__init_preview() {
    # Dynamic previews from remote Markdown files using glow command
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

    # Export all preview variables
    export _preview_linux _preview_nvidia _preview_mesa _preview_wine _preview_proton
    export _preview_config _preview_clean _preview_help _preview_return _preview_exit _glow_style
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# Generic package installation helper
__install_package() {
    # Parameters:
    # $1 = repository URL (string)
    # $2 = package name (string)
    # $3 = build command (string)
    # $4 = clean command (string, optional, only for proton-tkg)
    # $5 = working directory (string, optional, relative to cloned repo)
    # Returns:
    #   Clones, builds, and installs the specified package
    # Usage:
    #   __install_package "repo_url" "package_name" "build_command" ["clean_command"] ["work_directory"]
    # Example:
    #   __install_package "https://github.com/username/repo.git" "my_package" "makepkg -si"
    local _repo_url="$1"
    local _package_name="$2"
    local _build_command="$3"
    local _clean_command="${4:-}"  # Optional clean command after build proton-tkg only
    local _work_directory="${5:-}" # Optional working directory relative to cloned repo

    # Navigate to temporary directory
    cd "$_tmp_dir" || return 1

    # Clone repository from provided URL
    git clone "$_repo_url" || {
        __msg_error "Cloning failed for: $_package_name from $_repo_url"
        return 1
    }

    # Navigate to the correct directory (assume it's the cloned repo name)
    local _repo_dir
    _repo_dir=$(basename "$_repo_url" .git)
    cd "$_repo_dir" || return 1

    # Navigate to working directory if specified
    if [[ -n "$_work_directory" ]]; then
        cd "$_work_directory" || {
            __msg_error "Working directory not found: $_work_directory"
            return 1
        }
    fi

    # Fetch git repository information if available
    if command -v onefetch >/dev/null 2>&1; then
        # Display repository information using onefetch
        onefetch --no-bold --no-art --http-url --email --number-of-authors 6 --text-colors 15 3 15 3 15 11 || true
    fi

    # Build and install
    __msg "${_green}${_line}${_break} 🏗️ Cloning, building and installing $_package_name for ${_distro_name}, this may take a while... ⏳${_break}${_line}${_reset}"
    eval "$_build_command" || {
        __msg_error "Building: $_package_name for ${_distro_name} failed!"
        return 1
    }

    # Optional clean up after build (for proton-tkg)
    if [[ -n "$_clean_command" ]]; then
        __msg "${_green}${_line}${_break} 🏗️ Clean up old build artifacts...${_break}${_line}${_reset}"
        eval "$_clean_command" || {
            __msg_info "Nothing to clean: $_package_name"
            sleep 3
        }
    fi

    return 1

}

# Linux-TKG installation
__linux_install() {
    # Determine build command based on distribution
    # Arch-based distributions use makepkg, others use install.sh
    local _build_command

    # Determine build command based on distribution
    if [[ "${_distro_id}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like}" == *"arch"* ]]; then
        # Arch-based distributions
        _build_command="makepkg -si"
    else
        # Non-Arch distributions
        _build_command="chmod +x install.sh && ./install.sh install"
    fi

    # Execute installation process
    __install_package "${_frog_repo_url}/linux-tkg.git" "linux-tkg" "$_build_command"
}

# Nvidia-TKG installation
__nvidia_install() {
    __install_package "${_frog_repo_url}/nvidia-all.git" "nvidia-all" "makepkg -si"
}

# Mesa-TKG installation
__mesa_install() {
    __install_package "${_frog_repo_url}/mesa-git.git" "mesa-git" "makepkg -si"
}

# Wine-TKG installation
__wine_install() {
    # Determine build command based on distribution
    local _build_command

    # Determine build command based on distribution
    if [[ "${_distro_id}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like}" == *"arch"* ]]; then
        # Arch-based distributions
        _build_command="makepkg -si"
    else
        # Non-Arch distributions
        _build_command="chmod +x non-makepkg-build.sh && ./non-makepkg-build.sh"
    fi

    # Set appropriate build command for installation process
    __install_package "${_frog_repo_url}/wine-tkg-git.git" "wine-tkg-git" "$_build_command" "" "wine-tkg-git"
}

# Proton-TKG installation
__proton_install() {
    __install_package "${_frog_repo_url}/wine-tkg-git.git" "wine-tkg-git" "./proton-tkg.sh" "./proton-tkg.sh clean" "proton-tkg"
}

# =============================================================================
# EDITOR MANAGEMENT FUNCTION
# =============================================================================

# Text editor wrapper with fallback support
__editor() {
    # Parameters:
    # $1 = target file to edit (string)
    # Returns:
    #   Opens the specified file in the configured text editor or falls back to nano
    # Usage:
    #   __editor "/path/to/file"
    # Example:
    #   __editor "$HOME/.config/frogminer/linux-tkg.cfg"
    local _target_file="$1"

    # Parse $EDITOR variable (may contain arguments)
    local _editor_raw="${EDITOR-}"
    local _editor_parts=()

    # Split editor command into parts (array) by spaces while respecting quoted arguments
    IFS=' ' read -r -a _editor_parts <<< "$_editor_raw" || true

    # Fallback to nano if no editor configured or not executable
    if [[ -z "${_editor_parts[0]:-}" ]] || ! command -v "${_editor_parts[0]}" >/dev/null 2>&1; then
        if command -v nano >/dev/null 2>&1; then
            # Fallback to nano editor
            _editor_parts=(nano)
        else
            __msg_error "No editor found: Please set \$EDITOR environment or install 'nano' Editor as fallback."
            sleep 2
            return 1
        fi
    fi

    # Execute the editor with the target _target_file as argument
    "${_editor_parts[@]}" "$_target_file"
}

# Configuration file editor with interactive menu
__edit_config() {
    # Parameters:
    #   None
    # Returns:
    #   Opens an interactive menu to select and edit configuration files
    # Usage:
    #   __edit_config
    # Example:
    #   __edit_config
    while true; do
        local _config_choice

        # Ensure configuration directory exists
        if [[ ! -d "${_config_dir}" ]]; then
            __msg_warning "Configuration directory not found: ${_config_dir}"
            # Create the configuration directory if it doesn't exist
            read -r -p "Do you want to create the configuration directory? [y/N]: " create_dir
            echo
            # Handle user response
            case "$create_dir" in
                y|Y|yes|Yes|YES)
                    # Create the configuration directory
                    mkdir -p "${_config_dir}" || {
                        __msg_warning "Error creating configuration directory!"
                        sleep 3
                        clear
                        return 1
                    }
                    __msg_success "Configuration directory created: ${_config_dir}"
                    sleep 3
                    ;;
                *)
                    __msg_warning "Directory creation cancelled. Return to Main menu..."
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
        if [[ "${_distro_id,,}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like,,}" == *"arch"* ]]; then
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

        # Prepare menu content string for fzf menu
        local _menu_content
        _menu_content=$(printf '%s\n' "${_menu_options[@]}")

        # Define common error message for preview
        local _error_config_not_exist="${_red}${_line}${_break} ❌ Error: No external configuration file found.${_break}${_break}${_reset} ⚠️ Click to download missing file${_break}${_red}${_line}${_reset}"

        # Define a reusable bat command for the preview
        local _bat_cmd="bat --style=numbers --language=bash --wrap character --highlight-line 1 --force-colorization"

        # Define preview command for fzf menu
        local _preview_command='
            key=$(echo {} | cut -d"|" -f1 | xargs)
            _config_file_path="'"${_config_dir}"'/${key}.cfg"

            # For wine-tkg, the config file name is different
            if [[ "$key" == "wine-tkg" ]]; then
                _config_file_path="'"${_config_dir}"'/wine-tkg.cfg"
            fi
            
            case $key in
                linux-tkg|nvidia-all|mesa-git|wine-tkg|proton-tkg)
                    '"$_bat_cmd"' "$_config_file_path" 2>/dev/null || '"${_print}"' "'"$_error_config_not_exist"'"
                    ;;
                return)
                    $_print "$_preview_return"
                    ;;
            esac
        '

        # Define header and footer texts for fzf menu
        local _header_text=$'🐸 TKG-Installer ─ Editor menu\n\n   Edit external configuration file\n   Default directory: ~/.config/frogminer/'
        local _footer_text=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\n🐸 Frogging-Family: https://github.com/Frogging-Family\n🌐 About: https://github.com/damachine/tkginstaller'
        local _border_label_text="${_tkg_version}"
        local _preview_window_settings='right:wrap:70%'

        # Show fzf menu and get user selection
        _config_choice=$(__fzf_menu "$_menu_content" "$_preview_command" "$_header_text" "$_footer_text" "$_border_label_text" "$_preview_window_settings")

        # Handle cancelled selection (ESC key) or empty choice
        if [[ -z "$_config_choice" ]]; then
            __msg "${_orange}${_line}${_break} ⏪ Exit editor menu...${_break}${_line}${_reset}"
            sleep 1
            clear
            return 0
        fi

        # Extract selected configuration type and file path
        local _config_file
        _config_file=$(echo "$_config_choice" | cut -d"|" -f1 | xargs)

        # Handle configuration file editing based on selection
        case $_config_file in
            linux-tkg)
                __handle_config \
                    "Linux-TKG" \
                    "${_config_dir}/linux-tkg.cfg" \
                    "${_frog_raw_url}/linux-tkg/master/customization.cfg"
                ;;
            nvidia-all)
                __handle_config \
                    "Nvidia-TKG" \
                    "${_config_dir}/nvidia-all.cfg" \
                    "${_frog_raw_url}/nvidia-all/master/customization.cfg"
                ;;
            mesa-git)
                __handle_config \
                    "Mesa-TKG" \
                    "${_config_dir}/mesa-git.cfg" \
                    "${_frog_raw_url}/mesa-git/master/customization.cfg"
                ;;
            wine-tkg)
                __handle_config \
                    "Wine-TKG" \
                    "${_config_dir}/wine-tkg.cfg" \
                    "${_frog_raw_url}/wine-tkg-git/master/wine-tkg-git/customization.cfg"
                ;;
            proton-tkg)
                __handle_config \
                    "Proton-TKG" \
                    "${_config_dir}/proton-tkg.cfg" \
                    "${_frog_raw_url}/wine-tkg-git/master/proton-tkg/proton-tkg.cfg"
                ;;
            return)
                __msg "${_orange}${_line}${_break} ⏪ Exit editor menu...${_break}${_line}${_reset}"
                sleep 1
                clear
                return 0
                ;;
            *)
                echo ""
                __msg "${_red} ❌ Invalid option: $TKG_CHOICE${_reset}"
                __msg "${_green} Usage:${_reset} $0 help${_reset}"
                __msg "        $0 [linux|nvidia|mesa|wine|proton]${_break}${_reset}"
                return 1
                ;;
        esac
    done
}

# Helper function to handle individual config file editing
__handle_config() {
    # Arguments:
    #   $1 - Configuration name
    #   $2 - Configuration file path
    #   $3 - Configuration file URL
    # Returns:
    #   Opens or downloads and opens the specified configuration file
    # Usage:
    #   __handle_config "Linux-TKG" "/path/to/linux-tkg.cfg" "https://example.com/linux-tkg.cfg"
    # Example:
    #   __handle_config "Linux-TKG" "$HOME/.config/frogminer/linux-tkg.cfg" "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/master/customization.cfg"
    local _config_name="$1"
    local _config_path="$2" 
    local _config_url="$3"

    # Notify user about opening the configuration file
    __msg_success "Opening external $_config_name configuration file..."
    sleep 1
    clear

    # Check if configuration file exists
    if [[ -f "$_config_path" ]]; then
        # Edit existing configuration file
        __editor "$_config_path" || {
            __msg_error "Opening $_config_path configuration!"
            sleep 3
            clear
            return 1
        }
    else
        # Download and create new configuration file
        __msg_warning "External configuration file does not exist: $_config_path"
        # Prompt user for download
        read -r -p "Do you want to download the default configuration from $_config_url? [y/N]: " user_answer
        echo ""
        # Handle user response for downloading the config file
        case "$user_answer" in
            y|Y|yes|Yes|YES)
                # Create the configuration directory if it doesn't exist
                mkdir -p "$(dirname "$_config_path")"
                if curl -fsSL "$_config_url" -o "$_config_path" 2>/dev/null; then
                    __msg_success "External configuration ready at $_config_path"
                    sleep 3
                    clear
                    # Open the downloaded configuration file in the editor
                    __editor "$_config_path" || {
                        __msg_error "Opening external configuration $_config_path"
                        sleep 3
                        clear
                        return 1
                    }
                else
                    # Failed to download configuration file
                    __msg_error "Downloading external configuration from $_config_url"
                    sleep 3
                    clear
                    return 1
                fi
                ;;
            *)
                # User chose not to download the configuration file
                __msg_warning "Download cancelled. No configuration file created.${_break}    Return to Mainmenu..."
                sleep 3
                clear
                return 1
                ;;
        esac

        # Clear screen
        clear
    fi

    # Notify user about closing the configuration file
    __msg_success "Closing external $_config_name configuration file...${_break}    Remember to save your changes!"
    sleep 3
    clear
    return 0
}

# =============================================================================
# PROMPT MENU FUNCTIONS
# =============================================================================

# Linux-TKG installation prompt
__linux_prompt() {
    SECONDS=0
    __msg "${_green}${_line}${_break} 🧠 Fetching Linux-TKG from Frogging-Family repository... ⏳${_break}${_line}${_reset}"
    __linux_install
    __done $?
}

# Nvidia-TKG installation prompt
__nvidia_prompt() {
    SECONDS=0
    __msg "${_green}${_line}${_break} 🖥️ Fetching Nvidia-TKG from Frogging-Family repository... ⏳${_break}${_line}${_reset}"
    __nvidia_install
    __done $?
}

# Mesa-TKG installation prompt
__mesa_prompt() {
    SECONDS=0
    __msg "${_green}${_line}${_break} 🧩 Fetching Mesa-TKG from Frogging-Family repository... ⏳${_break}${_line}${_reset}"
    __mesa_install
    __done $?
}

# Wine-TKG installation prompt
__wine_prompt() {
    SECONDS=0
    __msg "${_green}${_line}${_break} 🍷 Fetching Wine-TKG from Frogging-Family repository... ⏳${_break}${_line}${_reset}"
    __wine_install
    __done $?
}

# Proton-TKG installation prompt
__proton_prompt() {
    SECONDS=0
    __msg "${_green}${_line}${_break} 🎮 Fetching Proton-TKG from Frogging-Family repository... ⏳${_break}${_line}${_reset}"
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
    # Define menu options and preview commands for fzf menu
    local _menu_options=(
        "Linux  |🧠 Linux   ─ Linux-TKG custom kernels"
    )

    # Only show Nvidia and Mesa options if Arch-based
    if [[ "${_distro_id,,}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like,,}" == *"arch"* ]]; then
        _menu_options+=(
            "Nvidia |🖥️ Nvidia  ─ Nvidia Open-Source or proprietary graphics driver"
            "Mesa   |🧩 Mesa    ─ Open-Source graphics driver for AMD and Intel"
        )
    fi

    # Always show Wine, Proton, Config, and Clean options
    _menu_options+=(
        "Wine   |🍷 Wine    ─ Windows compatibility layer"
        "Proton |🎮 Proton  ─ Windows compatibility layer for Steam / Gaming"
        "Config |🛠️ Config  ─ Edit external TKG configuration files"
        "Clean  |🧹 Clean   ─ Clean downloaded files"
        "Help   |❓ Help    ─ Shows all commands"
        "Exit   |❌ Exit"
    )

    # Prepare menu content for fzf menu
    local _menu_content
    _menu_content=$(printf '%s\n' "${_menu_options[@]}")

    # Define preview command for fzf menu with dynamic content based on selection
    local _preview_command='
        key=$(echo {} | cut -d"|" -f1 | xargs)
        case $key in
            Linux*) $_print "$_preview_linux" ;;
            Nvidia*)
                if [[ "${_distro_id,,}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like,,}" == *"arch"* ]]; then
                    $_print "$_preview_nvidia"
                else
                    $_print "${_red} ❌ Nvidia-TKG is only available for Arch-based distributions.${_reset}"
                fi
                ;;
            Mesa*)
                if [[ "${_distro_id,,}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like,,}" == *"arch"* ]]; then
                    $_print "$_preview_mesa"
                else
                    $_print "${_red} ❌ Mesa-TKG is only available for Arch-based distributions.${_reset}"
                fi
                ;;
            Wine*) $_print "$_preview_wine" ;;
            Proton*) $_print "$_preview_proton" ;;
            Config*) $_print "$_preview_config" ;;
            Clean*) $_print "$_preview_clean" ;;
            Help*) $_print "$_preview_help" ;;
            Exit*) $_print "$_preview_exit" ;;
        esac
    '

    # Define header and footer texts for fzf menu
    local _header_text=$'🐸 TKG-Installer\n\n🏗️ Easily build the TKG packages from the Frogging-Family repositories.'
    local _footer_text=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\n🐸 Frogging-Family: https://github.com/Frogging-Family\n🌐 About: https://github.com/damachine/tkginstaller'
    local _border_label_text="${_tkg_version}"
    local _preview_window_settings='right:wrap:60%'

    # Show fzf menu and get user selection
    local _main_choice
    _main_choice=$(__fzf_menu "$_menu_content" "$_preview_command" "$_header_text" "$_footer_text" "$_border_label_text" "$_preview_window_settings")

    # Handle cancelled selection (ESC pressed)
    if [[ -z "${_main_choice:-}" ]]; then
        __msg "${_orange}${_line}${_break} 👋 Exit TKG-Installer...${_break}${_line}${_reset}"
        sleep 1
        clear
        __exit 0
    fi

    # Save selection to temporary file for processing
    echo "$_main_choice" | cut -d"|" -f1 | xargs > "$_choice_file"
}

# =============================================================================
# MAIN PROGRAM ENTRY POINT
# =============================================================================

# Handle direct command-line arguments for quick execution
__main_direct_mode() {
    # Parameters:
    # $1 = first argument (string)
    # $2 = second argument (string, optional)
    # Returns:
    #   Processes command-line arguments for direct installation or config editing
    # Usage:
    #   __main_direct_mode "linux" "config"
    # Example:
    #   __main_direct_mode "nvidia" "edit"
    local _arg1="${1,,}"  # Convert to lowercase
    local _arg2="${2,,}"  # Convert to lowercase

    # Accept both [package] [config] and [config] [package] order
    local _package=""
    local _config_arg=""

    # Check for config argument in either position and set package accordingly
    if [[ "$_arg1" =~ ^(config|c|edit|e)$ ]]; then
        # Set config argument
        _config_arg="$_arg1"
        # Set package argument
        case "$_arg2" in
            linux|l|--linux|-l) _package="linux-tkg" ;;
            nvidia|n|--nvidia|-n) _package="nvidia-all" ;;
            mesa|m|--mesa|-m) _package="mesa-git" ;;
            wine|w|--wine|-w) _package="wine-tkg" ;;
            proton|p|--proton|-p) _package="proton-tkg" ;;
        esac
    elif [[ "$_arg2" =~ ^(config|c|edit|e)$ ]]; then
        # Set config argument
        _config_arg="$_arg2"
        # Set package argument
        case "$_arg1" in
            linux|l|--linux|-l) _package="linux-tkg" ;;
            nvidia|n|--nvidia|-n) _package="nvidia-all" ;;
            mesa|m|--mesa|-m) _package="mesa-git" ;;
            wine|w|--wine|-w) _package="wine-tkg" ;;
            proton|p|--proton|-p) _package="proton-tkg" ;;
        esac
    fi

    # If both package and config argument are set, handle config editing directly
    if [[ -n "$_package" && -n "$_config_arg" ]]; then
        # Determine config file path and URL based on package type
        local _config_path="${_config_dir}/${_package}.cfg"
        local _config_url=""
        local _config_name=""

        case "$_package" in
            linux-tkg)
                _config_name="Linux-TKG"
                _config_url="${_frog_raw_url}/linux-tkg/master/customization.cfg"
                ;;
            nvidia-all)
                _config_name="Nvidia-TKG"
                _config_url="${_frog_raw_url}/nvidia-all/master/customization.cfg"
                ;;
            mesa-git)
                _config_name="Mesa-TKG"
                _config_url="${_frog_raw_url}/mesa-git/master/customization.cfg"
                ;;
            wine-tkg)
                _config_name="Wine-TKG"
                _config_url="${_frog_raw_url}/wine-tkg-git/master/wine-tkg-git/customization.cfg"
                ;;
            proton-tkg)
                _config_name="Proton-TKG"
                _config_url="${_frog_raw_url}/wine-tkg-git/master/proton-tkg/proton-tkg.cfg"
                ;;
        esac

        # Disable exit trap before handling config 
        trap - INT TERM EXIT HUP

        # Handle config file
        __handle_config "$_config_name" "$_config_path" "$_config_url"

        # Display exit messages
        __msg "${_orange}${_line}${_break} 🧹 Cleanup completed!"
        __msg "👋 TKG-Installer closed!"
        __msg "${_line}"
        __msg "${_break}"

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
            # Clean temporary files and restart
            __msg "${_orange}${_line}${_break} 🧹 Cleaning temporary files...${_break}${_line}${_reset}"
            __pre >/dev/null 2>&1 || true
            rm -f "$_lock_file" 2>&1 || true
            sleep 1
            clear
            ;;
        help|h|--help|-h)
            __help

            ;;
        *)
            # Invalid argument handling and usage instructions display
            __msg "${_line}${_break}${_red} ❌ Invalid argument: ${1:-}${_reset}"
            __msg "${_orange}    The argument is either invalid or incomplete.${_break}${_reset}"
            __msg "${_blue} Run interactive fzf finder menu.${_reset}"
            __msg "${_green} Interactive:${_reset} $0"
            __msg ""
            __msg "${_blue} Run directly without entering the menu.${_reset}"
            __msg "${_green} Syntax:${_reset} $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p]"
            __msg ""
            __msg "${_orange} Example:${_reset}"
            __msg "  $0 linux         # Install Linux-TKG"
            __msg "  $0 nvidia        # Install Nvidia-TKG"
            __msg "  $0 mesa          # Install Mesa-TKG"
            __msg "  $0 wine          # Install Wine-TKG"
            __msg "  $0 proton        # Install Proton-TKG"
            __msg ""
            __msg "${_blue} Access configuration files directly without entering the menu.${_reset}"
            __msg "${_green} Syntax:${_reset} $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p] [config|c|edit|e]"
            __msg "${_green}        ${_reset} $0 [config|c|edit|e] [linux|l|nvidia|n|mesa|m|wine|w|proton|p]"
            __msg "${_orange} Example:${_reset}"
            __msg "  $0 linux config  # Edit Linux-TKG config"
            __msg "  $0 config linux  # Edit Linux-TKG config"
            __msg ""
            __msg "${_orange} Shortcuts:${_reset} l=linux, n=nvidia, m=mesa, w=wine, p=proton, c=config, e=edit"
            __msg "${_line}${_reset}"

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

    # Show the main menu
    __menu

    # Process user selection from menu
    local _user_choice
    _user_choice=$(< "$_choice_file")

    # Remove temporary choice file
    rm -f "$_choice_file"

    # Handle user choice from menu
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
            # Remove temporary choice file
            rm -f "$_lock_file"
            # Restart the script after editing config
            clear
            exec "$0"
            ;;
        Help)
            __help
            ;;
        Clean)
            # Clean temporary files and restart script
            __msg "${_orange}${_line}${_break} 🧹 Cleaning temporary files...${_break} 🔁 Restarting...${_break}${_line}${_reset}"      
            __pre >/dev/null 2>&1 || true
            rm -f "$_lock_file" 2>&1 || true
            sleep 1
            clear
            exec "$0" 
            ;;
        Exit)
            # Exit the script gracefully
            __msg "${_orange}${_line}${_break} 👋 Exit TKG-Installer...${_break}${_line}${_reset}"
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
        # Direct mode - bypass menu and execute commands
        __main_direct_mode "$@"
    else
        # Interactive mode - show menu and handle user selection
        __main_interactive_mode
    fi
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Start the main program with all provided arguments
__main "$@"
