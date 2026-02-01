#!/bin/bash
# krinry - Generic Package Install Command
# Installs packages with krinry branding

cmd_install_package() {
    local package="$1"
    
    if [[ -z "$package" ]]; then
        print_error "No package specified"
        echo "Usage: krinry install <package>"
        exit 1
    fi
    
    # Handle special package bundles
    case "$package" in
        shell-tools|shell)
            install_shell_tools
            return
            ;;
        fish)
            install_fish_shell
            return
            ;;
        zsh)
            install_zsh_shell
            return
            ;;
        oh-my-zsh|ohmyzsh)
            install_oh_my_zsh
            return
            ;;
        thefuck|fuck)
            install_thefuck
            return
            ;;
    esac
    
    print_header "Installing ${package}"
    
    # Check if Termux
    if ! is_termux; then
        print_warning "This command is designed for Termux"
        echo "On other systems, use your package manager directly"
        exit 1
    fi
    
    # Setup TermuxVoid repo silently if not already added
    setup_termuxvoid_repo
    
    # Install the package
    print_step "Installing ${package}..."
    
    if pkg install "$package" -y 2>/dev/null; then
        print_success "${package} installed successfully!"
        echo ""
        
        # Show post-install tips for common packages
        case "$package" in
            neovim|nvim)
                echo "Run: nvim <filename>"
                echo "Press 'i' to insert, ':wq' to save & quit"
                ;;
            micro)
                echo "Run: micro <filename>"
                echo "Ctrl+S to save, Ctrl+Q to quit"
                ;;
            vim)
                echo "Run: vim <filename>"
                echo "Press 'i' to insert, ':wq' to save & quit"
                ;;
            nano)
                echo "Run: nano <filename>"
                echo "Ctrl+O to save, Ctrl+X to quit"
                ;;
        esac
        
        echo ""
        echo -e "${DIM}Powered by krinry • Package from TermuxVoid${NC}"
    else
        print_error "Failed to install ${package}"
        echo ""
        echo "Try updating packages first:"
        echo "  pkg update && pkg upgrade"
        exit 1
    fi
}

setup_termuxvoid_repo() {
    # Check if repo already added
    if [[ -f "${PREFIX}/etc/apt/sources.list.d/termuxvoid.list" ]]; then
        return 0
    fi
    
    print_step "Setting up package repository..."
    
    # Silently add TermuxVoid repo
    curl -sL https://termuxvoid.github.io/repo/install.sh 2>/dev/null | bash >/dev/null 2>&1
    
    # Update package lists
    pkg update -y >/dev/null 2>&1 || true
    
    print_success "Repository configured"
}

# ============ Shell Tools Bundle ============

install_shell_tools() {
    print_header "Installing Shell Tools Bundle"
    echo -e "${DIM}Auto-suggestions, command correction, fuzzy finder${NC}"
    echo ""
    
    if ! is_termux; then
        die "This command is designed for Termux"
    fi
    
    setup_termuxvoid_repo
    
    local tools=("fish" "fzf" "zsh")
    local installed=0
    
    for tool in "${tools[@]}"; do
        print_step "Installing ${tool}..."
        if pkg install "$tool" -y >/dev/null 2>&1; then
            print_success "${tool} installed"
            ((installed++))
        else
            print_warning "Could not install ${tool}"
        fi
    done
    
    # Install thefuck via pip
    print_step "Installing thefuck (command correction)..."
    if pkg install python -y >/dev/null 2>&1; then
        pip install thefuck >/dev/null 2>&1 && print_success "thefuck installed" || print_warning "thefuck failed"
    fi
    
    echo ""
    print_success "Shell tools installed! (${installed}/${#tools[@]})"
    echo ""
    echo -e "${BOLD}Recommended: Switch to Fish shell${NC}"
    echo "  Run: chsh -s fish"
    echo "  Then restart Termux"
    echo ""
    echo -e "${BOLD}Fish Features:${NC}"
    echo "  • Tab → Auto-complete commands"
    echo "  • Type → Shows suggestions in gray"
    echo "  • ↑↓  → Browse command history"
    echo "  • Ctrl+R → Fuzzy search history (fzf)"
    echo ""
    echo -e "${BOLD}TheFuck Usage:${NC}"
    echo "  Type wrong command, then type 'fuck' to fix it"
    echo "  Add to ~/.bashrc: eval \$(thefuck --alias)"
    echo ""
    echo -e "${DIM}Powered by krinry${NC}"
}

install_fish_shell() {
    print_header "Installing Fish Shell"
    echo -e "${DIM}The Friendly Interactive SHell${NC}"
    echo ""
    
    if ! is_termux; then
        die "This command is designed for Termux"
    fi
    
    setup_termuxvoid_repo
    
    print_step "Installing fish..."
    if pkg install fish -y 2>/dev/null; then
        print_success "Fish shell installed!"
        echo ""
        echo -e "${BOLD}Features:${NC}"
        echo "  • Auto-suggestions as you type"
        echo "  • Syntax highlighting"
        echo "  • Tab completion for everything"
        echo "  • Web-based configuration"
        echo ""
        echo -e "${BOLD}To use Fish:${NC}"
        echo "  Temporary: fish"
        echo "  Permanent: chsh -s fish"
        echo ""
        echo -e "${BOLD}Pro Tip:${NC}"
        echo "  Install Oh My Fish for themes:"
        echo "  curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish"
        echo ""
        echo -e "${DIM}Powered by krinry${NC}"
    else
        print_error "Failed to install fish"
        exit 1
    fi
}

install_zsh_shell() {
    print_header "Installing Zsh Shell"
    echo -e "${DIM}Z Shell with powerful features${NC}"
    echo ""
    
    if ! is_termux; then
        die "This command is designed for Termux"
    fi
    
    setup_termuxvoid_repo
    
    print_step "Installing zsh..."
    if pkg install zsh -y 2>/dev/null; then
        print_success "Zsh installed!"
        echo ""
        echo -e "${BOLD}Next Step:${NC}"
        echo "  Install Oh My Zsh for themes & plugins:"
        echo "  krinry install oh-my-zsh"
        echo ""
        echo "  Or manually:"
        echo "  sh -c \"\$(curl -fsSL https://install.ohmyz.sh/)\""
        echo ""
        echo -e "${DIM}Powered by krinry${NC}"
    else
        print_error "Failed to install zsh"
        exit 1
    fi
}

install_oh_my_zsh() {
    print_header "Installing Oh My Zsh"
    echo -e "${DIM}Framework for managing Zsh configuration${NC}"
    echo ""
    
    if ! is_termux; then
        die "This command is designed for Termux"
    fi
    
    # Check if zsh is installed
    if ! command -v zsh &>/dev/null; then
        print_step "Installing zsh first..."
        pkg install zsh git curl -y >/dev/null 2>&1
    fi
    
    print_step "Installing Oh My Zsh..."
    
    # Install Oh My Zsh
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null; then
        print_success "Oh My Zsh installed!"
        echo ""
        echo -e "${BOLD}Recommended Plugins:${NC}"
        echo "  Edit ~/.zshrc and add to plugins=():"
        echo "  • git"
        echo "  • zsh-autosuggestions"
        echo "  • zsh-syntax-highlighting"
        echo ""
        echo -e "${BOLD}Install popular plugins:${NC}"
        echo "  git clone https://github.com/zsh-users/zsh-autosuggestions \${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
        echo "  git clone https://github.com/zsh-users/zsh-syntax-highlighting \${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
        echo ""
        echo -e "${BOLD}To use Zsh:${NC}"
        echo "  chsh -s zsh"
        echo ""
        echo -e "${DIM}Powered by krinry${NC}"
    else
        print_error "Oh My Zsh installation failed"
        exit 1
    fi
}

install_thefuck() {
    print_header "Installing TheFuck"
    echo -e "${DIM}Magnificent app that corrects your commands${NC}"
    echo ""
    
    if ! is_termux; then
        die "This command is designed for Termux"
    fi
    
    # Install python if needed
    print_step "Installing dependencies..."
    pkg install python -y >/dev/null 2>&1
    
    print_step "Installing thefuck via pip..."
    if pip install thefuck 2>/dev/null; then
        print_success "TheFuck installed!"
        echo ""
        echo -e "${BOLD}Setup:${NC}"
        echo "  Add to your ~/.bashrc or ~/.zshrc:"
        echo "  eval \$(thefuck --alias)"
        echo ""
        echo -e "${BOLD}Usage:${NC}"
        echo "  1. Type a wrong command: gti status"
        echo "  2. Type: fuck"
        echo "  3. It suggests: git status"
        echo "  4. Press Enter to run"
        echo ""
        echo -e "${BOLD}Alias:${NC}"
        echo "  You can also use: eval \$(thefuck --alias wtf)"
        echo "  Then type 'wtf' instead of 'fuck'"
        echo ""
        echo -e "${DIM}Powered by krinry${NC}"
    else
        print_error "TheFuck installation failed"
        echo "Try: pip install thefuck"
        exit 1
    fi
}
