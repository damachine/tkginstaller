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

# Fuzzy finder run in a separate shell (subshell) - export variables for fzf subshells
# shellcheck disable=SC2016 # Allow variable expansion in strings
# shellcheck disable=SC2059 # Disable SC2059 for printf with variable format string
# shellcheck disable=SC2218 # Allow usage of printf with variable format strings

# TKG-Installer VERSION
export _tkg_version="v0.24.0"

# Lock file
export _lock_file="/tmp/tkginstaller.lock"

# =============================================================================
# ENVIRONMENT SETUP
# =============================================================================

# Initialize global variables, paths, and configurations
__init_globals() {
    _tmp_dir=${HOME}/.cache/tkginstaller # Temporary directory for TKG-Installer
    _choice_file=${_tmp_dir}/choice.tmp # Temporary file to store user choices
    _config_dir=${HOME}/.config/frogminer # Configuration directory for Frogminer/TKG packages
    _tkg_repo_url=https://github.com/damachine/tkginstaller
    _tkg_raw_url=https://raw.githubusercontent.com/damachine/tkginstaller/refs/heads/master/docs
    _frog_repo_url=https://github.com/Frogging-Family
    _frog_raw_url=https://raw.githubusercontent.com/Frogging-Famil
    
    # Export variables for fzf subshells (unset __exit run)
    export _tmp_dir _choice_file _config_dir _tkg_repo_url _tkg_raw_url _frog_repo_url _frog_raw_url
}

# Initialize color and formatting
__init_style() {
    _break=$'\n'
    _reset=$'\033[0m' # Reset color/formatting
    _clear=$'\r%*s\r\033[A' # Clear line and move one line up

    # Helper to return TrueColor
    _color() {
        local r=${1:-255} g=${2:-255} b=${3:-255} idx=${4:-7}

        # Detect basic TrueColor support
        if [[ "${COLORTERM,,}" == *truecolor* || "${COLORTERM,,}" == *24bit* ]]; then
            printf '\033[38;2;%d;%d;%dm' "$r" "$g" "$b"
            return 0
        fi

        # Fallback to tput if available
        if command -v tput >/dev/null 2>&1; then
            local _tput_seq
            _tput_seq=$(tput sgr0; tput setaf "$idx") # Reset attributes, then set foreground color
            printf '%s' "${_tput_seq}"
            return 0
        fi

        # Fallback to 256-color
        # idx: 1=red, 2=green, 3=yellow, 4=blue
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
    _red="$(_color 220 60 60 1)"           # warm red
    _green_light="$(_color 80 255 140 2)"  # light green
    _green_neon="$(_color 120 255 100 2)"  # neon green
    _green_mint="$(_color 152 255 200 6)"  # mint green
    _green_dark="$(_color 34 68 34 2)"     # dark green (#224422)
    _orange="$(_color 255 190 60 3)"       # orange/yellow
    _blue="$(_color 85 170 255 4)"         # blue
    _gray="$(_color 200 250 200 7)"        # gray

    # Underline on/off sequences
    _uline_on=$(tput smul 2>/dev/null || printf '\033[4m')
    _uline_off=$(tput rmul 2>/dev/null || printf '\033[24m')

    # Calculate terminal width
    _cols="$(tput cols 2>/dev/null || echo 130)"

    # Calculate terminal width
    local _line_len=$(( _cols / 2 ))
    if [[ "$_line_len" -lt 130 ]]; then
        _line_len=130
    fi
    # Generate line
    _line=""
    for ((i=0; i<"$_line_len"; i++)); do _line+="─"; done

    # Export variables
    export _print _break _reset _red _green_light _green_neon _green_mint _orange _blue _gray _uline_on _uline_off _cols _line
}

# Display banner
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

# Initialize globals and colors
__init_globals
__init_style

# Unified message function with automatic level detection
__msg() {
    local _msg_first="${1:-}" _msg_level _msg
    case "${_msg_first,,}" in
        info_green|info_orange|info_neon|info_mint|info_blue|warning|error|prompt|plain)
            _msg_level="${_msg_first,,}"
            shift
            _msg="$*"
            ;;
        *)
            _msg_level="plain"
            _msg="$*"
            ;;
    esac

    # Ensure colors exist
    : "${_reset:=''}" "${_red:=''}" "${_green_light:=''}" "${_green_neon:=''}" "${_green_mint:=''}" "${_green_dark:=''}" "${_orange:=''}" "${_blue:=''}" "${_gray:=''}" "${_uline_on:=''}" "${_uline_off:=''}"

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
            printf '%b' "$_msg"
            return 0
            ;;
        plain|*)
            _color="${_reset}"; _prefix=""
            ;;
    esac

    # Print formatted line
    printf '%b\n' "${_color}${_prefix}${_msg}${_reset}"
}

# Level-specific message
__msg_info()        { __msg 'info_green' "$@"; }
__msg_info_neon()   { __msg 'info_neon' "$@"; }
__msg_info_mint()   { __msg 'info_mint' "$@"; }
__msg_info_orange() { __msg 'info_orange' "$@"; }
__msg_info_blue()   { __msg 'info_blue' "$@"; }
__msg_warning()     { __msg 'warning' "$@"; }
__msg_error()       { __msg 'error' "$@"; }
__msg_prompt()      { __msg 'prompt' "$@"; }
__msg_plain()       { __msg 'plain' "$@"; }

# Display information and configuration notice
__msg_pkg() {
    local _pkg_name="${1:-TKG package}"
    local _config_url="${2:-${_frog_repo_url}}"

    __msg_info "${_break}${_green_neon}${_uline_on}NOTICE${_uline_off}:${_reset}${_green_light} Create, edit, and compare${_gray} customization.cfg${_reset}${_green_light} files${_reset}${_break}"
    __msg_plain " A wide range of options are available!"
    __msg_plain " Thanks to their flexible configuration and powerful settings, -TKG- packages"
    __msg_plain " can be precisely tailored to different systems and personal preferences.${_break}"
    __msg_plain " Set up and use the${_gray} customization.cfg${_reset} file with one of the two methods listed below:"
    __msg_plain "  1)${_gray} tkginstaller -> Config -> ${_pkg_name,,}${_reset} (interactive menu)"
    __msg_plain "  2)${_gray} tkginstaller ${_pkg_name,,} config${_reset} (direct command)${_break}"
    __msg_plain " ${_uline_on}Please make sure to adjust the settings correctly!${_uline_off}"
    __msg_plain " See: ${_gray}${_config_url}${_reset}"
}

# Check for root execution
if [[ "$(id -u)" -eq 0 ]]; then
    __banner "$_orange"
    __msg_warning "You are running as root!${_break}"
    __msg_plain " Running this script as root is not recommended for security reasons.${_break}"
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
    # shellcheck disable=SC1091 # Source file is system-dependent
    . /etc/os-release
    export _distro_name="$NAME".
    export _distro_id="${ID:-unknown}"
    export _distro_like="${ID_LIKE:-}"
else
    export _distro_name="Unknown"
    export _distro_id="unknown"
    export _distro_like=""
fi

# Help information display
__help() {
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
    trap - INT TERM EXIT HUP
    exit 0
fi

# Prevent concurrent execution
if [[ -f "$_lock_file" ]]; then
    # Check if the process is still running from the lock file
    if [[ -r "$_lock_file" ]]; then
        # Get old PID from lock file
        _old_pid=$(cat "$_lock_file" 2>/dev/null || echo "")
        if [[ -n "$_old_pid" ]] && kill -0 "$_old_pid" 2>/dev/null; then
            __banner "$_orange"
            __msg_warning "Script is already running (PID: $_old_pid). Exiting...${_break}"
            __msg_plain " If the script was unexpectedly terminated before."
            __msg_plain " Remove ${_reset}${_gray}$_lock_file${_reset} manually run:${_break}"
            __msg_plain "tkginstaller clean${_break}"
            exit 1
        else
            # Stale lock file found
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

# Create lock file with current PID
echo $$ > "$_lock_file"

# =============================================================================
# CORE UTILITY FUNCTIONS
# =============================================================================

# Pre-installation checks and preparation
__prepare() {
    _load_preview="${1:-false}"
   
    # Welcome message
    __banner
    printf "%s" "${_green_mint}Starting"
    for i in {1..3}; do
        printf " ."
        sleep 0.33s
    done
    printf "%b\n" "${_reset}"

    # Check required dependencies
    local _dep=(git onefetch) # Base dependencies
    if [[ "$_load_preview" == "true" ]]; then
        # Add optional dependencies
        _dep+=(bat curl glow fzf wdiff)
    fi

    # Define package names per distro 
    declare -A _pkg_map_dep=(
        [git]=git
        [bat]=bat
        [curl]=curl
        [glow]=glow
        [fzf]=fzf
        [onefetch]=onefetch
        [wdiff]=wdiff
    )

    # Set install command
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
                [wdiff]=app-text/wdiff
                [wdiff]=app-text/wdiff
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

    # Exit if any dependencies are missing
    if [[ ${#_missing_dep[@]} -gt 0 ]]; then
        for i in {1..7}; do
            printf "$_clear" 80 ""
        done
        __banner "$_red"
        __msg_error "Missing dependencies detected.${_break}"
        __msg_plain " Please install the following dependencies first:${_break}"

        # Map dependencies
        local _pkg_name_dep=()
        for _dependency in "${_missing_dep[@]}"; do
            _pkg_name_dep+=("${_pkg_map_dep[$_dependency]:-$_dependency}")
        done

        # Display installation command
        __msg_plain "${_install_cmd_dep} ${_pkg_name_dep[*]}${_break}"

        # Exit with error code
        exit 0 >/dev/null 2>&1
    fi

    # Setup temporary directory
    rm -f "$_choice_file" 2>/dev/null || true
    rm -rf "$_tmp_dir" 2>/dev/null || true
    mkdir -p "$_tmp_dir" 2>/dev/null || {
        for i in {1..7}; do
            printf "$_clear" 80 ""
        done
        __banner "$_red"
        __msg_error "Creating temporary directory failed: ${_tmp_dir}${_break}"
        __msg_plain " Please check your permissions and try again.${_break}"
        exit 0 >/dev/null 2>&1
    }

    # Entering TKG-Installer
    if [[ "$_load_preview" == "true" ]]; then
        __msg_plain "${_green_mint}Entering interactive menu${_reset}"
    else
        __msg_plain "${_green_mint}Running direct installation${_reset}"
    fi

    # Short delay for better UX (( :P ))
    sleep 1.5s
}

# Display completion status
__finish() {
    local _status=${1:-$?}
    local _duration="${SECONDS:-0}"
    local _minutes=$((_duration / 60))
    local _seconds=$((_duration % 60))

    # Finisher message display
    __msg_info_orange "${_break}Action completed: $(date '+%Y-%m-%d %H:%M:%S')"
    if [[ $_status -eq 0 ]]; then
        __msg_info "Status: Successfully completed!"
    else
        __msg_error "Failed process (Code: $_status)"
    fi
    __msg_info_orange "Duration: ${_minutes} min ${_seconds} sec"

    # Return status code
    return "$_status"
}

# Setup exit trap for cleanup on script termination and errors
__exit() {
    # Remove exit trap
    local _exit_code=${1:-$?}
    trap - INT TERM EXIT HUP

    # Message handling on exit
    if [[ $_exit_code -ne 0 ]]; then
        __banner "$_red"
        __msg_error "Aborting status: $_exit_code${_break}"
        __msg_plain "${_red} Exiting due to errors. Please check the messages above for details.${_break}"
    else
        __banner
        __msg_plain "${_green_mint}Closed.${_break}"
    fi

    # Perform cleanup actions
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
    rm -f "$_lock_file" 2>/dev/null || true
    rm -f "$_choice_file" 2>/dev/null || true
    rm -rf "$_tmp_dir" 2>/dev/null || true

    # Unset exported variables for fzf subshells
    unset _tkg_version _lock_file
    unset _tmp_dir _choice_file _config_dir _tkg_repo_url _tkg_raw_url _frog_repo_url _frog_raw_url
    unset _break _reset _red _green_light _green_neon _green_mint _orange _blue _gray _uline_on _uline_off _cols _line
    unset _preview_linux _preview_nvidia _preview_mesa _preview_wine _preview_proton
    unset _preview_config _preview_clean _preview_help _preview_return _preview_exit _glow_style
    unset _distro_name _distro_id _distro_like
 }

# Fuzzy finder menu wrapper function for consistent settings and usage
__fzf_menu() {
    # $1: Menü-Inhalt, $2: Preview-Command, $3: Header, $4: Footer, $5: Label (optional), $6: Preview-Window-Settings (optional)
    local _menu_content="$1"
    local _preview_command="$2"
    local _header_text="$3"
    local _footer_text="$4"
    local _border_label_text="${5:-$_tkg_version}"
    local _preview_window_settings="${6:-right:wrap:55%}"
    local _fzf_bind="${7:-ctrl-p:toggle-preview}"

    # Run fzf with consistent styling and options
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

# Generic package installation helper function
__install_package() {
    SECONDS=0
    local _repo_url="$1"
    local _package_name="$2"
    local _build_command="$3"
    local _work_directory="${4:-}"

    # Navigate to temporary directory
    cd "${_tmp_dir}" > /dev/null 2>&1 || return 1

    # Clone repository from provided URL
    __msg_info "${_break}${_green_neon}${_uline_on}NOTICE${_uline_off}:${_reset}${_green_light} Fetching $_package_name from Frogging-Family repository...${_break}"
    git clone "$_repo_url" > /dev/null 2>&1 || {
        __msg_error "Cloning failed for: $_package_name${_break}"
        __msg_plain " Please check your internet connection and try again."
        return 1
    }

    # Navigate to the correct directory
    local _repo_dir
    _repo_dir=$(basename "${_repo_url}" .git)
    cd "${_repo_dir}" > /dev/null 2>&1 || {
        __msg_error "Cloned repository directory not found: ${_repo_dir}${_break}"
        __msg_plain " Please check your path or permissions and try again."
        return 1
    }

    # Navigate to working directory
    if [[ -n "${_work_directory}" ]]; then
        cd "${_work_directory}" > /dev/null 2>&1 || {
            __msg_error "Working directory not found: ${_work_directory}${_break}"
            __msg_plain " Please check your path or permissions and try again."
            return 1
        }
    fi

    # Prefix every output line with a single space
    onefetch --no-bold --no-title --no-art --no-color-palette --http-url --email --nerd-fonts --text-colors 15 15 15 15 15 8 2>/dev/null | sed -u 's/^/ /' || true
    sleep 1.5s

    # Build and install
    __msg_info "${_break}${_green_neon}${_uline_on}NOTICE${_uline_off}:${_reset}${_green_light} Cloning, building and installing $_package_name for $_distro_name, this may take a while...${_break}"
    eval "$_build_command" || {
        __msg_error "Building failed: $_package_name for $_distro_name"
        return 1
    }
}

# Linux-TKG installation
__linux_install() {
    # Display banner
    if [[ "${_load_preview:-false}" == "true" ]]; then
        __banner
        printf "$_clear" 80 ""
    fi

    # Inform user about external configuration usage
    __msg_pkg "linux" "${_frog_repo_url}/linux-tkg/blob/master/customization.cfg"

    # Determine build command
    local _build_command

    if [[ "${_distro_id}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like}" == *"arch"* ]]; then
        # Arch-based distributions: Ask user which build system to use
        __msg_info "${_break}${_green_neon}${_uline_on}CHOOSE${_uline_off}:${_reset}${_green_light} Which build system want to use?${_break}"
        __msg_plain " Detected distribution:${_reset} ${_gray}${_distro_name}${_break}"
        __msg_plain " ${_uline_on}1${_uline_off}) makepkg -si${_reset}${_gray} (recommended for Arch-based distros) (${_uline_on}selected${_uline_off})"
        __msg_plain " 2) install.sh install${_reset} ${_gray} (use if you want the generic install script)${_break}"
        _old_trap_int=$(trap -p INT 2>/dev/null || true)
        trap '__exit 130' INT
        SECONDS_LEFT=60
        _user_answer=""
        while [[ $SECONDS_LEFT -gt 0 ]]; do
            printf "\r${_green_neon}${_uline_on}SELECT${_uline_off}:${_reset} [${_uline_on}1${_uline_off}/2]${_orange} Waiting for input... %2ds:${_reset} " "$SECONDS_LEFT"
            trap 'echo;echo; __msg_plain "${_red}Aborted by user.";sleep 1.5s; __exit 130' INT
            if read -r -t 1 _user_answer; then
                printf "$_clear" 80 ""
                break
            fi
            ((SECONDS_LEFT--))
        done
        printf "$_clear" 80 ""

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

    # Installation status message
    local _status=$?
    __finish "$_status"
}

# Nvidia-TKG installation
__nvidia_install() {
    # Display banner
    if [[ "${_load_preview:-false}" == "true" ]]; then
        __banner
        printf "$_clear" 80 ""
    fi

    # Inform user about external configuration usage
    __msg_pkg "nvidia" "${_frog_repo_url}/nvidia-all/blob/master/customization.cfg"

    # Execute installation process
    __install_package "${_frog_repo_url}/nvidia-all.git" "nvidia-all" "makepkg -si"

    # Installation status message
    local _status=$?
    __finish "$_status"
}

# Mesa-TKG installation
__mesa_install() {
    # Display banner
    if [[ "${_load_preview:-false}" == "true" ]]; then
        __banner
        printf "$_clear" 80 ""
    fi

    # Inform user about external configuration usage
    __msg_pkg "mesa" "${_frog_repo_url}/mesa-git/blob/master/customization.cfg"

    # Execute installation process
    __install_package "${_frog_repo_url}/mesa-git.git" "mesa-git" "makepkg -si"

    # Installation status message
    local _status=$?
    __finish "$_status"
}

# Wine-TKG installation
__wine_install() {
    # Display banner 
    if [[ "${_load_preview:-false}" == "true" ]]; then
        __banner
        printf "$_clear" 80 ""
    fi

    # Inform user about external configuration usage
    __msg_pkg "wine" "${_frog_repo_url}/wine-tkg-git/blob/master/wine-tkg-git/customization.cfg"

    # Determine build command
    local _build_command

    # Determine build command
    if [[ "${_distro_id}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like}" == *"arch"* ]]; then
        # Arch-based distributions: Ask user which build system to use
        __msg_info "${_break}${_green_neon}${_uline_on}CHOOSE${_uline_off}:${_reset}${_green_light} Which build system want to use?${_break}"
        __msg_plain " Detected distribution:${_reset} ${_gray}${_distro_name}${_break}"
        __msg_plain " ${_uline_on}1${_uline_off}) makepkg -si${_reset}${_gray} (recommended for Arch-based distros) (${_uline_on}selected${_uline_off})"
        __msg_plain " 2) non-makepkg-build.sh${_reset}${_gray} (use if you want a custom build script)${_break}"
        _old_trap_int=$(trap -p INT 2>/dev/null || true)
        trap '__exit 130' INT
        SECONDS_LEFT=60
        _user_answer=""
        while [[ $SECONDS_LEFT -gt 0 ]]; do
            printf "\r${_green_neon}${_uline_on}SELECT${_uline_off}:${_reset} [${_uline_on}1${_uline_off}/2]${_orange} Waiting for input... %2ds:${_reset} " "$SECONDS_LEFT"
            trap 'echo;echo; __msg_plain "${_red}Aborted by user.";sleep 1.5s; __exit 130' INT
            if read -r -t 1 _user_answer; then
                printf "$_clear" 80 ""
                break
            fi
            ((SECONDS_LEFT--))  
        done
        printf "$_clear" 80 ""


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

    # Restore previous INT trap
    if [[ -n "$_old_trap_int" ]]; then
        eval "$_old_trap_int"
    else
        trap - INT
    fi

    # Set appropriate build command
    __install_package "${_frog_repo_url}/wine-tkg-git.git" "wine-tkg-git" "$_build_command" "wine-tkg-git"

    # Installation status message
    local _status=$?
    __finish "$_status"
}

# Proton-TKG installation
__proton_install() {
    # Display banner
    if [[ "${_load_preview:-false}" == "true" ]]; then
        __banner
        printf "\r%*s\r\033[A" 80 ""
    fi

    # Inform user about external configuration usage    
    __msg_pkg "proton" "${_frog_repo_url}/wine-tkg-git/blob/master/proton-tkg/proton-tkg.cfg"

    # Determine build command
    local _build_command="./proton-tkg.sh" # Build command for proton-tkg

    # Determine clean command
    local _clean_command="./proton-tkg.sh clean" # Clean command for proton-tkg

    # Build and install
    __install_package "${_frog_repo_url}/wine-tkg-git.git" "wine-tkg-git" "$_build_command" "proton-tkg"
    local _status=$?  # capture status immediately

    if [[ $_status -eq 0 ]]; then
        # Ask user if clean command
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
                __msg_error "Cleaning failed (code: ${_clean_status}).${_break}"
            fi
        fi
    fi

    # Installation status message
    __finish "$_status"
}

# =============================================================================
# EDITOR MANAGEMENT FUNCTION
# =============================================================================

# Text editor wrapper with fallback
__editor() {
    local _target_file="${1}"
    local _editor_raw="${EDITOR-}"
    local _editor_parts=()

    # Split editor command into parts
    IFS=' ' read -r -a _editor_parts <<< "${_editor_raw}" || true

    # Fallback to nano, micro, or vim if no editor configured
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
            __msg_prompt "Press any key to continue...${_break}"
            read -n 1 -s -r -p ""
            return 1
        fi
    fi

    # Execute the editor with the target _target_file as argument
    "${_editor_parts[@]}" "$_target_file"
}

# Configuration file editor with interactive menu using fzf finder
__edit_config() {
    while true; do
        local _config_choice

        # Ensure configuration directory exists
        if [[ ! -d "${_config_dir}" ]]; then
            __banner "$_orange"
            __msg_warning "Configuration directory not found.${_break}"
            __msg_plain " Creating directory:${_reset}${_gray} ${_config_dir}${_reset}${_break}"
            __msg_prompt "Do you want to create the configuration directory? [y/N]: "
            trap 'echo;echo; __msg_plain "${_red}Aborted by user.${_reset}";sleep 1.5; clear; return 0' INT
            read -r _user_answer
            trap - INT
            # Handle user response for directory
            if [[ -z "$_user_answer" ]]; then
                _user_answer="n"
            fi
            case "${_user_answer,,}" in
                y|yes)
                    mkdir -p "${_config_dir}" || {
                        clear
                        __banner "$_red"
                        __msg_error "Creating configuration directory failed: ${_config_dir}${_break}"
                        __msg_plain " Please check the path and your permissions then try again.${_break}"
                        __msg_prompt "Press any key to continue...${_break}"
                        read -n 1 -s -r -p ""
                        clear
                        return 1
                    }
                    clear
                    __banner
                    __msg_info "Configuration directory created:${_reset}${_gray} ${_config_dir}${_reset}${_break}"
                    __msg_prompt "Press any key to continue...${_break}"
                    read -n 1 -s -r -p ""
                    clear
                    return 0
                    ;;
                *)
                    clear
                    __banner "$_orange"
                    __msg_info_orange "Directory creation cancelled.${_break}"
                    __msg_plain " No changes were made.${_break}"
                    __msg_prompt "Press any key to continue...${_break}"
                    read -n 1 -s -r -p ""
                    clear
                    return 0
                    ;;
            esac
        fi

        # Function to handle configuration file editing and downloading if missing
        local _menu_options=(
            "linux-tkg  |🐧 ${_green_neon}Linux   ${_gray} customization.cfg ${_reset}->${_orange} 'linux-tkg.cfg'  "
        )

        # Only show Nvidia and Mesa config if Arch-based distro is detected
        if [[ "${_distro_id,,}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like,,}" == *"arch"* ]]; then
            _menu_options+=(
                "nvidia-all |💻 ${_green_neon}Nvidia  ${_gray} customization.cfg ${_reset}->${_orange} 'nvidia-all.cfg'"
                "mesa-git   |🧩 ${_green_neon}Mesa    ${_gray} customization.cfg ${_reset}->${_orange} 'mesa-git.cfg'"
            )
        fi

        _menu_options+=(
            "wine-tkg   |🍷 ${_green_neon}Wine    ${_gray} customization.cfg ${_reset}->${_orange} 'wine-tkg.cfg'"
            "proton-tkg |🎮 ${_green_neon}Proton  ${_gray} customization.cfg ${_reset}->${_orange} 'proton-tkg.cfg'"
            "return     |⏪ ${_green_neon}Return"
        )

        # Prepare menu content
        local _menu_content
        _menu_content=$(printf '%s\n' "${_menu_options[@]}")

        # Define info message
        local _info_config="${_green_neon}Comparing remote and local ${_reset}${_gray}customization.cfg${_reset}${_green_neon}, press [Enter] to open and edit ${_reset}${_break}${_break}${_green_light} Remote:${_reset}${_gray} \$_remote_url ${_reset}${_break}${_orange}≠${_reset}${_green_light} Local:${_reset}${_gray} file://\$_config_file_path ${_reset}${_break}${_green_dark}${_line}${_break}"

        # Define error message
        local _error_config_not_exist="${_orange}No external configuration file found.${_reset}${_break}${_break}${_green_light} This configuration file is required for customizing the -TKG- package.${_break}${_green_light} Press [Enter] to download the missing${_reset}${_gray} customization.cfg${_reset}${_green_light} file, according to -TKG- package standards.${_reset}${_break}${_green_dark}${_line}${_break}"

        # Define bat command
        local _bat_cmd="bat --style=plain --language=cfg --wrap character --terminal-width ${_cols} --force-colorization --theme='Visual Studio Dark+'"
        
        # Define wdiff command
        local _diff_cmd="wdiff --terminal --statistics --start-delete='${_red}' --end-delete='${_reset}' --start-insert='${_green_light}' --end-insert='${_reset}'"

        # Define preview command for fzf menu
        local _preview_command='
            declare -A remote_urls=(
                [linux-tkg]="'${_frog_raw_url}'/linux-tkg/master/customization.cfg"
                [nvidia-all]="'${_frog_raw_url}'/nvidia-all/master/customization.cfg"
                [mesa-git]="'${_frog_raw_url}'/mesa-git/master/customization.cfg"
                [wine-tkg]="'${_frog_raw_url}'/wine-tkg-git/master/wine-tkg-git/customization.cfg"
                [proton-tkg]="'${_frog_raw_url}'/wine-tkg-git/master/proton-tkg/proton-tkg.cfg"

            )
            # Extract selected key from fzf choice string for preview handling
            key=$(echo {} | cut -d"|" -f1 | xargs)
            # Handle preview content based on selected key
            [[ "$key" == "return" ]] && { glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/return.md"; exit 0; }
            _config_file_path="'${_config_dir}'/${key}.cfg"
            _remote_url="${remote_urls[$key]}"
            # Show config diff if local file exists, otherwise show error message for missing file
            if [[ -f "$_config_file_path" && -n "$_remote_url" ]]; then
                _remote_tmp="${_tmp_dir}/${key}-remote.cfg"
                # Fetch remote config file to temporary location and show diff with local file if successful
                if curl -fsSL "$_remote_url" -o "$_remote_tmp" 2>/dev/null; then
                    printf "%b\n" "'"${_info_config}"'"
                    '"${_diff_cmd}"' "$_remote_tmp" "${_config_file_path}" | '"${_bat_cmd}"'
                    rm -f "$_remote_tmp"
                else
                    printf "%b\n" "'"${_error_config_not_exist}"'"
                fi
            else
                printf "%b\n" "'"${_error_config_not_exist}"'"
            fi
        '

        # Define header, footer, border label, and preview window settings for fzf menu
        local _header_text="🐸 ${_green_neon}${_uline_on}TKG-Installer ─ Config menu (Beta)${_uline_off}${_reset}${_break}${_break}${_green_light}    ${_uline_on}Create${_uline_off}: ${_reset}${_gray}Download missing file(s)${_reset}${_break}${_green_light}    ${_uline_on}Edit${_uline_off}: ${_reset}${_gray}Customize to your preferred settings${_reset}${_break}    ${_green_light}${_uline_on}Compare${_uline_off}: ${_reset}${_gray}Show difference between remote and local${_reset}${_break}${_break}    ${_green_light}According to -TKG- package standards file(s)${_break}    stored in: ${_reset}${_gray}file://$HOME/.config/frogminer/${_break}${_break}    ${_green_light}Please make sure to adjust the settings correctly!${_break}    More visit: ${_reset}${_gray}https://github.com/Frogging-Family${_reset}${_break}${_break}${_break}   ${_green_light}Select an option below:"
        local _footer_text="  ${_green_light}Use arrow keys ⌨️ or mouse 🖱️ to navigate${_break}  Press [Enter] to select, [Ctrl+P] ${_green_light}to toggle the preview window, [ESC] to exit${_break}${_break}  ${_green_light}Website:${_reset} ${_gray}https://github.com/damachine/tkginstaller${_reset} | ${_gray}https://github.com/Frogging-Family"
        local _border_label_text="${_tkg_version}"
        local _preview_window_settings='right:wrap:75%'

        # Show fzf menu and get user selection
        _config_choice=$(__fzf_menu "$_menu_content" "$_preview_command" "$_header_text" "$_footer_text" "$_border_label_text" "$_preview_window_settings" "$_fzf_bind" )

        # Handle cancelled selection
        if [[ -z "$_config_choice" ]]; then
            __banner
            __msg_info_orange " Applying${_reset}${_gray} customization.cfg${_reset}${_orange} changes...${_break}"
            sleep 1.5s
            clear
            return 0
        fi

        # Extract selected configuration
        local _config_file
        _config_file=$(echo "${_config_choice}" | cut -d"|" -f1 | xargs)

        # Handle configuration file editing
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
    local _config_name="${1}"
    local _config_path="${2}"
    local _config_url="${3}"

    # Notify user about opening the configuration file editor
    __banner
    __msg_info_orange "Opening external configuration file:${_reset}${_gray} $_config_name${_break}"
    sleep 1.5s
    clear

    # Check if configuration file exists
    if [[ -f "${_config_path}" ]]; then
        # Edit existing configuration
        __editor "${_config_path}" || {
            clear
            __banner "$_red"
            __msg_error "Opening external configuration failed:${_reset}${_gray} ${_config_path}${_break}"
            __msg_plain " Please check if the file exists and is accessible.${_break}"
            __msg_prompt "Press any key to continue...${_break}"
            read -n 1 -s -r -p ""
            clear
            return 1
        }
    else
        # Download and create new configuration
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
            _user_answer="n"
        fi
        # Handle user response for downloading
        case "${_user_answer,,}" in
            y|yes)
                # Create the configuration directory
                mkdir -p "$(dirname "${_config_path}")" || {
                    clear
                    __banner "$_red"
                    __msg_error "Creating configuration directory failed: ${_config_path}${_break}"
                    __msg_plain " Please check the path and your permissions then try again.${_break}"
                    __msg_prompt "Press any key to continue...${_break}"
                    read -n 1 -s -r -p ""
                    clear
                    return 1
                }
                if ! command -v curl >/dev/null 2>&1; then
                    clear
                    __banner "$_red"
                    __msg_error "curl is not installed. Please install curl to download configuration files.${_break}"
                    __msg_prompt "Press any key to continue...${_break}"
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
                    # Open the downloaded
                    __editor "${_config_path}" || {
                        clear
                        __banner "$_orange"
                        __msg_error "Opening external configuration file:${_reset}${_gray} $_config_name${_break}"
                        __msg_plain " Please check if the file exists and is accessible.${_break}"
                        __msg_prompt "Press any key to continue...${_break}"
                        read -n 1 -s -r -p ""
                        clear
                        return 1
                    }
                else
                    # Failed to download
                    clear
                    __banner "$_red"
                    __msg_error "Downloading external configuration from ${_config_url} failed!${_break}"
                    __msg_plain " Please check your internet connection and try again.${_break}"
                    __msg_prompt "Press any key to continue...${_break}"
                    read -n 1 -s -r -p ""
                    clear
                    return 1
                fi
                ;;
            *)
                # Cancel download process
                clear
                __banner "$_orange"
                __msg_info_orange "Download cancelled. No configuration file created.${_break}"
                __msg_plain " No changes were made.${_break}"
                __msg_prompt "Press any key to continue...${_break}"
                read -n 1 -s -r -p "" # Wait for user input before exiting
                clear
                return 1
                ;;
        esac

        # Clear screen process
        clear
    fi

    # Notify user about closing the configuration file editor
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

# Interactive main menu with fzf preview
__menu() {
    # I DONT KNOW THIS WORKS BUT IT SHOULD. NOT TESTED YET.
    # Glow style detection
    if [[ -z "${_glow_style:-}" ]]; then
        case "${COLORTERM:-}${TERM:-}" in
            *light*|*xterm*|*rxvt*|*konsole*)
                _glow_style="light"
                ;;
            *)
                _glow_style="dark"
                ;;
        esac
    fi

    # Define menu options and preview commands for fzf menu
    local _menu_options=(
        "Linux  |🐧 ${_green_neon}Linux   ${_gray} Linux custom kernels for better desktop and gaming experience"
    )

    # Only show Nvidia and Mesa options if Arch-based distribution
    if [[ "${_distro_id,,}" =~ ^(arch|cachyos|manjaro|endeavouros)$ || "${_distro_like,,}" == *"arch"* ]]; then
        _menu_options+=(
            "Nvidia |💻 ${_green_neon}Nvidia  ${_gray} Nvidia open-source or proprietary graphics drivers"
            "Mesa   |🧩 ${_green_neon}Mesa    ${_gray} AMD and Intel open-source graphics driver"
        )
    fi

    _menu_options+=(
        "Wine   |🍷 ${_green_neon}Wine    ${_gray} Windows compatibility layer to run Windows apps on Linux"
        "Proton |🎮 ${_green_neon}Proton  ${_gray} Run Windows games on the Linux system via Steam"
        "Config |🔧 ${_green_neon}Config  ${_gray} Enter external configuration files menu (Expert)"
        "Clean  |🧹 ${_green_neon}Clean   ${_gray} Removes all temporary files for a clean installation"
        "Help   |❓ ${_green_neon}Help    ${_gray} Displays help and usage information about TKG-Installer"
        "Close  |❎ ${_green_neon}Close"
    )

    # Prepare menu content for fzf menu
    local _menu_content
    _menu_content=$(printf '%s\n' "${_menu_options[@]}")

    # Define preview command for fzf menu to show relevant markdown documentation using glow based on selection
    local _preview_command='
        key=$(echo {} | cut -d"|" -f1 | xargs)
        case $key in
            Linux*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/linux.md"
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_frog_raw_url}/linux-tkg/refs/heads/master/README.md"
                ;;
            Nvidia*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/nvidia.md"
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_frog_raw_url}/nvidia-all/refs/heads/master/README.md"
                ;;
            Mesa*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/mesa.md"
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_frog_raw_url}/mesa-git/refs/heads/master/README.md"
                ;;
            Wine*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/wine.md"
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_frog_raw_url}/wine-tkg-git/refs/heads/master/wine-tkg-git/README.md"
                ;;
            Proton*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/proton.md"
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_frog_raw_url}/wine-tkg-git/refs/heads/master/proton-tkg/README.md"
                ;;
            Config*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/config.md" ;;
            Clean*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/clean.md" ;;
            Help*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/help.md" ;;
            Close*)
                glow --pager --width 80 --style "${_glow_style:-dark}" "${_tkg_raw_url}/close.md" ;;
        esac
    '

    # Define header and footer texts, border label, and preview window
    local _header_text="🐸 ${_green_neon}${_uline_on}TKG-Installer ─ Main menu${_uline_off}${_reset}${_break}${_break}    ${_green_light}Install (clone, build) and customize -TKG- packages${_break}${_break}${_break}   Select an option below:"
    local _footer_text="  ${_green_light}Use arrow keys ⌨️ or mouse 🖱️ to navigate${_break}  Press [Enter] to select, [Ctrl+P] ${_green_light}to toggle the preview window, [ESC] to exit${_break}${_break}  ${_green_light}Website:${_reset} ${_gray}https://github.com/damachine/tkginstaller${_reset} | ${_gray}https://github.com/Frogging-Family"
    local _border_label_text="${_tkg_version}"
    local _preview_window_settings='right:wrap:55%:hidden'

    # Show fzf menu and get user selection
    local _main_choice
    _main_choice=$(__fzf_menu "$_menu_content" "$_preview_command" "$_header_text" "$_footer_text" "$_border_label_text" "$_preview_window_settings" "$_fzf_bind")

    # Handle cancelled selection (ESC pressed)
    if [[ -z "${_main_choice:-}" ]]; then
        clear
        __exit 0
    fi

    # Save selection to temporary file
    echo "$_main_choice" | cut -d"|" -f1 | xargs > "$_choice_file"
}

# =============================================================================
# MAIN PROGRAM ENTRY POINT
# =============================================================================

# Handle direct command-line arguments
__main_direct_mode() {
    local _arg1="${1,,}"  
    local _arg2="${2,,}"

    # Accept both [package] [config] and [config] [package]
    local _package=""
    local _config_arg=""

    # Check for config argument
    if [[ "$_arg1" =~ ^(config|c|edit|e)$ ]]; then
        _config_arg="$_arg1"
        case "$_arg2" in
            linux|l|--linux|-l) _package="linux-tkg" ;;
            nvidia|n|--nvidia|-n) _package="nvidia-all" ;;
            mesa|m|--mesa|-m) _package="mesa-git" ;;
            wine|w|--wine|-w) _package="wine-tkg" ;;
            proton|p|--proton|-p) _package="proton-tkg" ;;
        esac
    elif [[ "$_arg2" =~ ^(config|c|edit|e)$ ]]; then
        _config_arg="$_arg2"
        case "$_arg1" in
            linux|l|--linux|-l) _package="linux-tkg" ;;
            nvidia|n|--nvidia|-n) _package="nvidia-all" ;;
            mesa|m|--mesa|-m) _package="mesa-git" ;;
            wine|w|--wine|-w) _package="wine-tkg" ;;
            proton|p|--proton|-p) _package="proton-tkg" ;;
        esac
    fi

    # Handle config editing
    if [[ -n "$_package" && -n "$_config_arg" ]]; then
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

        # Disable exit trap
        trap - INT TERM EXIT HUP

        # Handle config file editing
        __handle_config "$_config_name" "$_config_path" "$_config_url"

        # Display exit messages
        __banner
        __msg_plain "${_green_mint}Closed.${_break}"

        # Clean exit
        __clean
        exit 0
    fi

    # Handle regular install commands
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
            # Handle help command
            ;;
        *)
            # Invalid argument handling and usage instructions display
            __banner "$_orange"
            __msg_warning "Invalid argument:${_reset}${_gray} ${1:-} ${2:-}${_reset}${_break}"
            __msg_plain " The argument is either invalid or incomplete."
            __msg_plain " All available arguments run:${_break}"
            __msg_plain "$0 help${_break}"

            # Disable exit trap before cleanup
            trap - INT TERM EXIT HUP
            __clean
            exit 1
            ;;
    esac
}

# Main function for interactive mode
__main_interactive_mode() {
    __prepare true
    clear
    __menu

    # Process user selection from menu until exit is chosen
    local _user_choice
    _user_choice=$(< "$_choice_file")

    # Remove temporary choice file after reading user choice
    rm -f "$_choice_file" 2>&1 || true

    # Handle user choice from menu using case statement
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
            rm -f "$_lock_file"
            # Restart the script after editing config
            clear
            exec "$0"
            ;;
        Help)
            # Remove exit trap to avoid cleanup
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
            exit 0
            ;;
    esac
}

# Main function - handles command line arguments and menu interaction
__main() {
    if [[ $# -gt 0 ]]; then
        __main_direct_mode "$@"
    else
        __main_interactive_mode
    fi
}

# SCRIPT EXECUTION ENTRY POINT
__main "$@" 
