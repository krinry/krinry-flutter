#!/bin/bash
# krinry flutter - Install Flutter Command

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
    if is_termux; then
        print_info "Detected Termux environment"
        install_flutter_termux
    else
        # Detect OS for non-Termux
        case "$(uname -s)" in
            Linux*)  
                print_info "Detected Linux"
                install_flutter_linux
                ;;
            Darwin*) 
                print_info "Detected macOS"
                install_flutter_macos
                ;;
            *)
                die "Unsupported platform: $(uname -s)"
                ;;
        esac
    fi
}

install_flutter_termux() {
    print_header "Installing Flutter for Termux"
    
    # METHOD 1: Try Termux Void repo (recommended, pre-built for Termux)
    print_step "Setting up Termux Void repository..."
    
    # Install dependencies first
    print_step "Installing dependencies..."
    pkg install -y git curl wget 2>/dev/null || true
    
    # Check if flutter is available via pkg (Termux Void repo)
    print_step "Checking for Flutter package..."
    
    # Add Termux Void repo if not added
    local sources_list="${PREFIX}/etc/apt/sources.list.d"
    local void_repo="${sources_list}/termux-void.list"
    
    if [[ ! -f "$void_repo" ]]; then
        print_step "Adding Termux Void repository..."
        mkdir -p "$sources_list" 2>/dev/null || true
        
        # Add the void repo
        echo "deb https://termuxvoid.github.io/repo termux main" > "$void_repo" 2>/dev/null || {
            # Try alternate method
            echo "deb [trusted=yes] https://termuxvoid.github.io/repo termux main" > "$void_repo"
        }
    fi
    
    # Update and try to install flutter
    print_step "Updating package lists..."
    pkg update -y 2>/dev/null || apt update -y 2>/dev/null || true
    
    print_step "Installing Flutter from Termux Void repo..."
    if pkg install flutter -y 2>/dev/null || apt install flutter -y 2>/dev/null; then
        print_success "Flutter installed from Termux Void repo!"
        
        # Verify
        print_step "Verifying installation..."
        if command -v flutter &>/dev/null; then
            echo ""
            flutter --version
            echo ""
            print_success "Flutter is ready!"
            echo ""
            echo "Next steps:"
            echo "  1. Run: flutter doctor"
            echo "  2. Create app: flutter create myapp"
            echo "  3. Build: krinry flutter build apk --release"
            return 0
        fi
    fi
    
    # METHOD 2: If pkg install fails, try dpkg method
    print_warning "Package install failed, trying alternate method..."
    install_flutter_termux_deb
}

install_flutter_termux_deb() {
    print_step "Downloading Flutter .deb package..."
    
    local deb_url="https://github.com/AryaXAI/flutter-termux/releases/latest/download/flutter.deb"
    local deb_file="${PREFIX}/tmp/flutter.deb"
    
    # Try to download .deb
    if curl -fsSL "$deb_url" -o "$deb_file" 2>/dev/null || \
       wget -q "$deb_url" -O "$deb_file" 2>/dev/null; then
        
        print_step "Installing Flutter .deb package..."
        if dpkg -i "$deb_file" 2>/dev/null; then
            rm -f "$deb_file" 2>/dev/null
            print_success "Flutter installed from .deb!"
            
            # Verify
            if command -v flutter &>/dev/null; then
                echo ""
                flutter --version
                echo ""
                print_success "Flutter is ready!"
                return 0
            fi
        else
            # Fix dependencies
            apt --fix-broken install -y 2>/dev/null || true
            if command -v flutter &>/dev/null; then
                print_success "Flutter installed!"
                return 0
            fi
        fi
    fi
    
    # METHOD 3: Manual installation guide
    print_error "Automatic installation failed"
    echo ""
    echo "Please try manual installation:"
    echo ""
    echo "Option 1: Termux Void repo"
    echo "  1. Add repo: pkg install tur-repo"
    echo "  2. Install: pkg install flutter"
    echo ""
    echo "Option 2: From .deb file"
    echo "  1. Download flutter.deb from:"
    echo "     https://github.com/AryaXAI/flutter-termux/releases"
    echo "  2. Install: dpkg -i flutter.deb"
    echo "  3. Fix deps: apt --fix-broken install"
    echo ""
    exit 1
}

install_flutter_linux() {
    print_header "Installing Flutter SDK"
    
    ensure_dir "${KRINRY_HOME}"
    
    local flutter_tar="${KRINRY_HOME}/flutter.tar.xz"
    local flutter_url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.3-stable.tar.xz"
    
    # Remove old installation
    rm -rf "${FLUTTER_HOME}" 2>/dev/null || true
    
    print_step "Downloading Flutter SDK..."
    if ! download_file "$flutter_url" "$flutter_tar"; then
        die "Failed to download Flutter SDK"
    fi
    
    print_step "Extracting Flutter SDK..."
    cd "${KRINRY_HOME}"
    tar -xf "$flutter_tar"
    rm -f "$flutter_tar" 2>/dev/null || true
    
    setup_flutter_path
    verify_flutter_install
}

install_flutter_macos() {
    print_header "Installing Flutter SDK"
    
    ensure_dir "${KRINRY_HOME}"
    
    local flutter_zip="${KRINRY_HOME}/flutter.zip"
    local flutter_url="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.27.3-stable.zip"
    
    # Remove old installation
    rm -rf "${FLUTTER_HOME}" 2>/dev/null || true
    
    print_step "Downloading Flutter SDK..."
    if ! download_file "$flutter_url" "$flutter_zip"; then
        die "Failed to download Flutter SDK"
    fi
    
    print_step "Extracting Flutter SDK..."
    cd "${KRINRY_HOME}"
    unzip -q "$flutter_zip"
    rm -f "$flutter_zip" 2>/dev/null || true
    
    setup_flutter_path
    verify_flutter_install
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
    if grep -q "flutter/bin" "$shell_rc" 2>/dev/null; then
        print_info "PATH already configured"
        return
    fi
    
    # Add to PATH
    echo "" >> "$shell_rc"
    echo "# Flutter SDK (krinry)" >> "$shell_rc"
    echo "export PATH=\"${flutter_bin}:\$PATH\"" >> "$shell_rc"
    
    # Export for current session
    export PATH="${flutter_bin}:$PATH"
    
    print_success "PATH configured in ${shell_rc}"
    print_warning "Run 'source ${shell_rc}' or restart terminal"
}

verify_flutter_install() {
    print_step "Verifying installation..."
    
    if command -v flutter &>/dev/null || [[ -f "${FLUTTER_HOME}/bin/flutter" ]]; then
        print_success "Flutter installed successfully!"
        echo ""
        flutter --version 2>/dev/null || "${FLUTTER_HOME}/bin/flutter" --version
        echo ""
        print_info "Run 'flutter doctor' to check your setup"
    else
        die "Flutter installation failed. Please try again."
    fi
}
