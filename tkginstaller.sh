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
# shellcheck disable=SC2016 # Allow variable expansion in strings
# shellcheck disable=SC2059 # Disable SC2059 for printf with variable format string
# shellcheck disable=SC2218 # Allow usage of printf with variable format strings

# TKG-Installer VERSION definition
export _tkg_version="v0.22.4"

# Lock file to prevent concurrent execution of the script
export _lock_file="/tmp/tkginstaller.lock"

# =============================================================================
# ENVIRONMENT SETUP
# =============================================================================

# Initialize global variables, paths, and configurations for the script
__init_globals() {
    _tmp_dir=${HOME}/.cache/tkginstaller # Temporary directory for script operations
    _choice_file=${_tmp_dir}/choice.tmp # Temporary file to store user choices
    _config_dir=${HOME}/.config/frogminer # Configuration directory for Frogminer/TKG packages
    _tkg_repo_url=https://github.com/damachine/tkginstaller # TKG-Installer GitHub repository URL
    _tkg_raw_url=https://raw.githubusercontent.com/damachine/tkginstaller/refs/heads/master/docs # TKG-Installer raw content URL
    _frog_repo_url=https://github.com/Frogging-Family # Frogging-Family GitHub repository URL
    _frog_raw_url=https://raw.githubusercontent.com/Frogging-Family # Frogging-Family raw content URL
    
    # Export variables for fzf subshells (unset __exit run)
    export _tmp_dir _choice_file _config_dir _tkg_repo_url _tkg_raw_url _frog_repo_url _frog_raw_url
}

# Initialize color and formatting definitions for output messages and prompts
__init_style() {
    _echo=$"echo -en" # Echo without newline and interpret escape sequences
    _break=$'\n' # Line break
    _reset=$'\033[0m' # Reset color/formatting
    _clear="\r%*s\r\033[A" # Clear line and move one line up

    # Helper to return TrueColor escape if supported, otherwise fallback to tput setaf <n> if available, else to a 256-color ESC as last resort
    _color() {
        # $1 = r, $2 = g, $3 = b, $4 = fallback tput color index (0-7)
        local r=${1:-255} g=${2:-255} b=${3:-255} idx=${4:-7}

        # Detect basic TrueColor support: COLORTERM usually set to truecolor or 24bit
        if [[ "${COLORTERM,,}" == *truecolor* || "${COLORTERM,,}" == *24bit* ]]; then
            printf '\033[38;2;%d;%d;%dm' "$r" "$g" "$b"
            return 0
        fi

        # Fallback to tput if available
        if command -v tput >/dev/null 2>&1; then
            local _tput_seq
            _tput_seq=$(tput sgr0; tput setaf "$idx") # Reset attributes, then set foreground color
            printf '%s' "${_tput_seq}" # Print the escape sequence
            return 0
        fi

        # Fallback to 256-color approx (map semantic idx -> nicer 256 color indices)
        # idx: 1=red, 2=green, 3=yellow, 4=blue (fallback indices chosen for good contrast)
        local _idx256
        case "$idx" in
            1) _idx256=196 ;;  # bright red
            2) _idx256=118 ;;  # light/bright green
            3) _idx256=214 ;;  # orange/yellow
            4) _idx256=39  ;;  # bright blue/cyan-ish
            *) _idx256=15  ;;  # white
        esac
        printf '\033[38;5;%dm' "$_idx256"
    }

    # Define colors: prefer TrueColor values, fallback to tput/256-color
    _red="$(_color 220 60 60 1)"    # warm red
    _green_light="$(_color 80 255 140 2)"  # light green
    _green_neon="$(_color 120 255 100 2)" # neon green
    _green_mint="$(_color 152 255 200 6)" # mint green
    _green_dark="$(_color 34 68 34 2)"    # dark green (#224422)
    _orange="$(_color 255 190 60 3)"  # orange/yellow
    _blue="$(_color 85 170 255 4)"    # blue
    _gray="$(_color 200 250 200 7)"   # gray

    # Underline on/off sequences (use tput if available for portability)
    _uline_on=$(tput smul 2>/dev/null || printf '\033[4m')
    _uline_off=$(tput rmul 2>/dev/null || printf '\033[24m')

    # Calculate terminal width for dynamic line generation (minimum 80, max half terminal width)
    local _cols
    _cols=$(tput cols 2>/dev/null || echo 80) # Get terminal width, default to 80 if tput fails
    local _line_len=$((_cols / 2)) # Set line length to half terminal width
    if [[ "$_line_len" -lt 80 ]]; then # Minimum line length of 80
        _line_len=80
    fi
    _line=""
    for ((i=0; i<_line_len; i++)); do _line+="─"; done # Generate line of specified length

    # Export variables for fzf subshells (unset __exit run)
    export _print _echo _break _reset _red _green_light _green_neon _green_mint _orange _blue _gray _uline_on _uline_off _line
}

# Display banner with TKG-Installer version information
__banner() {
    local _color="${1:-$_green_mint}"
    printf "%b\n" "${_color}"
    cat <<EOF
░▀█▀░█░█░█▀▀░░░░░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░░█▀▀░█▀▄
░░█░░█▀▄░█░█░▄▄▄░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░░█▀▀░█▀▄
░░▀░░▀░▀░▀▀▀░░░░░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀
──  ${_tkg_version}  ──
EOF
    printf "%b\n" "$_reset"
}

# =============================================================================
# INITIALIZATION AND PRE-CHECKS
# =============================================================================

# Initialize globals and colors for script execution
__init_globals
__init_style

# Unified message function with automatic level detection
__msg() {
    # If first arg is a known level, treat it as level, else default to plain
    local _msg_first="${1:-}" _msg_level _msg # First argument (string)
    case "${_msg_first,,}" in
        info_green|info_orange|info_neon|info_mint|info_blue|warning|error|prompt|plain)
            _msg_level="${_msg_first,,}" # Level specified
            shift # Remove first argument
            _msg="$*" # Remaining arguments as message
            ;;
        *)
            _msg_level="plain" # Default level
            _msg="$*" # All arguments as message
            ;;
    esac

    # Ensure colors exist (fallback to empty strings if not set)
    : "${_reset:=''}" "${_red:=''}" "${_green_light:=''}" "${_green_neon:=''}" "${_green_mint:=''}" "${_green_dark:=''}" "${_orange:=''}" "${_blue:=''}" "${_gray:=''}" "${_uline_on:=''}" "${_uline_off:=''}"

    # Map level -> color + prefix; prompt handled specially (no newline)
    local _color="" _prefix=""
    case "${_msg_level}" in
        info_green)
            _color="${_green_light}"; _prefix=""
            ;;
        info_neon)
            _color="${_green_neon}"; _prefix=""
            ;;
        info_mint)
            _color="${_green_mint}"; _prefix=""
            ;;
        info_orange)
            _color="${_orange}"; _prefix=""
            ;;
        info_blue)
            _color="${_blue}"; _prefix=""
            ;;
        warning)
            _color="${_orange}"
            _prefix="${_uline_on}WARNING:${_uline_off}${_color} "
            ;;
        error)
            _color="${_red}"
            _prefix="${_uline_on}ERROR:${_uline_off}${_color} "
            ;;
        prompt)
            # prompt: do not add newline, do not append reset so user input appears after prompt
            printf '%b' "$_msg"
            return 0
            ;;
        plain|*)
            _color="${_reset}"; _prefix=""
            ;;
    esac

    # Print formatted line with color and reset (add newline)
    printf '%b\n' "${_color}${_prefix}${_msg}${_reset}"
}

# Level-specific message functions for convenience
__msg_info()        { __msg 'info_green' "$@"; }
__msg_info_neon()   { __msg 'info_neon' "$@"; }
__msg_info_mint()   { __msg 'info_mint' "$@"; }
__msg_info_orange() { __msg 'info_orange' "$@"; }
__msg_info_blue()   { __msg 'info_blue' "$@"; }
__msg_warning()     { __msg 'warning' "$@"; }
__msg_error()       { __msg 'error' "$@"; }
__msg_prompt()      { __msg 'prompt' "$@"; }
__msg_plain()       { __msg 'plain' "$@"; }

# Display package information and configuration location notice
__msg_pkg() {
    # $1 = friendly package name (e.g. "Linux-TKG")
    # $2 = config URL (full URL shown in Location:)
    local _pkg_name="${1:-TKG package}"
    local _config_url="${2:-${_frog_repo_url}}"

    __msg_info "${_break}${_green_neon}${_uline_on}NOTICE:${_uline_off}${_reset}${_green_light} customization.cfg${_reset}${_break}"
    __msg_plain " A wide range of options are available."
    __msg_plain " Thanks to their flexible configuration and powerful settings functions, TKG packages"
    __msg_plain " can be precisely tailored to different systems and personal requirements."
    __msg_plain " The${_gray} customization.cfg${_reset} files can be set up using a short setup guide via the interactive menu or with${_reset}${_gray} ‘tkginstaller ${_pkg_name,,} config’${_reset}."
    __msg_plain " The tool then offers you the option to make the adjustments in your preferred text editor."
    __msg_plain " Please make sure to adjust the settings correctly."
    __msg_plain " Refer to the${_gray} customization.cfg${_reset} documentation for detailed configuration options."
    __msg_plain " Location:${_reset}${_gray} ${_config_url}"
}

# Check for root execution and warn the user (if running as root)
if [[ "$(id -u)" -eq 0 ]]; then
    __banner "$_orange"
    __msg_warning "You are running as root!${_break}"
    __msg_plain " Running this script as root is not recommended for security reasons.${_break}"
    # Ask for user confirmation to continue as root
    __msg_prompt "Do you really want to continue as root? [y/N]: "
    trap 'echo;echo; __msg_plain "${_red}Aborted by user.\n";sleep 1.5s; exit 1' INT
    read -r _user_answer
    trap - INT
    if [[ ! "$_user_answer" =~ ^([yY]|[yY][eE][sS])$ ]]; then
        __msg_plain "${_break}${_red}Aborted by user.${_break}"
        exit 1
    fi
fi

# Detect Linux Distribution
if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091 # Source file is system-dependent and may not exist on all systems
    . /etc/os-release
    export _distro_name="$NAME" # e.g., "Ubuntu", "Fedora", etc.
    export _distro_id="${ID:-unknown}" # Distribution ID code, e.g., "ubuntu", "fedora", etc.
    export _distro_like="${ID_LIKE:-}" # Distribution like code, e.g., "debian", "arch", etc.
else
    export _distro_name="Unknown"
    export _distro_id="unknown"
    export _distro_like=""
fi

# Help information display
__help() {
    # Display help information with usage examples and shortcuts
    __banner
    __msg_plain "${_green_mint}Help and Usage${_break}"
    __msg_plain "${_orange}1) Run ${_uline_on}interactive${_uline_off} command${_break}"
    __msg_plain " To run the script in interactive menu mode, simply execute:${_break}"
    __msg_plain "$0${_break}${_break}"
    __msg_plain "${_orange}2) Run ${_uline_on}direct${_uline_off} command${_break}"
    __msg_plain " To run the script with a specific package, use the following command:${_break}"
    __msg_plain "$0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p]${_break}${_break}"
    __msg_plain "${_orange}3) Run direct command for ${_uline_on}customization.cfg${_uline_off}${_break}"
    __msg_plain " To edit the configuration file for a specific package, use the following command:${_break}"
    __msg_plain "$0 [linux|l|nvidia|n|mesa|m|wine|w|proton|p] [config|c|edit|e]${_break}${_break}"
    __msg_plain "${_orange}${_uline_on}Shortcuts${_uline_off}:${_reset} l=linux, n=nvidia, m=mesa, w=wine, p=proton, c=config, e=edit${_break}"
}

# Help can show always!
if [[ $# -gt 0 && "${1:-}" =~ ^(help|h|--help|-h)$ ]]; then
    __help
    trap - INT TERM EXIT HUP # Remove trap on exit
    exit 0
fi

# Prevent concurrent execution (after help check)
if [[ -f "$_lock_file" ]]; then
    # Check if the process is still running from the lock file
    if [[ -r "$_lock_file" ]]; then
        # Get old PID from lock file and check if process is running
        _old_pid=$(cat "$_lock_file" 2>/dev/null || echo "")
        if [[ -n "$_old_pid" ]] && kill -0 "$_old_pid" 2>/dev/null; then
            __banner "$_orange"
            __msg_warning "Script is already running (PID: $_old_pid). Exiting...${_break}"
            __msg_plain " If the script was unexpectedly terminated before."
            __msg_plain " Remove ${_reset}${_gray}$_lock_file${_reset} manually run:${_break}"
            __msg_plain "tkginstaller clean${_break}"
            exit 1
        else
            # Stale lock file found, remove it safely and continue
            rm -f "$_lock_file" 2>/dev/null || {
                __banner "$_orange"
                __msg_warning "Script is already running (PID: $_old_pid). Exiting...${_break}"
                __msg_plain " If the script was unexpectedly terminated before."
                __msg_plain " Remove ${_reset}${_gray}$_lock_file${_reset} manually run:${_break}"
                __msg_plain "tkginstaller clean${_break}"
                exit 1
            }
        fi
    fi
fi

# Create lock file with current PID to prevent concurrent execution (of this script)
echo $$ > "$_lock_file"

# =============================================================================
# CORE UTILITY FUNCTIONS
# =============================================================================

# Pre-installation checks and preparation for installation process
__prepare() {
    # Parameters:
    #   $1 = load preview content (boolean, optional, default: false)
    # Returns:
    #   Performs pre-checks and setup for installation process
    # Usage:
    #   __prepare true  # Load preview content for interactive mode
    #   __prepare false # Skip preview content for direct mode
    # Example:
    #   see above
    _load_preview="${1:-false}" # Default to false if not provided (for direct mode)
    _cols=$(tput cols 2>/dev/null || echo 80) # Get terminal width, default to 80 if tput fails
   
    # Welcome message and pre-checks
    __banner
    printf "%s" "${_green_mint}Starting"
    for i in {1..3}; do
        printf " ."
        sleep 0.33s
    done
    printf "%b\n" "${_reset}"

    # Check required dependencies based on mode (interactive/direct)
    local _dep=(git onefetch)
    if [[ "$_load_preview" == "true" ]]; then
        # Add optional dependencies for interactive mode
        _dep+=(bat curl glow fzf)
    fi

    # Define package names per distro for missing dependencies installation mapping
    declare -A _pkg_map_dep=(
        [git]=git
        [bat]=bat
        [curl]=curl
        [glow]=glow
        [fzf]=fzf
        [onefetch]=onefetch
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
                [onefetch]=app-misc/onefetch
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
        for i in {1..7}; do
            printf "${_clear}" 80 ""
        done
        __banner "$_red"
        __msg_error "Missing dependencies detected.${_break}"
        __msg_plain " Please install the following dependencies first:${_break}"

        # Map dependencies to package names for installation command display
        local _pkg_name_dep=()
        for _dependency in "${_missing_dep[@]}"; do
            _pkg_name_dep+=("${_pkg_map_dep[$_dependency]:-$_dependency}")
        done

        # Display installation command with missing packages
        __msg_plain "${_install_cmd_dep} ${_pkg_name_dep[*]}${_break}"

        # Exit with error code
        exit 0 >/dev/null 2>&1
    fi

    # Setup temporary directory and files for installation process
    # Remove old temporary files and directories if they exist
    rm -f "$_choice_file" 2>/dev/null || true
    rm -rf "$_tmp_dir" 2>/dev/null || true
    # Create necessary subdirectories for temporary files
    mkdir -p "$_tmp_dir" 2>/dev/null || {
        for i in {1..7}; do
            printf "${_clear}" 80 ""
        done
        __banner "$_red"
        __msg_error "Creating temporary directory failed: ${_tmp_dir}${_break}"
        __msg_plain " Please check your permissions and try again.${_break}"
        exit 0 >/dev/null 2>&1
    }

    # Final message before starting TKG-Installer process
    if [[ "$_load_preview" == "true" ]]; then
        __msg_plain "${_green_mint}Entering interactive menu${_reset}"
    else
        __msg_plain "${_green_mint}Running direct installation${_reset}"
    fi

    # Short delay for better UX (( :P ))
    sleep 1.5s
}

# Display completion status with timestamp and duration of the action performed
__finish() {
    local _status=${1:-$?} # Use passed status, fallback to $? for compatibility
    local _duration="${SECONDS:-0}" # Total duration in seconds (since script start)
    local _minutes=$((_duration / 60)) # Calculate minutes part
    local _seconds=$((_duration % 60)) # Calculate remaining seconds part

    # Finalizing message display
    __msg_info_orange "${_break}Action completed: $(date '+%Y-%m-%d %H:%M:%S')" # Display completion message with timestamp
    # Display done or failure status based on exit code
    if [[ $_status -eq 0 ]]; then
        __msg_info "Status: Successfully completed!"
    else
        __msg_error "Failed process (Code: $_status)"
    fi
    __msg_info_orange "Duration: ${_minutes} min ${_seconds} sec" # Display duration message with minutes and seconds

    # Return status code
    return "$_status"
}

# Setup exit trap for cleanup on script termination and errors
__exit() {
    # Get exit code or use passed code
    local _exit_code=${1:-$?}

    # Remove exit trap to avoid recursion during cleanup
    trap - INT TERM EXIT HUP

    # Message handling on exit based on exit code (0=done, non-0=failure)
    if [[ $_exit_code -ne 0 ]]; then
        __banner "$_red"
        __msg_error "Aborting status: $_exit_code${_break}"
        __msg_plain "${_red} Exiting due to errors. Please check the messages above for details.${_break}"
    else
        __banner
        __msg_plain "${_green_mint}Closed.${_break}"
    fi

    # Perform cleanup actions before exiting the script
    __clean
    wait
    exit "$_exit_code"
}

# Ensure signals lead to __exit with non-zero code so __exit shows error output.
# EXIT gets the real status, INT/TERM/HUP use 130 (SIGINT) as conventional code.
trap '__exit 130' INT TERM HUP
trap '__exit $?' EXIT

# Cleanup handler for graceful exit and resource management
__clean() {
    # Remove temporary files and directories created during execution
    rm -f "$_lock_file" 2>/dev/null || true # Remove lock file
    rm -f "$_choice_file" 2>/dev/null || true # Remove temporary choice file
    rm -rf "$_tmp_dir" 2>/dev/null || true # Remove temporary directory

    # Unset exported variables for fzf subshells
    unset _tkg_version _lock_file
    unset _tmp_dir _choice_file _config_dir _tkg_repo_url _tkg_raw_url _frog_repo_url _frog_raw_url
    unset _break _echo _reset _red _green_light _green_neon _green_mint _orange _blue _gray _uline_on _uline_off _line
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
    # Fuzzy finder key bindings for preview toggle and config edit (open)
    local _fzf_bind="ctrl-p:toggle-preview"

    # Run fzf with provided parameters and predefined settings
    fzf \
        --with-shell='bash -c' \
        --style default \
        --color='current-fg:#00ff00,current-bg:#336633,gutter:#336633,pointer:#336633,border:#224422,scrollbar:#336633:bold' \
        --border=sharp \
        --layout=reverse \
        --highlight-line \
        --height='-1' \
        --padding='0' \
        --ansi \
        --delimiter='|' \
        --with-nth='2' \
        --gap='0' \
        --no-extended \
        --no-input \
        --no-multi \
        --no-multi-line \
        --cycle \
        --header="${_header_text}" \
        --header-border=line \
        --header-label="${_green_dark}${_border_label_text}" \
        --header-label-pos=2048 \
        --header-first \
        --footer="${_footer_text}" \
        --footer-border=line \
        --preview-window="${_preview_window_settings}" \
        --preview="${_preview_command}" \
        --preview-border=line \
        --bind="${_fzf_bind}" \
        --disabled \
        <<< "${_menu_content}"
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
    SECONDS=0 # Reset duration timer
    local _repo_url="$1" # Repository URL (string)
    local _package_name="$2" # Package name (string)
    local _build_command="$3" # Build command (string)
    local _work_directory="${4:-}" # Optional working directory relative to cloned repo (string)

    # Navigate to temporary directory for cloning and building process
    cd "${_tmp_dir}" > /dev/null 2>&1 || return 1

    # Clone repository from provided URL
    __msg_info "${_break}${_green_neon}${_uline_on}NOTICE:${_uline_off}${_reset}${_green_light} Fetching $_package_name from Frogging-Family repository...${_break}"
    git clone "$_repo_url" > /dev/null 2>&1 || {
        __msg_error "Cloning failed for: $_package_name${_break}"
        __msg_plain " Please check your internet connection and try again."
        return 1
    }

    # Navigate to the correct directory (assume it's the cloned repo name)
    local _repo_dir
    _repo_dir=$(basename "${_repo_url}" .git)
    cd "${_repo_dir}" > /dev/null 2>&1 || {
        __msg_error "Cloned repository directory not found: ${_repo_dir}${_break}"
        __msg_plain " Please check your path or permissions and try again."
        return 1
    }

    # Navigate to working directory if specified (for proton-tkg)
    if [[ -n "${_work_directory}" ]]; then
        cd "${_work_directory}" > /dev/null 2>&1 || {
            __msg_error "Working directory not found: ${_work_directory}${_break}"
            __msg_plain " Please check your path or permissions and try again."
            return 1
        }
    fi

    # Prefix every output line with a single space (preserves color escapes).
    onefetch --no-bold --no-title --no-art --no-color-palette --http-url --email --nerd-fonts --text-colors 15 15 15 15 15 8 2>/dev/null | sed -u 's/^/ /' || true
    sleep 1.5s # Short delay for better UX (( :P ))

    # Build and install the package using the provided build command
    __msg_info "${_break}${_green_neon}${_uline_on}NOTICE:${_uline_off}${_reset}${_green_light} Cloning, building and installing $_package_name for $_distro_name, this may take a while...${_break}"
    eval "$_build_command" || {
        __msg_error "Building failed: $_package_name for $_distro_name"
        return 1
    }
}

# Linux-TKG installation
__linux_install() {
    # Display banner with package name and version
    if [[ "${_load_preview:-false}" == "true" ]]; then
        __banner
        printf "${_clear}" 80 ""
    fi

    # Inform user (globalized)
    __msg_pkg "linux" "${_frog_repo_url}/linux-tkg/blob/master/customization.cfg"

    # Determine build command based on distribution. Arch-based distributions use makepkg, others use install.sh
    local _build_command

    if [[ "${_distro_id}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like}" == *"arch"* ]]; then
        # Arch-based distributions: Ask user which build system to use
        __msg_info "${_break}${_green_neon}${_uline_on}CHOOSE:${_uline_off}${_reset}${_green_light} Which build system want to use?${_break}"
        __msg_plain " Detected distribution:${_reset} ${_gray}${_distro_name}${_break}"
        __msg_plain " ${_uline_on}1${_uline_off}) makepkg -si${_reset} ${_gray} (recommended for Arch-based distros)"
        __msg_plain " 2) ./install.sh install${_reset} ${_gray} (use if you want the generic install script)${_break}"
        _old_trap_int=$(trap -p INT 2>/dev/null || true)
        trap '__exit 130' INT
        SECONDS_LEFT=60
        _user_answer=""
        while [[ $SECONDS_LEFT -gt 0 ]]; do
            printf "\r${_green_neon}${_uline_on}Select:${_uline_off}${_reset} [${_uline_on}1${_uline_off}/2]${_gray} (auto select: 1)${_reset}${_orange} Waiting for input... %2ds${_reset}: " "$SECONDS_LEFT"
            trap 'echo;echo; __msg_plain "${_red}Aborted by user.";sleep 1.5s; __exit 130' INT
            if read -r -t 1 _user_answer; then
                printf "${_clear}" 80 ""
                break
            fi
            ((SECONDS_LEFT--))
        done
        printf "${_clear}" 80 ""

        if [[ -z "$_user_answer" ]]; then
            _user_answer="1"
        fi
        _user_answer=${_user_answer:-1}

        case "$_user_answer" in
            2)
                _build_command="chmod +x install.sh && ./install.sh install"
                ;;
            *)
                _build_command="makepkg -si"
                ;;
        esac

        # restore previous INT trap
        if [[ -n "$_old_trap_int" ]]; then
            eval "$_old_trap_int"
        else
            trap - INT
        fi
    else
        # Non-Arch distributions
        _build_command="chmod +x install.sh && ./install.sh install"
    fi

    # Execute installation process
    __install_package "${_frog_repo_url}/linux-tkg.git" "linux-tkg" "$_build_command"

    # Installation status message display
    local _status=$?
    __finish "$_status"
}

# Nvidia-TKG installation
__nvidia_install() {
    # Display banner with package name and version
    if [[ "${_load_preview:-false}" == "true" ]]; then
        __banner
        printf "${_clear}" 80 ""
    fi

    # Inform user about external configuration usage for Nvidia-TKG build options customization
    __msg_pkg "nvidia" "${_frog_repo_url}/nvidia-all/blob/master/customization.cfg"

    # Execute installation process for Nvidia-TKG
    __install_package "${_frog_repo_url}/nvidia-all.git" "nvidia-all" "makepkg -si"

    # Installation status message display
    local _status=$?
    __finish "$_status"
}

# Mesa-TKG installation
__mesa_install() {
    # Display banner with package name and version
    if [[ "${_load_preview:-false}" == "true" ]]; then
        __banner
        printf "\r%*s\r\033[A" 80 ""
    fi

    # Inform user about external configuration usage for Mesa-TKG build options customization
    __msg_pkg "mesa" "${_frog_repo_url}/mesa-git/blob/master/customization.cfg"

    # Execute installation process for Mesa-TKG
    __install_package "${_frog_repo_url}/mesa-git.git" "mesa-git" "makepkg -si"

    # Installation status message display
    local _status=$?
    __finish "$_status"
}

# Wine-TKG installation
__wine_install() {
    # Display banner with package name and version
    if [[ "${_load_preview:-false}" == "true" ]]; then
        __banner
        printf "${_clear}" 80 ""
    fi

    # Inform user about external configuration usage for Wine-TKG build options customization
    __msg_pkg "wine" "${_frog_repo_url}/wine-tkg-git/blob/master/wine-tkg-git/customization.cfg"

    # Determine build command based on distribution
    local _build_command

    # Determine build command based on distribution
    if [[ "${_distro_id}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like}" == *"arch"* ]]; then
        # Arch-based distributions: Ask user which build system to use
        __msg_info "${_break}${_green_neon}${_uline_on}CHOOSE:${_uline_off}${_reset}${_green_light} Which build system want to use?${_break}"
        __msg_plain " Detected distribution:${_reset} ${_gray}${_distro_name}${_break}"
        __msg_plain " ${_uline_on}1${_uline_off}) makepkg -si${_reset} ${_gray} (recommended for Arch-based distros)"
        __msg_plain " 2) ./non-makepkg-build.sh${_reset} ${_gray} (use if you want a custom build script)${_break}"
        _old_trap_int=$(trap -p INT 2>/dev/null || true)
        trap '__exit 130' INT
        SECONDS_LEFT=60
        _user_answer=""
        while [[ $SECONDS_LEFT -gt 0 ]]; do
            printf "\r${_green_neon}${_uline_on}Select:${_uline_off}${_reset} [${_uline_on}1${_uline_off}/2]${_gray} (auto select: 1)${_reset}${_orange} Waiting for input... %2ds${_reset}: " "$SECONDS_LEFT"
            trap 'echo;echo; __msg_plain "${_red}Aborted by user.";sleep 1.5s; __exit 130' INT
            if read -r -t 1 _user_answer; then
                printf "${_clear}" 80 ""
                break
            fi
            ((SECONDS_LEFT--))
        done
        printf "${_clear}" 80 ""


        if [[ -z "$_user_answer" ]]; then
            _user_answer="1"
        fi
        _user_answer=${_user_answer:-1}

        case "$_user_answer" in
            2)
                _build_command="chmod +x non-makepkg-build.sh && ./non-makepkg-build.sh"
                ;;
            *)
                _build_command="makepkg -si"
                ;;
        esac
    else
        # Non-Arch distributions
        _build_command="chmod +x non-makepkg-build.sh && ./non-makepkg-build.sh"
    fi

    # restore previous INT trap
    if [[ -n "$_old_trap_int" ]]; then
        eval "$_old_trap_int"
    else
        trap - INT
    fi

    # Set appropriate build command for installation process
    __install_package "${_frog_repo_url}/wine-tkg-git.git" "wine-tkg-git" "$_build_command" "wine-tkg-git"

    # Installation status message display
    local _status=$?
    __finish "$_status"
}

# Proton-TKG installation
__proton_install() {
    # Display banner with package name and version
    if [[ "${_load_preview:-false}" == "true" ]]; then
        __banner
        printf "\r%*s\r\033[A" 80 ""
    fi

    # Inform user about external configuration usage for Proton-TKG build options customization
    __msg_pkg "proton" "${_frog_repo_url}/wine-tkg-git/blob/master/proton-tkg/proton-tkg.cfg"

    # Determine build command for proton-tkg
    local _build_command="./proton-tkg.sh" # Build command for proton-tkg

    # Determine clean command for proton-tkg (after build process)
    local _clean_command="./proton-tkg.sh clean" # Clean command for proton-tkg

    # Build and install and ask for cleaning after build process
    __install_package "${_frog_repo_url}/wine-tkg-git.git" "wine-tkg-git" "$_build_command" "proton-tkg"
    local _status=$?  # capture status immediately

    if [[ $_status -eq 0 ]]; then
        # Ask user if clean command should be executed after build
        __msg_prompt "Do you want to run ${_reset}${_gray}'./proton-tkg.sh clean'${_reset} after building Proton-TKG? [y/N]: "
        _old_trap_int=$(trap -p INT 2>/dev/null || true)
        trap '__exit 130' INT
        read -r _user_answer || { eval "$_old_trap_int"; trap - INT; __exit 130; }
        # restore previous trap
        if [[ -n "$_old_trap_int" ]]; then eval "$_old_trap_int"; else trap - INT; fi

        if [[ "${_user_answer,,}" =~ ^(y|yes)$ ]]; then
            __install_package "${_frog_repo_url}/wine-tkg-git.git" "wine-tkg-git" "$_clean_command" "proton-tkg"
            local _clean_status=$?
            if [[ $_clean_status -eq 0 ]]; then
                __msg_info "${_break}${_green_neon}${_uline_on}NOTICE:${_uline_off}${_reset}${_green_light} Cleaning completed successfully.${_reset}${_break}"
            else
                __msg_error "${_break}${_red}Cleaning failed (code: ${_clean_status}).${_reset}${_break}"
            fi
        fi
    fi

    # Installation status message display — use the captured status
    __finish "$_status"
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
    local _target_file="${1}" # Target file to edit (string)

    # Parse $EDITOR variable (may contain arguments)
    local _editor_raw="${EDITOR-}" # Raw editor command from environment variable (string)
    local _editor_parts=() # Array to hold parsed editor command parts (array)

    # Split editor command into parts (array) by spaces while respecting quoted arguments
    IFS=' ' read -r -a _editor_parts <<< "${_editor_raw}" || true

    # Fallback to nano, micro, or vim if no editor configured or not executable
    if [[ -z "${_editor_parts[0]:-}" ]] || ! command -v "${_editor_parts[0]}" >/dev/null 2>&1; then
        if command -v nano >/dev/null 2>&1; then
            _editor_parts=(nano)
        elif command -v micro >/dev/null 2>&1; then
            _editor_parts=(micro)
        elif command -v vim >/dev/null 2>&1; then
            _editor_parts=(vim)
        else
            __banner "$_red"
            __msg_error "No editor found!${_break}"
            __msg_plain " Please set \$EDITOR environment or install${_reset}${_gray} 'nano'${_reset},${_reset}${_gray} 'micro'${_reset}, or${_reset}${_gray} 'vim'${_reset} as fallback.${_break}"
            __msg_prompt "Press any key to continue..."
            read -n 1 -s -r -p "" # Wait for user input before exiting
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
        # Show configuration options using fzf menu and capture user choice
        local _config_choice # User's configuration choice (string)

        # Ensure configuration directory exists before proceeding (with user prompt to create if missing)
        if [[ ! -d "${_config_dir}" ]]; then
            __banner "$_orange"
            __msg_warning "Configuration directory not found.${_break}"
            __msg_plain " Creating directory:${_reset}${_gray} ${_config_dir}${_reset}${_break}"
            __msg_prompt "Do you want to create the configuration directory? [y/N]: "
            trap 'echo;echo; __msg_plain "${_red}Aborted by user.${_reset}";sleep 1.5; clear; return 0' INT
            read -r _user_answer
            trap - INT
            # Handle user response for directory creation prompt with case statement
            if [[ -z "$_user_answer" ]]; then
                _user_answer="n" # Default to 'no' if no input provided
            fi
            case "${_user_answer,,}" in
                y|yes)
                    # Create the configuration directory with error handling
                    mkdir -p "${_config_dir}" || {
                        clear
                        __banner "$_red"
                        __msg_error "Creating configuration directory failed: ${_config_dir}${_break}"
                        __msg_plain " Please check the path and your permissions then try again.${_break}"
                        __msg_prompt "Press any key to continue..."
                        read -n 1 -s -r -p "" # Wait for user input before exiting
                        clear
                        return 1
                    }
                    clear
                    __banner
                    __msg_info "Configuration directory created:${_reset}${_gray} ${_config_dir}${_reset}${_break}"
                    __msg_prompt "Press any key to continue..."
                    read -n 1 -s -r -p "" # Wait for user input before exiting
                    clear
                    return 0
                    ;;
                *)
                    clear
                    __banner "$_orange"
                    __msg_info_orange "Directory creation cancelled.${_break}"
                    __msg_plain " No changes were made.${_break}"
                    __msg_prompt "Press any key to continue..."
                    read -n 1 -s -r -p "" # Wait for user input before exiting
                    clear
                    return 0
                    ;;
            esac
        fi

        # Function to handle configuration file editing and downloading if missing
        local _menu_options=(
            "linux-tkg  |🐧 ${_green_neon}Linux   ${_gray} linux-tkg.cfg${_reset}   ${_orange} Customize to your needs"
        )

        # Only show Nvidia and Mesa config if Arch-based distro is detected
        if [[ "${_distro_id,,}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like,,}" == *"arch"* ]]; then
            _menu_options+=(
                "nvidia-all |💻 ${_green_neon}Nvidia  ${_gray} nvidia-all.cfg${_reset}  ${_gray} ..."
                "mesa-git   |🧩 ${_green_neon}Mesa    ${_gray} mesa-git.cfg${_reset}    ${_gray} ..."
            )
        fi

        # Always show Wine and Proton config options
        _menu_options+=(
            "wine-tkg   |🍷 ${_green_neon}Wine    ${_gray} wine-tkg.cfg${_reset}    ${_gray} ..."
            "proton-tkg |🎮 ${_green_neon}Proton  ${_gray} proton-tkg.cfg${_reset}  ${_gray} ..."
            "return     |⏪ ${_green_neon}Return"
        )

        # Prepare menu content string for fzf menu display from options array
        local _menu_content
        _menu_content=$(printf '%s\n' "${_menu_options[@]}")

        # Define reusable info message for preview when showing config diffs
        local _info_config="${_green_neon} Showing differences between remote default and your external configuration file${_reset}${_break}${_break}${_green_light} Remote:${_reset}${_gray} \$_remote_url ${_reset}${_break}${_orange}≠${_reset}${_green_light} Local:${_reset}${_gray} file://\$_config_file_path ${_reset}${_break}${_green_dark}${_line}${_break}"

        # Define common error message for preview when config file is missing
        local _error_config_not_exist="${_orange} No external configuration file found.${_reset}${_break}${_break}${_green_light} This configuration file is required for customizing TKG builds and options.${_break}${_green_light} Select and confirm a option to download the missing${_reset}${_gray} customization.cfg${_reset}${_green_light} file now, or create your own later.${_reset}${_break}${_green_dark}${_line}${_break}"

        # Define a reusable bat command for the preview window
        local _bat_cmd="bat --style=plain --language=cfg --force-colorization --theme='Visual Studio Dark+'"

        # Define a reusable diff command for the preview window
        local _cols
        _cols=$(tput cols 2>/dev/null || echo 120)
        
        #local _diff_cmd="git diff --compact-summary --color=always --word-diff=color --unified=3 --ignore-all-space --ignore-blank-lines"
        #local _diff_cmd="colordiff --color=yes --side-by-side"
        local _diff_cmd="diff --color=always --side-by-side"
        
        # Define preview command for fzf menu to show config file content or diff vs remote default
        # It fetches the remote default config file and compares it with the local one if it exists
        local _preview_command='
            declare -A remote_urls=(
                [linux-tkg]="'${_frog_raw_url}'/linux-tkg/master/customization.cfg"
                [nvidia-all]="'${_frog_raw_url}'/nvidia-all/master/customization.cfg"
                [mesa-git]="'${_frog_raw_url}'/mesa-git/master/customization.cfg"
                [wine-tkg]="'${_frog_raw_url}'/wine-tkg-git/master/wine-tkg-git/customization.cfg"
                [proton-tkg]="'${_frog_raw_url}'/wine-tkg-git/master/proton-tkg/proton-tkg.cfg"
            )
            key=$(echo {} | cut -d"|" -f1 | xargs)
            [[ "$key" == "return" ]] && { printf "%b\n" "${_preview_return}"; exit 0; }
            _config_file_path="'${_config_dir}'/${key}.cfg"
            _remote_url="${remote_urls[$key]}"
            if [[ -f "$_config_file_path" && -n "$_remote_url" ]]; then
                _remote_tmp="${_tmp_dir}/${key}-remote.cfg"
                if curl -fsSL "$_remote_url" -o "$_remote_tmp" 2>/dev/null; then
                    printf "%b\n" "${_info_config}"
                    '"${_diff_cmd}"' "$_remote_tmp" "${_config_file_path}" | '"${_bat_cmd}"'
                    rm -f "$_remote_tmp"
                else
                    printf "%b\n" "${_error_config_not_exist}"
                fi
            else
                printf "%b\n" "${_error_config_not_exist}"
            fi
        '

        # Define header, footer, border label, and preview window settings for fzf menu
        local _header_text="🐸${_green_neon} TKG-Installer ─ Config menu${_reset}${_break}${_break}${_green_light}   Adjust external configuration file${_break}   Default directory:${_reset}${_gray} ~/.config/frogminer/ "
        local _footer_text="${_green_light}  Use arrow keys ⌨️ or 🖱️ mouse to navigate, Enter to select, ESC to exit${_break}  Press${_reset}${_gray} Ctrl+P${_reset}${_green_light} to toggle the preview window${_break}${_green_light}  Info:${_reset}${_gray} https://github.com/Frogging-Family${_reset}${_break}${_gray}        https://github.com/damachine/tkginstaller"
        local _border_label_text="${_tkg_version}"
        local _preview_window_settings='right:wrap:70%'

        # Show fzf menu and get user selection for configuration file editing
        _config_choice=$(__fzf_menu "$_menu_content" "$_preview_command" "$_header_text" "$_footer_text" "$_border_label_text" "$_preview_window_settings")

        # Handle cancelled selection (ESC key) or empty choice to exit editor menu gracefully
        if [[ -z "$_config_choice" ]]; then
            __banner
            __msg_info_orange " Applying${_reset}${_gray} customization.cfg${_reset}${_orange} changes...${_break}"
            sleep 1.5s
            clear
            return 0
        fi

        # Extract selected configuration type and file path from choice string
        local _config_file
        _config_file=$(echo "${_config_choice}" | cut -d"|" -f1 | xargs)

            # Handle configuration file editing based on selection using case statement
        case ${_config_file} in
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
                __banner
                __msg_info_orange "Applying${_reset}${_gray} customization.cfg${_reset}${_orange} changes...${_break}"
                sleep 1.5s
                clear
                return 0
                ;;
            *)
                __banner "$_red"
                __msg_error "Invalid option:${_reset} $_config_file${_break}"
                __msg_plain " The option is either invalid or incomplete."
                __msg_plain " All available options run:${_break}"
                __msg_plain "$0 help${_break}"

                # Disable exit trap before cleanup and exit to avoid duplicate cleanup messages on exit
                trap - INT TERM EXIT HUP
                __clean
                exit 1
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
    local _config_name="${1}" # Configuration name (string)
    local _config_path="${2}" # Configuration file path (string)
    local _config_url="${3}" # Configuration file URL (string)

    # Notify user about opening the configuration file editor
    __banner
    __msg_info_orange "Opening external configuration file:${_reset}${_gray} $_config_name${_break}"
    sleep 1.5s
    clear

    # Check if configuration file exists and open or download accordingly
    if [[ -f "${_config_path}" ]]; then
        # Edit existing configuration file in the editor if it exists
        __editor "${_config_path}" || {
            clear
            __banner "$_red"
            __msg_error "Opening external configuration failed:${_reset}${_gray} ${_config_path}${_break}"
            __msg_plain " Please check if the file exists and is accessible.${_break}"
            __msg_prompt "Press any key to continue..."
            read -n 1 -s -r -p "" # Wait for user input before exiting
            clear
            return 1
        }
    else
        # Download and create new configuration file if it does not exist
        __banner "$_orange"
        __msg_warning "External configuration file does not exist.${_break}"
        __msg_plain " Local path: ${_gray}file://${_config_path}"
        __msg_plain " Remote URL: ${_gray}${_config_url}${_break}"

        # Prompt user for download confirmation
        __msg_prompt "Do you want to download the default configuration? [y/N]: "
        trap 'echo;echo; __msg_plain "${_red}Aborted by user.";sleep 1.5s; clear; return 0' INT
        read -r _user_answer
        trap - INT
        if [[ -z "${_user_answer}" ]]; then
            _user_answer="n" # Default to 'no' if no input provided
        fi
        # Handle user response for downloading the config file using case statement
        case "${_user_answer,,}" in
            y|yes)
                # Create the configuration directory if it doesn't exist and download the file using curl with error handling
                mkdir -p "$(dirname "${_config_path}")" || {
                    clear
                    __banner "$_red"
                    __msg_error "Creating configuration directory failed: ${_config_path}${_break}"
                    __msg_plain " Please check the path and your permissions then try again.${_break}"
                    __msg_prompt "Press any key to continue..."
                    read -n 1 -s -r -p "" # Wait for user input before exiting
                    clear
                    return 1
                }
                if ! command -v curl >/dev/null 2>&1; then
                    clear
                    __banner "$_red"
                    __msg_error "curl is not installed. Please install curl to download configuration files.${_break}"
                    __msg_prompt "Press any key to continue..."
                    read -n 1 -s -r -p ""
                    clear
                    return 1
                fi
                if curl -fsSL "${_config_url}" -o "${_config_path}" 2>/dev/null; then
                    clear
                    __banner
                    __msg_info "External configuration ready at:${_reset}${_gray} ${_config_path}"
                    sleep 1.5s
                    clear
                    # Open the downloaded configuration file in the editor
                    __editor "${_config_path}" || {
                        clear
                        __banner "$_orange"
                        __msg_error "Opening external configuration file:${_reset}${_gray} $_config_name${_break}"
                        __msg_plain " Please check if the file exists and is accessible.${_break}"
                        __msg_prompt "Press any key to continue..."
                        read -n 1 -s -r -p "" # Wait for user input before exiting
                        clear
                        return 1
                    }
                else
                    # Failed to download configuration file from URL with error handling
                    clear
                    __banner "$_red"
                    __msg_error "Downloading external configuration from ${_config_url} failed!${_break}"
                    __msg_plain " Please check your internet connection and try again.${_break}"
                    __msg_prompt "Press any key to continue..."
                    read -n 1 -s -r -p "" # Wait for user input before exiting
                    clear
                    return 1
                fi
                ;;
            *)
                # User chose not to download the configuration file
                clear
                __banner "$_orange"
                __msg_info_orange "Download cancelled. No configuration file created.${_break}"
                __msg_plain " No changes were made.${_break}"
                __msg_prompt "Press any key to continue..."
                read -n 1 -s -r -p "" # Wait for user input before exiting
                clear
                return 1
                ;;
        esac

        # Clear screen after download process
        clear
    fi

    # Notify user about closing the configuration file editor and remind to save changes
    clear
    __banner
    __msg_info_orange "Closing external configuration file:${_reset}${_gray} $_config_name${_reset}${_break}"
    sleep 1.5s
    clear
    return 0
}

# =============================================================================
# FZF MAIN MENU FUNCTIONS
# =============================================================================

# Interactive main menu with fzf preview for TKG-Installer
__menu() {
    # Parameters:
    #   None
    # Returns:
    #   Displays an interactive main menu using fzf with preview window and captures user selection for processing
    # Usage:
    #   __menu
    # Example:
    #   __menu

    # I DONT KNOW THIS WORKS BUT IT SHOULD. NOT TESTED YET.
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

    # Define menu options and preview commands for fzf menu display using glow command for dynamic content based on selection
    local _menu_options=(
        "Linux  |🐧 ${_green_neon}Linux   ${_gray} Linux-TKG custom kernels (highly customizable to your needs)"
    )

    # Only show Nvidia and Mesa options if Arch-based distribution is detected 
    if [[ "${_distro_id,,}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like,,}" == *"arch"* ]]; then
        _menu_options+=(
            "Nvidia |💻 ${_green_neon}Nvidia  ${_gray} Nvidia Open-Source or proprietary graphics driver"
            "Mesa   |🧩 ${_green_neon}Mesa    ${_gray} Open-Source graphics driver for AMD and Intel"
        )
    fi

    # Always show Wine, Proton, Config, and Clean options
    _menu_options+=(
        "Wine   |🍷 ${_green_neon}Wine    ${_gray} Windows compatibility layer (run Windows apps on Linux)"
        "Proton |🎮 ${_green_neon}Proton  ${_gray} Run Windows games on Linux via Steam (Proton)"
        "Config |🔧 ${_green_neon}Config  ${_gray} Edit external TKG configuration files (Expert)"
        "Clean  |🧹 ${_green_neon}Clean   ${_gray} Clean all downloaded files and restart the installer"
        "Help   |❓ ${_green_neon}Help    ${_gray} Displays all available usage commands"
        "Close  |❎ ${_green_neon}Close"
    )

    # Prepare menu content for fzf menu display string from options array
    local _menu_content
    _menu_content=$(printf '%s\n' "${_menu_options[@]}")

    # Define preview command for fzf menu with dynamic content based on selection using glow command
    local _preview_command='
        key=$(echo {} | cut -d"|" -f1 | xargs)
        case $key in
            Linux*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/linux.md" ;;
            Nvidia*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/nvidia.md" ;;
            Mesa*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/mesa.md" ;;
            Wine*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/wine.md" ;;
            Proton*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/proton.md" ;;
            Config*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/config.md" ;;
            Clean*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/clean.md" ;;
            Help*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/help.md" ;;
            Close*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/exit.md" ;;
        esac
    '

    # Define header and footer texts for fzf menu display with TKG version info and instructions
    local _header_text="🐸${_green_neon} TKG-Installer ─ Main menu${_reset}${_break}${_break}${_green_light}   Adjust, download, build, and install -TKG- packages${_break}   Select an option below"
    local _footer_text="${_green_light}  Use arrow keys ⌨️ or 🖱️ mouse to navigate, Enter to select, ESC to exit${_break}  Press${_reset}${_gray} Ctrl+P${_reset}${_green_light} to toggle the preview window${_break}${_green_light}  Info:${_reset}${_gray} https://github.com/Frogging-Family${_reset}${_break}${_gray}        https://github.com/damachine/tkginstaller"
    local _border_label_text="${_tkg_version}"
    local _preview_window_settings='right:wrap:60%' #:hidden

    # Show fzf menu and get user selection for main menu options using defined parameters and preview command
    local _main_choice
    _main_choice=$(__fzf_menu "$_menu_content" "$_preview_command" "$_header_text" "$_footer_text" "$_border_label_text" "$_preview_window_settings")

    # Handle cancelled selection (ESC pressed) or empty choice to exit TKG-Installer gracefully
    if [[ -z "${_main_choice:-}" ]]; then
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
        __banner
        __msg_plain "${_green_mint}Closed.${_break}"

        # Clean exit without triggering __exit cleanup messages. Unset exported all variables
        __clean
        exit 0
    fi

    # Handle regular install commands based on first argument using case statement
    case "$_arg1" in
        linux|l|--linux|-l)
            __prepare
            __linux_install
            ;;
        nvidia|n|--nvidia|-n)
            __prepare
            __nvidia_install
            ;;
        mesa|m|--mesa|-m)
            __prepare
            __mesa_install
            ;;
        wine|w|--wine|-w)
            __prepare
            __wine_install
            ;;
        proton|p|--proton|-p)
            __prepare
            __proton_install
            ;;
        clean|--clean)
            # Clean temporary files and restart script
            __banner
            __msg_info_orange "Cleaning all temporary files...${_break}"
            __msg_plain " Location:${_reset}${_gray} ${_tmp_dir}${_reset}${_break}"
            rm -f "$_choice_file" 2>&1 || true
            rm -f "$_lock_file" 2>&1 || true
            rm -rf "$_tmp_dir" 2>&1 || true
            sleep 1.5s
            __msg_plain "${_green_mint}Done.${_break}"
            exit 0 >/dev/null 2>&1
            ;;
        help|h|--help|-h)
            # Display help information
            ;;
        *)
            # Invalid argument handling and usage instructions display
            __banner "$_orange"
            __msg_warning "Invalid argument:${_reset}${_gray} ${1:-} ${2:-}${_reset}${_break}"
            __msg_plain " The argument is either invalid or incomplete."
            __msg_plain " All available arguments run:${_break}"
            __msg_plain "$0 help${_break}"

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
            __linux_install
            ;;
        Nvidia)
            __nvidia_install
            ;;
        Mesa)
            __mesa_install
            ;;
        Wine)
            __wine_install
            ;;
        Proton)
            __proton_install
            ;;
        Config)
            __edit_config || true
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
            # Clean temporary files and restart script
            __banner
            __msg_info_orange "Cleaning all temporary files...${_break}"
            __msg_plain " Location:${_reset}${_gray} ${_tmp_dir}${_reset}${_break}"
            rm -f "$_choice_file" 2>&1 || true
            rm -f "$_lock_file" 2>&1 || true
            rm -rf "$_tmp_dir" 2>&1 || true
            sleep 1.5s
            __msg_plain "${_green_mint}Done.${_break}"
            exit 0 >/dev/null 2>&1
            ;;
        Close)
            # Close the script gracefully with cleanup messages
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

# Pass all command line arguments to main function
__main "$@" 
