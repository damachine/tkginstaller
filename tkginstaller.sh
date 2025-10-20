#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# author : damachine (christkue79@gmail.com)
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

# Safety settings and strict mode (optional)
#set -euo pipefail # Uncomment to enable strict error handling

# Force standard locale for consistent behavior (sorting, comparisons, messages)
#export LC_ALL=C # Uncomment if locale issues arise

# Fuzzy finder run in a separate shell (subshell) - export variables for fzf subshells
# shellcheck disable=SC2016
# shellcheck disable=SC2218

# TKG-Installer VERSION definition
_tkg_version="v0.14.6"

# Lock file to prevent concurrent execution of the script
_lock_file="/tmp/tkginstaller.lock"

# =============================================================================
# ENVIRONMENT SETUP
# =============================================================================

# Initialize global variables, paths, and configurations for the script
__init_globals() {
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

# Initialize color and formatting definitions for output messages and prompts
__init_colors() {
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
# INITIALIZATION AND PRE-CHECKS
# =============================================================================

# Initialize globals and colors for script execution
__init_globals
__init_colors

# Print message in normal formatting
__msg() {
    ${_print} "$*${_reset}"
}

# Print success message in green
__msg_success() {
    ${_print} "${_green}$*${_reset}"
}

# Print info message in green
__msg_info() {
    ${_print} "${_orange}$*${_reset}"
}

# Print info message in orange with [INFO] tag
__msg_info2() {
    ${_print} "${_orange}[INFO]: $*${_reset}"
}

# Print warning message in yellow with [WARNING] tag
__msg_warning() {
    ${_print} "${_orange}[WARNING]: $*${_reset}"
}

# Print error message in red with [ERROR] tag
__msg_error() {
    ${_print} "${_red}[ERROR]: $*${_reset}"
}

# Check for root execution and warn the user (if running as root)
if [[ "$(id -u)" -eq 0 ]]; then
    __msg "${_break}${_orange}${_line}"
    __msg_warning "You are running as root!"
    __msg "${_orange}           This is not recommended."
    __msg ""
    echo -en "${_red} Do you really want to continue as root? [y/N]: ${_reset}"
    read -r allow_root
    if [[ ! "$allow_root" =~ ^(y|Y|yes|Yes|YES)$ ]]; then
        __msg ""
        __msg_info2 "Aborted. Exiting..."
        __msg "${_orange}${_line}"
        exit 1
    fi
    __msg "${_orange}${_line}${_break}"
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
    # Display help information with usage examples and shortcuts
    __msg "${_break}${_line}"
    __msg "${_green}TKG-Installer Help"
    __msg ""
    __msg "${_blue}Run interactive fzf finder menu."
    __msg "${_green}Interactive run:${_reset} $0"
    __msg ""
    __msg "${_blue}Run directly without entering the menu."
    __msg "${_green}Direct syntax:${_reset} $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p]"
    __msg "${_orange}Example:${_reset}"
    __msg " $0 linux    # Install Linux-TKG"
    __msg " $0 l        # Install Linux-TKG (shortcut)"
    __msg " $0 nvidia   # Install Nvidia-TKG"
    __msg " $0 mesa     # Install Mesa-TKG"
    __msg " $0 wine     # Install Wine-TKG"
    __msg " $0 proton   # Install Proton-TKG"
    __msg ""
    __msg "${_blue}Access configuration files directly without entering the menu.${_reset}"
    __msg "${_green}Direct syntax:${_reset} $0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p] [config|c|edit|e]"
    __msg "${_green}              ${_reset} $0 [config|c|edit|e] [linux|l|nvidia|n|mesa|m|wine|w|proton|p]"
    __msg "${_orange}Example:${_reset}"
    __msg " $0 linux config  # Edit Linux-TKG config"
    __msg " $0 l c           # Edit Linux-TKG config (shortcut)"
    __msg " $0 config linux  # Edit Linux-TKG config (alternate syntax)"
    __msg ""
    __msg "${_orange}Shortcuts:${_reset} l=linux, n=nvidia, m=mesa, w=wine, p=proton, c=config, e=edit"
    __msg "${_line}${_break}"
}

# Help can show always!
if [[ $# -gt 0 && "${1:-}" =~ ^(help|h|--help|-h)$ ]]; then
    __help
    trap - INT TERM EXIT HUP
    exit 0
fi

# Prevent concurrent execution (after help check)
if [[ -f "$_lock_file" ]]; then
    # Check if the process is still running
    if [[ -r "$_lock_file" ]]; then
        # Get old PID from lock file and check if process is running
        _old_pid=$(cat "$_lock_file" 2>/dev/null || echo "")
        if [[ -n "$_old_pid" ]] && kill -0 "$_old_pid" 2>/dev/null; then
            __msg "${_break}${_orange}${_line}"
            __msg_warning "Script is already running (PID: $_old_pid). Exiting..."
            __msg ""
            __msg_info2 "If the script was unexpectedly terminated before."
            __msg_info "        Remove $_lock_file manually run:"
            __msg ""
            __msg "${_red}        >>>${_reset}     tkginstaller clean     ${_red}<<<"
            __msg ""
            __msg "${_orange}${_line}${_break}"
            exit 1
        else
            rm -f "$_lock_file" 2>/dev/null || {
                __msg "${_break}${_orange}${_line}"
                __msg_warning "Script is already running (PID: $_old_pid). Exiting..."
                __msg ""
                __msg_info2 "If the script was unexpectedly terminated before."
                __msg_info "        Remove $_lock_file manually run:"
                __msg ""
                __msg "${_red}        >>>${_reset}     tkginstaller clean     ${_red}<<<"
                __msg ""
                __msg "${_orange}${_line}${_break}"
                exit 1
            }
        fi
    fi
fi
echo $$ > "$_lock_file"

# =============================================================================
# CORE UTILITY FUNCTIONS
# =============================================================================

# Pre-installation checks and preparation 
__prepare() {
    # Parameters:
    #   $1 = load preview content (boolean, optional, default: false)
    # Returns:
    #   Performs pre-checks and setup for installation process
    # Usage:
    #   __prepare true  # Load preview content for interactive mode
    #   __prepare false # Skip preview content for direct mode
    # Example:
    #   __prepare true
    local _load_preview="${1:-false}" # Default to false if not provided (for direct mode)

    # Welcome message and pre-checks
    __msg_success "${_break}${_line}${_break}TKG-Installer ${_tkg_version} for ${_distro_name}${_break}${_line}"
    __msg_info "Preparation..."

    # Check required dependencies based on mode (interactive/direct)
    local _dep=(git)
    if [[ "$_load_preview" == "true" ]]; then
        # Add optional dependencies for interactive mode
        _dep+=(bat curl glow fzf onefetch)
    fi

    # Define package names per distro for missing dependencies installation mapping
    declare -A _pkg_map_dep=(
        [git]=git
        [bat]=bat
        [curl]=curl
        [glow]=glow
        [fzf]=fzf
    )

    # Set install command based on detected Linux distribution
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

    # Check for missing dependencies and collect them for installation instructions
    local _missing_dep=() # Array to hold missing dependencies
    for _required_dep in "${_dep[@]}"; do
        if ! command -v "$_required_dep" >/dev/null; then
            _missing_dep+=("$_required_dep")
        fi
    done

    # Exit if any dependencies are missing with installation instructions
    if [[ ${#_missing_dep[@]} -gt 0 ]]; then
        __msg_error "Missing dependencies detected."
        __msg_info "         Please install the following dependencies first:"
        __msg ""

        # Map dependencies to package names for installation command display
        local _pkg_name_dep=()
        for _dependency in "${_missing_dep[@]}"; do
            _pkg_name_dep+=("${_pkg_map_dep[$_dependency]:-$_dependency}")
        done

        # Display installation command with missing packages
        __msg_info "${_red}         >>> ${_reset}${_install_cmd_dep} ${_pkg_name_dep[*]}${_red} <<<"
        exit 1
    fi

    # Setup temporary directory and files for installation process
    __msg_info "Cleaning old temporary files..."
    # Remove old temporary files and directories if they exist
    rm -rf "$_tmp_dir" "$_choice_file" 2>/dev/null || true
    __msg_info "Creating temporary directory..."
    # Create necessary subdirectories for temporary files
    mkdir -p "$_tmp_dir" 2>/dev/null || {
        __msg_error "Creating temporary directory failed: ${_tmp_dir}"
        return 1
    }

    # Load preview content only for interactive mode (if requested)
    if [[ "$_load_preview" == "true" ]]; then
        __msg_info "Retrieving preview content..."
        __init_preview || {
            __msg_error "Initializing preview content failed..."
            return 1
        }
    fi

    # Final message before starting TKG-Installer process
    if [[ "$_load_preview" == "true" ]]; then
        __msg "$_green${_line}"
        __msg_success "Preparation done!"
        __msg_success "Entering interactive menu..."
        __msg "$_green${_line}"
    else
        __msg_success "Preparation done!"
        __msg_success "Starting direct installation..."
    fi

    # Short delay for better UX
    wait
    sleep 3
}

# Display completion status with timestamp and duration of the action performed
__done() {
    local _status=${1:-$?} # Use passed status, fallback to $? for compatibility
    local _duration="${SECONDS:-0}" # Total duration in seconds (since script start)
    local _minutes=$((_duration / 60)) # Calculate minutes part
    local _seconds=$((_duration % 60)) # Calculate remaining seconds part

    # Finalizing message display
    __msg "${_orange}${_line}"

    # Display completion message with timestamp
    __msg_info "Action completed: $(date '+%Y-%m-%d %H:%M:%S')"

    # Display success or failure status based on exit code
    if [[ $_status -eq 0 ]]; then
        __msg_success "Status: Successfully completed!"
    else
        __msg_error "Failed process (Code: $_status)"
    fi

    # Display duration message with minutes and seconds
    __msg_info "Duration: ${_minutes} min ${_seconds} sec"

    __msg "${_orange}${_line}"

    # Return status code
    return "$_status"
}

# Setup exit trap for cleanup on script termination and errors
__exit() {
    # Get exit code or use passed code
    local _exit_code=${1:-$?}

    # Remove exit trap to avoid recursion during cleanup
    trap - INT TERM EXIT HUP

    # Message handling on exit based on exit code (0=success, non-0=failure)
    if [[ $_exit_code -ne 0 ]]; then
        __msg "${_break}${_red}${_line}${_break}TKG-Installer aborted! Exiting...${_break}${_line}${_break}"
    else
        __msg "${_break}${_green}${_line}${_break}TKG-Installer closed! Goodbye!${_break}${_line}${_break}"
    fi

    # Perform cleanup
    __clean
    wait
    exit "$_exit_code"
}

# Set exit traps for various termination signals to ensure cleanup
trap __exit INT TERM EXIT HUP

# Cleanup handler for graceful exit and resource management
__clean() {
    # Remove temporary files and directories created during execution
    rm -f "$_lock_file" 2>/dev/null || true # Remove lock file
    rm -f "$_choice_file" 2>/dev/null || true # Remove temporary choice file
    rm -rf "$_tmp_dir" 2>/dev/null || true # Remove temporary directory

    # Unset exported variables for fzf subshells
    unset _tmp_dir _choice_file _config_dir _tkg_repo_url _tkg_raw_url _frog_repo_url _frog_raw_url
    unset _print _break _line _reset _red _green _orange _blue
    unset _preview_linux _preview_nvidia _preview_mesa _preview_wine _preview_proton
    unset _preview_config _preview_clean _preview_help _preview_return _preview_exit _glow_style
    unset _distro_name _distro_id _distro_like
 }

# Fuzzy finder menu wrapper function for consistent settings and usage
__fzf_menu() {
    # Parameters:
    #   $1 = menu content (string with options)
    #   $2 = preview command (string)
    #   $3 = header text (string)
    #   $4 = footer text (string)
    #   $5 = border label text (string, optional, default: TKG version)
    #   $6 = preview window settings (string, optional, default: right:nowrap:60%)
    # Returns:
    #   Selected menu option from fzf menu (run in subshell)
    # Usage:
    #   __fzf_menu "$menu_content" "$preview_command" "$header_text" "$footer_text" "[border_label_text]" "[preview_window_settings]"
    # Example:
    #   selected_option=$(__fzf_menu "$menu_content" "$preview_command" "$header_text" "$footer_text" "Custom Label" "right:nowrap:70%")
    local _menu_content="$1" # Menu options content (string)
    local _preview_command="$2" # Preview command (string)
    local _header_text="$3" # Header text (string)
    local _footer_text="$4" # Footer text (string)
    local _border_label_text="${5:-$_tkg_version}" # Border label text (string, optional)
    local _preview_window_settings="${6:-right:nowrap:60%}" # Preview window settings (string, optional)

    # Run fzf with provided parameters and predefined settings
    fzf \
        --with-shell='bash -c' \
        --style default \
        --color='header:#00ff00,pointer:#00ff00,marker:#00ff00' \
        --border=none \
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
        --pointer='>' \
        --header="${_header_text}" \
        --header-border=line \
        --header-label="${_border_label_text}" \
        --header-label-pos=1024 \
        --header-first \
        --footer="${_footer_text}" \
        --footer-border=line \
        --preview-window="${_preview_window_settings}" \
        --preview="${_preview_command}" \
        --preview-border=line \
        --disabled \
        <<< "${_menu_content}"
}

# =============================================================================
# PREVIEW FUNCTIONS
# =============================================================================

# Dynamic preview content generator for fzf menus using glow command
__get_preview() {
    # Parameters:
    #   $1 = preview choice (string)
    # Returns:
    #   Displays preview content using glow command based on choice provided
    # Usage:
    #   __get_preview "linux"  # For Linux-TKG preview
    # Example:
    #   __get_preview "nvidia" # For Nvidia-TKG preview
    local _preview_choice="$1" # Preview choice (string)
    local _frogging_family_preview_url="" # Frogging-Family preview URL
    local _tkg_installer_preview_url="" # TKG-Installer preview URL

    # Define repository URLs and static previews for each TKG package and action type
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
        # Detect terminal color scheme for glow style (auto)
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
        # Display preview content using glow command for TKG-Installer docs
        glow --pager --width 80 --style "${_glow_style:-dark}" "$_tkg_installer_preview_url"
    fi

    # Display FROGGING-FAMILY remote preview content
    if [[ -n "$_frogging_family_preview_url" ]]; then
        # Display preview content using glow command for Frogging-Family repos (TKG packages)
        glow --pager --width 80 --style "${_glow_style:-dark}" "$_frogging_family_preview_url"
    fi
}

# Preview content is initialized only for interactive mode (using glow command)
__init_preview() {
    # Dynamic previews from remote Markdown files using glow command for fzf menus
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

    # Export all preview variables for fzf subshells (unset __exit run)
    export _preview_linux _preview_nvidia _preview_mesa _preview_wine _preview_proton
    export _preview_config _preview_clean _preview_help _preview_return _preview_exit _glow_style
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# Generic package installation helper function for TKG packages from Frogging-Family repos
__install_package() {
    # Parameters:
    #   $1 = repository URL (string)
    #   $2 = package name (string)
    #   $3 = build command (string)
    #   $4 = clean command (string, optional, only for proton-tkg)
    #   $5 = working directory (string, optional, relative to cloned repo)
    # Returns:
    #   Clones, builds, and installs the specified package from the provided repository URL
    # Usage:
    #   __install_package "repo_url" "package_name" "build_command" ["clean_command"] ["work_directory"]
    # Example:
    #   __install_package "https://github.com/username/repo.git" "my_package" "makepkg -si" "makepkg -C" "subdir"
    local _repo_url="$1" # Repository URL (string)
    local _package_name="$2" # Package name (string)
    local _build_command="$3" # Build command (string)
    local _clean_command="${4:-}"  # Optional clean command after build proton-tkg only (string)
    local _work_directory="${5:-}" # Optional working directory relative to cloned repo (string)

    # Navigate to temporary directory for cloning and building process
    cd "$_tmp_dir" > /dev/null 2>&1 || return 1

    # Clone repository from provided URL
    git clone "$_repo_url" > /dev/null 2>&1 || {
        __msg "${_break}${_red}${_line}"
        __msg_error "Cloning failed for: $_package_name @ $_repo_url"
        __msg "${_red}${_line}${_break}"
        return 1
    }

    # Navigate to the correct directory (assume it's the cloned repo name)
    local _repo_dir
    _repo_dir=$(basename "$_repo_url" .git)
    cd "$_repo_dir" > /dev/null 2>&1 || return 1

    # Navigate to working directory if specified (for proton-tkg)
    if [[ -n "$_work_directory" ]]; then
        cd "$_work_directory" > /dev/null 2>&1 || {
            __msg "${_break}${_red}${_line}"
            __msg_error "Working directory not found: $_work_directory"
            __msg "${_red}${_line}${_break}"
            return 1
        }
    fi

    # Fetch git repository information if available (using onefetch if installed)
    if command -v onefetch >/dev/null 2>&1; then
        # Display git repository information using onefetch tool
        onefetch --no-title --no-bold --no-art --http-url --email --number-of-authors 6 --text-colors 15 3 15 3 15 11 || true
    fi

    # Build and install the package using the provided build command
    __msg_info "${_line}${_break}Cloning, building and installing $_package_name for $_distro_name, this may take a while...${_break}${_line}"
    eval "$_build_command" || {
        __msg "${_break}${_red}${_line}"
        __msg_error "Building failed: $_package_name for $_distro_name failed!"
        __msg "${_red}${_line}${_break}"
        return 1
    }

    # Optional clean up after build (for proton-tkg) if clean command provided
    if [[ -n "$_clean_command" ]]; then
        __msg_info "${_line}${_break}Clean up old build artifacts...${_break}${_line}"
        eval "$_clean_command" || {
            __msg_info "Nothing to clean: $_package_name"
            sleep 3
        }
    fi
}

# Linux-TKG installation
__linux_install() {
    # Determine build command based on distribution
    # Arch-based distributions use makepkg, others use install.sh
    local _build_command # Build command variable

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

# Text editor wrapper with fallback support to nano editor
__editor() {
    # Parameters:
    #   1 = target file to edit (string)
    # Returns:
    #   Opens the specified file in the configured text editor or falls back to nano if none is set or executable
    # Usage:
    #   __editor "/path/to/file"
    # Example:
    #   __editor "$HOME/.config/frogminer/linux-tkg.cfg"
    local _target_file="$1" # Target file to edit (string)

    # Parse $EDITOR variable (may contain arguments)
    local _editor_raw="${EDITOR-}" # Raw editor command from environment variable (string)
    local _editor_parts=() # Array to hold parsed editor command parts (array)

    # Split editor command into parts (array) by spaces while respecting quoted arguments
    IFS=' ' read -r -a _editor_parts <<< "$_editor_raw" || true

    # Fallback to nano if no editor configured or not executable
    if [[ -z "${_editor_parts[0]:-}" ]] || ! command -v "${_editor_parts[0]}" >/dev/null 2>&1; then
        if command -v nano >/dev/null 2>&1; then
            # Fallback to nano editor
            _editor_parts=(nano)
        else
            __msg "${_break}${_red}${_line}"
            __msg_error "No editor found: Please set \$EDITOR environment or install 'nano' Editor as fallback."
            __msg "${_red}${_line}${_break}"
            sleep 2
            return 1
        fi
    fi

    # Execute the editor with the target _target_file as argument
    "${_editor_parts[@]}" "$_target_file"
}

# Configuration file editor with interactive menu using fzf finder
__edit_config() {
    # Parameters:
    #   None
    # Returns:
    #   Opens an interactive menu to select and edit configuration files using fzf finder and the configured text editor
    # Usage:
    #   __edit_config
    # Example:
    #   __edit_config
    while true; do
        local _config_choice # User's configuration choice (string)

        # Ensure configuration directory exists
        if [[ ! -d "${_config_dir}" ]]; then
            __msg "${_break}${_orange}${_line}"
            __msg_warning "Configuration directory not found."
            __msg "${_blue}           Folder path: ${_config_dir}"
            __msg "${_orange}${_line}${_break}"
            # Create the configuration directory if it doesn't exist
            echo -en "${_blue} Do you want to create the configuration directory? [y/N]: ${_reset}"
            read -r create_dir
            # Handle user response
            case "$create_dir" in
                y|Y|yes|Yes|YES)
                    # Create the configuration directory with error handling
                    mkdir -p "${_config_dir}" || {
                        __msg "${_break}${_red}${_line}"
                        __msg_error "Creating configuration directory failed: ${_config_dir}"
                        __msg "${_red}${_line}${_break}"
                        sleep 5
                        clear
                        return 1
                    }
                    __msg "${_break}${_green}${_line}"
                    __msg_success "Configuration directory created: ${_config_dir}"
                    __msg "${_green}${_line}${_break}"
                    sleep 3
                    ;;
                *)
                    __msg "${_break}${_orange}${_line}"
                    __msg_info "Directory creation cancelled.${_break}Return to Main menu..."
                    __msg "${_orange}${_line}${_break}"
                    sleep 5
                    clear
                    return 0
                    ;;
            esac

            # Clear screen
            clear
        fi

        # Function to handle configuration file editing and downloading if missing
        local _menu_options=(
            "linux-tkg  |🧠 Linux   ─ 📝 linux-tkg.cfg"
        )

        # Only show Nvidia and Mesa config if Arch-based distro is detected
        if [[ "${_distro_id,,}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like,,}" == *"arch"* ]]; then
            _menu_options+=(
                "nvidia-all |🎮 Nvidia  ─ 📝 nvidia-all.cfg"
                "mesa-git   |🧩 Mesa    ─ 📝 mesa-git.cfg"
            )
        fi

        # Always show Wine and Proton config options
        _menu_options+=(
            "wine-tkg   |🍷 Wine    ─ 📝 wine-tkg.cfg"
            "proton-tkg |🎮 Proton  ─ 📝 proton-tkg.cfg"
            "return     |⏪ Return"
        )

        # Prepare menu content string for fzf menu display from options array
        local _menu_content
        _menu_content=$(printf '%s\n' "${_menu_options[@]}")

        # Define common error message for preview when config file is missing
        local _error_config_not_exist="${_red}${_line}${_break} ❌ ERROR: No external configuration file found.${_break}${_break}${_reset} ⚠️ Click to download missing file${_break}${_red}${_line}${_reset}"

        # Define a reusable bat command for the preview window
        local _bat_cmd="bat --style=numbers --language=bash --wrap character --highlight-line 1 --force-colorization"

        # Define preview command for fzf menu to show config file content or error message if missing
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

        # Define header and footer texts for fzf menu display with TKG version info
        local _header_text=$'🐸 TKG-Installer ─ Editor menu\n\n   Edit external configuration file\n   Default directory: ~/.config/frogminer/'
        local _footer_text=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\n🐸 Frogging-Family: https://github.com/Frogging-Family\n🌐 About: https://github.com/damachine/tkginstaller'
        local _border_label_text="${_tkg_version}"
        local _preview_window_settings='right:wrap:70%'

        # Show fzf menu and get user selection for configuration file editing
        _config_choice=$(__fzf_menu "$_menu_content" "$_preview_command" "$_header_text" "$_footer_text" "$_border_label_text" "$_preview_window_settings")

        # Handle cancelled selection (ESC key) or empty choice to exit editor menu gracefully
        if [[ -z "$_config_choice" ]]; then
            __msg "${_break}${_green}${_line}"
            __msg_success "Returning to main menu..."
            __msg "${_green}${_line}${_break}"
            sleep 1
            clear
            return 0
        fi

        # Extract selected configuration type and file path from choice string
        local _config_file
        _config_file=$(echo "$_config_choice" | cut -d"|" -f1 | xargs)

        # Handle configuration file editing based on selection using case statement
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
                __msg "${_break}${_green}${_line}"
                __msg_success "Returning to main menu..."
                __msg "${_green}${_line}${_break}"
                sleep 1
                clear
                return 0
                ;;
            *)
                __msg_error "${_line}${_break}Invalid option: $_config_file"
                __msg_info "Usage: $0 help"
                __msg_info " $0 config|c [linux|nvidia|mesa|wine|proton]"
                __msg_error "${_line}${_break}"
                return 1
                ;;
        esac
    done
}

# Helper function to handle individual config file editing and downloading if missing
__handle_config() {
    # Arguments:
    #   $1 - Configuration name
    #   $2 - Configuration file path
    #   $3 - Configuration file URL
    # Returns:
    #   Opens or downloads and opens the specified configuration file in the configured text editor
    # Usage:
    #   __handle_config "Linux-TKG" "/path/to/linux-tkg.cfg" "https://example.com/linux-tkg.cfg"
    # Example:
    #   __handle_config "Linux-TKG" "$HOME/.config/frogminer/linux-tkg.cfg" "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/master/customization.cfg"
    local _config_name="$1" # Configuration name (string)
    local _config_path="$2" # Configuration file path (string)
    local _config_url="$3" # Configuration file URL (string)

    # Notify user about opening the configuration file editor
    __msg "${_break}${_green}${_line}"
    __msg_success "Opening external configuration file: $_config_name"
    __msg "${_green}${_line}${_break}"
    sleep 1
    clear

    # Check if configuration file exists and open or download accordingly
    if [[ -f "$_config_path" ]]; then
        # Edit existing configuration file in the editor if it exists
        __editor "$_config_path" || {
            __msg "${_break}${_red}${_line}"
            __msg_error "Opening external configuration failed: $_config_path"
            __msg "${_red}${_line}${_break}"
            sleep 3
            clear
            return 1
        }
    else
        # Download and create new configuration file if it does not exist
        __msg "${_break}${_orange}${_line}"
        __msg_warning "External configuration file does not exist."
        __msg "${_blue}           Save path: $_config_path"
        __msg "${_blue}           Download link: $_config_url"
        __msg "${_orange}${_line}${_break}"
        # Prompt user for download confirmation
        echo -en "${_blue} Do you want to download the default configuration? [y/N]: ${_reset}"
        read -r user_answer
        # Handle user response for downloading the config file using case statement
        case "$user_answer" in
            y|Y|yes|Yes|YES)
                __msg ""
                # Create the configuration directory if it doesn't exist and download the file using curl with error handling
                mkdir -p "$(dirname "$_config_path") " || {
                    __msg "${_break}${_red}${_line}"
                    __msg_error "Creating configuration directory failed: $_config_path"
                    __msg "${_red}${_line}${_break}"
                    sleep 5
                    clear
                    return 1
                }
                if curl -fsSL "$_config_url" -o "$_config_path" 2>/dev/null; then
                    __msg "${_break}${_green}${_line}"
                    __msg_success "External configuration ready at $_config_path"
                    __msg "${_green}${_line}${_break}"
                    sleep 3
                    clear
                    # Open the downloaded configuration file in the editor
                    __editor "$_config_path" || {
                        __msg "${_break}${_red}${_line}"
                        __msg_error "Opening external configuration $_config_path failed!"
                        __msg "${_red}${_line}${_break}"
                        sleep 5
                        clear
                        return 1
                    }
                else
                    # Failed to download configuration file from URL with error handling
                    __msg "${_break}${_red}${_line}"
                    __msg_error "Downloading external configuration from $_config_url failed!"
                    __msg "${_red}${_line}${_break}"
                    sleep 5
                    clear
                    return 1
                fi
                ;;
            *)
                # User chose not to download the configuration file
                __msg "${_break}${_orange}${_line}"
                __msg_info "Download cancelled. No configuration file created.${_break}Return to Mainmenu..."
                __msg "${_orange}${_line}${_break}"
                sleep 3
                clear
                return 1
                ;;
        esac

        # Clear screen after download process
        clear
    fi

    # Notify user about closing the configuration file editor and remind to save changes
    __msg "${_break}${_green}${_line}"
    __msg_success "Closing external $_config_name configuration file..."
    __msg_success "Remember to save all your changes!"
    __msg "${_green}${_line}${_break}"
    sleep 1
    clear
    return 0
}

# =============================================================================
# PROMPT MENU FUNCTIONS
# =============================================================================

# Linux-TKG installation prompt
__linux_prompt() {
    SECONDS=0
    __msg_info "${_line}${_break}Fetching Linux-TKG from Frogging-Family repository...${_break}${_line}"
    __linux_install
    __done $?
}

# Nvidia-TKG installation prompt
__nvidia_prompt() {
    SECONDS=0
    __msg_info "${_line}${_break}Fetching Nvidia-TKG from Frogging-Family repository...${_break}${_line}"
    __nvidia_install
    __done $?
}

# Mesa-TKG installation prompt
__mesa_prompt() {
    SECONDS=0
    __msg_info "${_line}${_break}Fetching Mesa-TKG from Frogging-Family repository...${_break}${_line}"
    __mesa_install
    __done $?
}

# Wine-TKG installation prompt
__wine_prompt() {
    SECONDS=0
    __msg_info "${_line}${_break}Fetching Wine-TKG from Frogging-Family repository...${_break}${_line}"
    __wine_install
    __done $?
}

# Proton-TKG installation prompt
__proton_prompt() {
    SECONDS=0
    __msg_info "${_line}${_break}Fetching Proton-TKG from Frogging-Family repository...${_break}${_line}"
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

# Interactive main menu with fzf preview for TKG-Installer
__menu() {
    # Define menu options and preview commands for fzf menu display using glow command for dynamic content based on selection
    local _menu_options=(
        "Linux  |🧠 Linux   ─ Linux-TKG custom kernels"
    )

    # Only show Nvidia and Mesa options if Arch-based distribution is detected 
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

    # Prepare menu content for fzf menu display string from options array
    local _menu_content
    _menu_content=$(printf '%s\n' "${_menu_options[@]}")

    # Define preview command for fzf menu with dynamic content based on selection using glow command
    local _preview_command='
        key=$(echo {} | cut -d"|" -f1 | xargs)
        case $key in
            Linux*) $_print "$_preview_linux" ;;
            Nvidia*) $_print "$_preview_nvidia" ;;
            Mesa*) $_print "$_preview_mesa" ;;
            Wine*) $_print "$_preview_wine" ;;
            Proton*) $_print "$_preview_proton" ;;
            Config*) $_print "$_preview_config" ;;
            Clean*) $_print "$_preview_clean" ;;
            Help*) $_print "$_preview_help" ;;
            Exit*) $_print "$_preview_exit" ;;
        esac
    '

    # Define header and footer texts for fzf menu display with TKG version info and instructions
    local _header_text=$'🐸 TKG-Installer\n\n🏗️ Easily build the TKG packages from the Frogging-Family repositories.'
    local _footer_text=$'📝 Use arrow keys or 🖱️ mouse to navigate, Enter to select, ESC to exit\n🐸 Frogging-Family: https://github.com/Frogging-Family\n🌐 About: https://github.com/damachine/tkginstaller'
    local _border_label_text="${_tkg_version}"
    local _preview_window_settings='right:wrap:60%'

    # Show fzf menu and get user selection for main menu options using defined parameters and preview command
    local _main_choice
    _main_choice=$(__fzf_menu "$_menu_content" "$_preview_command" "$_header_text" "$_footer_text" "$_border_label_text" "$_preview_window_settings")

    # Handle cancelled selection (ESC pressed) or empty choice to exit TKG-Installer gracefully
    if [[ -z "${_main_choice:-}" ]]; then
        __msg "${_break}${_green}${_line}"
        __msg_success "Exit TKG-Installer..."
        __msg_success "Cleaning temporary files..."
        __msg "${_green}${_line}${_break}"
        sleep 1
        clear
        __exit 0
    fi

    # Save selection to temporary file for processing in main program loop
    echo "$_main_choice" | cut -d"|" -f1 | xargs > "$_choice_file"
}

# =============================================================================
# MAIN PROGRAM ENTRY POINT
# =============================================================================

# Handle direct command-line arguments for quick execution mode without interactive menu
__main_direct_mode() {
    # Parameters:
    #   $1 = first argument (string)
    #   $2 = second argument (string, optional)
    # Returns:
    #   Processes command-line arguments for direct installation or config editing without interactive menu
    # Usage:
    #   __main_direct_mode "linux" "config"
    # Example:
    #   __main_direct_mode "nvidia" "edit"
    local _arg1="${1,,}"  # Convert to lowercase (optional)
    local _arg2="${2,,}"  # Convert to lowercase (optional)

    # Accept both [package] [config] and [config] [package] order for arguments flexibility
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

        # Disable exit trap before handling config editing to avoid duplicate cleanup messages on exit
        trap - INT TERM EXIT HUP

        # Handle config file editing directly using helper function
        __handle_config "$_config_name" "$_config_path" "$_config_url"

        # Display exit messages after editing config file and before exiting script gracefully
        __msg "${_break}${_green}${_line}${_break}TKG-Installer closed! Goodbye!${_break}${_line}${_break}"

        # Clean exit without triggering __exit cleanup messages. Unset exported all variables
        __clean
        exit 0
    fi

    # Handle regular install commands based on first argument using case statement
    case "$_arg1" in
        linux|l|--linux|-l)
            __prepare
            __linux_prompt
            exit 0
            ;;
        nvidia|n|--nvidia|-n)
            __prepare
            __nvidia_prompt
            exit 0
            ;;
        mesa|m|--mesa|-m)
            __prepare
            __mesa_prompt
            exit 0
            ;;
        wine|w|--wine|-w)
            __prepare
            __wine_prompt
            exit 0
            ;;
        proton|p|--proton|-p)
            __prepare
            __proton_prompt
            exit 0
            ;;
        clean|--clean)
            # Clean temporary files and restart script
            __msg "${_break}${_orange}${_line}"
            __msg_info "Cleaning temporary files..."
            __msg_info "Restarting..."
            __msg "${_orange}${_line}${_break}"
            __prepare >/dev/null 2>&1 || true
            rm -f "$_lock_file" 2>&1 || true
            sleep 1
            clear
            ;;
        help|h|--help|-h)
            # Display help information
            ;;
        *)
            # Invalid argument handling and usage instructions display
            __msg ""
            __msg "${_red}Invalid argument:${_reset} ${1:-} ${2:-}"
            __msg "${_orange}The argument is either invalid or incomplete."

            # Show usage instructions
            __help

            # Disable exit trap before cleanup and exit to avoid duplicate cleanup messages on exit
            trap - INT TERM EXIT HUP
            __clean
            exit 1
            ;;
    esac
}

# Main function for interactive mode with menu selection handling loop
__main_interactive_mode() {
    # Interactive mode - show menu and handle user selection loop until exit chosen
    __prepare true
    clear

    # Initialize dynamic preview content for fzf menus using glow command
    __menu

    # Process user selection from menu until exit is chosen
    local _user_choice
    _user_choice=$(< "$_choice_file")

    # Remove temporary choice file after reading user choice to avoid stale data on next menu display
    rm -f "$_choice_file" 2>&1 || true

    # Handle user choice from menu using case statement and call corresponding prompt functions
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
            # Remove temporary choice file and restart script after editing config file to refresh state and menu options
            rm -f "$_lock_file"
            # Restart the script after editing config file to refresh state and menu options
            clear
            exec "$0"
            ;;
        Help)
            # Remove exit trap to avoid cleanup during help display
            trap - INT TERM EXIT HUP
            __help
            __clean
            exit 0
            ;;
        Clean)
            # Clean temporary files and restart script to refresh state and menu options
            __msg "${_break}${_orange}${_line}"
            __msg_info "Cleaning temporary files...${_break}Restarting..."
            __msg "${_orange}${_line}${_break}"
            __prepare >/dev/null 2>&1 || true
            rm -f "$_lock_file" 2>&1 || true
            sleep 1
            clear
            exec "$0" 
            ;;
        Exit)
            # Exit the script gracefully with cleanup messages
            __msg "${_break}${_green}${_line}"
            __msg_success "Exit TKG-Installer..."
            __msg_success "Cleaning temporary files..."
            __msg "${_green}${_line}${_break}"
            sleep 1
            clear
            exit 0
            ;;
    esac
}

# Main function - handles command line arguments and menu interaction
__main() {
    # Handle direct command line arguments for automation or show interactive menu otherwise
    if [[ $# -gt 0 ]]; then
        # Direct mode - bypass menu and execute commands directly based on arguments
        __main_direct_mode "$@"
    else
        # Interactive mode - show menu and handle user selection loop until exit chosen
        __main_interactive_mode
    fi
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Run main function with all command line arguments
__main "$@"
