#!/bin/bash
# krinry-flutter - Install Flutter Command

cmd_install_flutter() {
    print_header "Install Flutter SDK"
    
    # Check if Flutter is already installed
    if is_flutter_installed; then
        local current_version
        current_version=$(get_flutter_version)
        print_success "Flutter is already installed!"
        echo "  Version: ${current_version}"
        echo ""
        
        if ask_yes_no "Do you want to reinstall/update Flutter?"; then
            print_info "Proceeding with reinstall..."
        else
            print_info "Keeping existing installation"
            echo ""
            echo "Run 'flutter doctor' to check your setup"
            exit 0
        fi
    fi
    
    # Check internet connection
    print_step "Checking internet connection..."
    if ! check_internet; then
        die "No internet connection. Please check your network."
    fi
    print_success "Internet connection OK"
    
    # Detect platform
    local platform=""
    local flutter_url=""
    
    if is_termux; then
        print_info "Detected Termux environment"
        platform="termux"
        # For Termux, we'll install from pkg if available, otherwise manual
    else
        # Detect OS for non-Termux
        case "$(uname -s)" in
            Linux*)  platform="linux" ;;
            Darwin*) platform="macos" ;;
            *)       platform="unknown" ;;
        esac
        print_info "Detected platform: ${platform}"
    fi
    
    # Create installation directory
    print_step "Creating installation directory..."
    ensure_dir "${KRINRY_HOME}"
    
    if [[ "$platform" == "termux" ]]; then
        install_flutter_termux
    else
        install_flutter_generic
    fi
    
    # Setup PATH
    setup_flutter_path
    
    # Verify installation
    print_step "Verifying installation..."
    if [[ -f "${FLUTTER_HOME}/bin/flutter" ]]; then
        print_success "Flutter installed successfully!"
        echo ""
        "${FLUTTER_HOME}/bin/flutter" --version
        echo ""
        print_info "Run 'krinry-flutter doctor' to check your setup"
    else
        die "Flutter installation failed. Please try again."
    fi
}

install_flutter_termux() {
    print_header "Installing Flutter for Termux"
    
    # Check if flutter is available via pkg
    print_step "Checking for Flutter in Termux packages..."
    
    # Update pkg first
    print_step "Updating package lists..."
    pkg update -y 2>/dev/null || true
    
    # Try to install required dependencies
    print_step "Installing dependencies..."
    pkg install -y git curl unzip 2>/dev/null || true
    
    # Download Flutter SDK
    print_step "Downloading Flutter SDK (this may take a while)..."
    
    local flutter_tar="${KRINRY_HOME}/flutter.tar.xz"
    local flutter_url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.3-stable.tar.xz"
    
    # Remove old installation if exists
    rm -rf "${FLUTTER_HOME}" 2>/dev/null || true
    
    if ! download_file "$flutter_url" "$flutter_tar"; then
        die "Failed to download Flutter SDK"
    fi
    
    print_step "Extracting Flutter SDK..."
    cd "${KRINRY_HOME}"
    tar -xf "$flutter_tar" 2>/dev/null || {
        # Try with xz directly if tar fails
        xz -d "$flutter_tar" 2>/dev/null
        tar -xf "${flutter_tar%.xz}" 2>/dev/null
    }
    
    # Cleanup
    rm -f "$flutter_tar" "${flutter_tar%.xz}" 2>/dev/null || true
    
    print_success "Flutter SDK extracted"
}

install_flutter_generic() {
    print_header "Installing Flutter SDK"
    
    local flutter_tar="${KRINRY_HOME}/flutter.tar.xz"
    local flutter_url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.3-stable.tar.xz"
    
    # macOS uses zip
    if [[ "$(uname -s)" == "Darwin" ]]; then
        flutter_url="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.27.3-stable.zip"
        flutter_tar="${KRINRY_HOME}/flutter.zip"
    fi
    
    # Remove old installation if exists
    rm -rf "${FLUTTER_HOME}" 2>/dev/null || true
    
    print_step "Downloading Flutter SDK..."
    if ! download_file "$flutter_url" "$flutter_tar"; then
        die "Failed to download Flutter SDK"
    fi
    
    print_step "Extracting Flutter SDK..."
    cd "${KRINRY_HOME}"
    
    if [[ "$flutter_tar" == *.zip ]]; then
        unzip -q "$flutter_tar"
    else
        tar -xf "$flutter_tar"
    fi
    
    # Cleanup
    rm -f "$flutter_tar" 2>/dev/null || true
    
    print_success "Flutter SDK extracted"
}

setup_flutter_path() {
    print_step "Configuring PATH..."
    
    local flutter_bin="${FLUTTER_HOME}/bin"
    local shell_rc=""
    
    # Determine shell config file
    if [[ -n "$BASH_VERSION" ]]; then
        shell_rc="${HOME}/.bashrc"
    elif [[ -n "$ZSH_VERSION" ]]; then
        shell_rc="${HOME}/.zshrc"
    else
        shell_rc="${HOME}/.profile"
    fi
    
    # Check if already in PATH
    if grep -q "krinry-flutter/flutter/bin" "$shell_rc" 2>/dev/null; then
        print_info "PATH already configured"
        return
    fi
    
    # Add to PATH
    echo "" >> "$shell_rc"
    echo "# krinry-flutter - Flutter SDK" >> "$shell_rc"
    echo "export PATH=\"${flutter_bin}:\$PATH\"" >> "$shell_rc"
    
    # Also export for current session
    export PATH="${flutter_bin}:$PATH"
    
    print_success "PATH configured in ${shell_rc}"
    print_warning "Please run 'source ${shell_rc}' or restart your terminal"
}
