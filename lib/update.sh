#!/bin/bash
# krinry-flutter - Update Command

cmd_update() {
    print_header "Update krinry-flutter"
    
    local install_dir="${HOME}/.krinry-flutter"
    
    if [[ ! -d "$install_dir" ]]; then
        die "krinry-flutter not installed at ${install_dir}. Please reinstall."
    fi
    
    print_step "Checking for updates..."
    
    cd "$install_dir"
    
    # Fetch latest
    if ! git fetch origin main 2>/dev/null; then
        die "Failed to fetch updates. Check your internet connection."
    fi
    
    # Check if updates available
    local local_hash remote_hash
    local_hash=$(git rev-parse HEAD 2>/dev/null)
    remote_hash=$(git rev-parse origin/main 2>/dev/null)
    
    if [[ "$local_hash" == "$remote_hash" ]]; then
        print_success "Already up to date!"
        echo ""
        echo "Version: ${VERSION}"
        exit 0
    fi
    
    print_info "Updates available!"
    echo ""
    
    # Show changes
    print_step "Changes:"
    git log --oneline HEAD..origin/main 2>/dev/null | head -10
    echo ""
    
    # Pull updates
    print_step "Updating..."
    if git pull origin main 2>/dev/null; then
        print_success "Updated successfully!"
        echo ""
        
        # Make sure scripts are executable
        chmod +x "${install_dir}/bin/krinry-flutter" 2>/dev/null || true
        chmod +x "${install_dir}/lib/"*.sh 2>/dev/null || true
        
        echo "Restart your terminal or run:"
        echo "  source ~/.bashrc"
        echo ""
    else
        print_error "Update failed"
        echo "Try reinstalling:"
        echo "  curl -fsSL https://raw.githubusercontent.com/krinry/krinry-flutter/main/install.sh | bash"
        exit 1
    fi
}
