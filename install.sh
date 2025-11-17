#!/usr/bin/env bash
# install.sh - TKG-Installer automated installation with verification
# Usage: curl -fsSL https://raw.githubusercontent.com/damachine/tkginstaller/master/install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Configuration
REPO_URL="https://raw.githubusercontent.com/damachine/tkginstaller/master"
INSTALL_DIR="${HOME}/bin"
SCRIPT_NAME="tkginstaller"

# Functions
msg_info() { printf "${GREEN}%s${RESET}\n" "$*"; }
msg_error() { printf "${RED}ERROR: %s${RESET}\n" "$*"; }
msg_warning() { printf "${ORANGE}WARNING: %s${RESET}\n" "$*"; }
msg_step() { printf "${CYAN}➜ %s${RESET}\n" "$*"; }

banner() {
    cat << "EOF"
░▀█▀░█░█░█▀▀░░░░░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░░█▀▀░█▀▄
░░█░░█▀▄░█░█░▄▄▄░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░░█▀▀░█▀▄
░░▀░░▀░▀░▀▀▀░░░░░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀
EOF
}

cleanup() {
    cd "$OLDPWD" 2>/dev/null || true
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT INT TERM

# Main installation
main() {
    banner
    echo ""
    msg_info "🐸 TKG-Installer - Automated Installation"
    echo ""

    # Check dependencies
    msg_step "Checking dependencies..."
    for cmd in curl sha256sum; do
        if ! command -v "$cmd" &>/dev/null; then
            msg_error "$cmd is not installed!"
            exit 1
        fi
    done
    msg_info "✓ Dependencies OK"
    echo ""

    # Create installation directory
    msg_step "Creating installation directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"

    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # Download files
    msg_step "Downloading tkginstaller..."
    if ! curl -fsSL "${REPO_URL}/${SCRIPT_NAME}" -o "${SCRIPT_NAME}"; then
        msg_error "Failed to download tkginstaller"
        exit 1
    fi

    msg_step "Downloading checksum..."
    if ! curl -fsSL "${REPO_URL}/${SCRIPT_NAME}.sha256sum" -o "${SCRIPT_NAME}.sha256sum"; then
        msg_error "Failed to download checksum file"
        exit 1
    fi
    msg_info "✓ Download complete"
    echo ""

    # Verify checksum
    msg_step "Verifying integrity..."
    echo ""
    if sha256sum -c "${SCRIPT_NAME}.sha256sum" 2>&1 | grep -q "OK"; then
        msg_info "✓ Checksum verification successful!"
    else
        msg_error "Checksum verification FAILED!"
        echo ""
        msg_warning "The downloaded file does not match the expected checksum."
        msg_warning "This could indicate:"
        msg_warning "  - File corruption during download"
        msg_warning "  - Security compromise"
        msg_warning "  - Network issues"
        echo ""
        msg_error "Installation aborted for security reasons."
        exit 1
    fi
    echo ""

    # Move to installation directory
    msg_step "Installing to $INSTALL_DIR..."
    mv "${SCRIPT_NAME}" "${INSTALL_DIR}/"
    mv "${SCRIPT_NAME}.sha256sum" "${INSTALL_DIR}/"
    chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}"
    msg_info "✓ Installation complete"
    echo ""

    # Setup shell alias
    msg_step "Setting up shell alias..."
    
    # Detect shell
    SHELL_RC=""
    if [[ -n "${BASH_VERSION:-}" ]]; then
        SHELL_RC="${HOME}/.bashrc"
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        SHELL_RC="${HOME}/.zshrc"
    elif [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="${HOME}/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_RC="${HOME}/.bashrc"
    fi

    if [[ -n "$SHELL_RC" ]]; then
        # Check if alias already exists
        if grep -q "alias ${SCRIPT_NAME}=" "$SHELL_RC" 2>/dev/null; then
            msg_info "✓ Alias already exists in $SHELL_RC"
        else
            echo "" >> "$SHELL_RC"
            echo "# TKG-Installer alias" >> "$SHELL_RC"
            echo "alias ${SCRIPT_NAME}='${INSTALL_DIR}/${SCRIPT_NAME}'" >> "$SHELL_RC"
            msg_info "✓ Alias added to $SHELL_RC"
        fi
        echo ""
        msg_warning "Run the following command to activate the alias:"
        echo "  source $SHELL_RC"
    else
        msg_warning "Could not detect shell configuration file."
        msg_warning "Add this manually to your shell config:"
        echo "  alias ${SCRIPT_NAME}='${INSTALL_DIR}/${SCRIPT_NAME}'"
    fi

    echo ""
    msg_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    msg_info "✓ Installation successful!"
    msg_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Next steps:"
    echo "  1. Reload your shell config:"
    if [[ -n "$SHELL_RC" ]]; then
        echo "     source $SHELL_RC"
    fi
    echo "  2. Run the installer:"
    echo "     ${SCRIPT_NAME}"
    echo ""
    echo "Documentation: https://github.com/damachine/tkginstaller"
    echo ""
}

# Run main
main