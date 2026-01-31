#!/bin/bash
# krinry-flutter Installer
# One-line installation: curl -fsSL https://raw.githubusercontent.com/krinry/krinry-flutter/main/install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_step() { echo -e "${CYAN}→${NC} $1"; }

# Banner
echo ""
echo -e "${BOLD}${CYAN}"
echo "  _          _                       __ _       _   _            "
echo " | | ___ __ (_)_ __  _ __ _   _     / _| |_   _| |_| |_ ___ _ __ "
echo " | |/ / '__|| | '_ \| '__| | | |___| |_| | | | | __| __/ _ \ '__|"
echo " |   <| |   | | | | | |  | |_| |___|  _| | |_| | |_| ||  __/ |   "
echo " |_|\_\_|   |_|_| |_|_|   \__, |   |_| |_|\__,_|\__|\__\___|_|   "
echo "                          |___/                                   "
echo -e "${NC}"
echo -e "${BOLD}Mobile-first Flutter CLI for Termux${NC}"
echo ""

# Detect Termux
is_termux() {
    [[ -n "$PREFIX" && "$PREFIX" == *"com.termux"* ]]
}

# Check if command exists
check_cmd() {
    command -v "$1" &> /dev/null
}

# Install directory
INSTALL_DIR="${HOME}/.krinry-flutter"
REPO_URL="https://github.com/krinry/krinry-flutter.git"

# Detect environment
if is_termux; then
    print_info "Detected: Termux on Android"
    BIN_DIR="$PREFIX/bin"
else
    print_info "Detected: $(uname -s)"
    BIN_DIR="${HOME}/.local/bin"
fi

# Install dependencies
print_step "Checking dependencies..."

install_pkg() {
    local pkg="$1"
    if is_termux; then
        pkg install -y "$pkg" 2>/dev/null || true
    elif check_cmd apt-get; then
        sudo apt-get install -y "$pkg" 2>/dev/null || true
    elif check_cmd brew; then
        brew install "$pkg" 2>/dev/null || true
    fi
}

# Git
if ! check_cmd git; then
    print_step "Installing git..."
    install_pkg git
fi
if check_cmd git; then
    print_success "git installed"
else
    print_error "Failed to install git"
    exit 1
fi

# curl
if ! check_cmd curl; then
    print_step "Installing curl..."
    install_pkg curl
fi
if check_cmd curl; then
    print_success "curl installed"
else
    print_error "Failed to install curl"
    exit 1
fi

# GitHub CLI
if ! check_cmd gh; then
    print_step "Installing GitHub CLI..."
    if is_termux; then
        pkg install -y gh 2>/dev/null || true
    elif check_cmd apt-get; then
        # Ubuntu/Debian
        (type -p wget >/dev/null || sudo apt install wget -y) \
        && sudo mkdir -p -m 755 /etc/apt/keyrings \
        && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
        && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && sudo apt update \
        && sudo apt install gh -y 2>/dev/null || true
    elif check_cmd brew; then
        brew install gh 2>/dev/null || true
    fi
fi
if check_cmd gh; then
    print_success "GitHub CLI installed"
else
    print_warning "GitHub CLI not installed. Install manually: https://cli.github.com"
fi

# jq (optional)
if ! check_cmd jq; then
    print_step "Installing jq..."
    install_pkg jq
fi
if check_cmd jq; then
    print_success "jq installed"
else
    print_warning "jq not installed (optional)"
fi

# termux-api (for Termux - enables auto browser open)
if is_termux; then
    if ! check_cmd termux-open-url; then
        print_step "Installing termux-api (for auto browser open)..."
        pkg install -y termux-api 2>/dev/null || true
    fi
    if check_cmd termux-open-url; then
        print_success "termux-api installed"
    else
        print_warning "termux-api not installed (optional, for 'run web' auto-open)"
    fi
fi

# Clone or update repository
print_step "Installing krinry-flutter..."

if [[ -d "$INSTALL_DIR" ]]; then
    print_info "Updating existing installation..."
    cd "$INSTALL_DIR"
    git pull origin main 2>/dev/null || git pull 2>/dev/null || true
else
    print_info "Cloning repository..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Make scripts executable
chmod +x "$INSTALL_DIR/bin/krinry-flutter"
chmod +x "$INSTALL_DIR/lib/"*.sh 2>/dev/null || true

# Create bin directory if needed
mkdir -p "$BIN_DIR"

# Create symlink
print_step "Creating symlink..."
ln -sf "$INSTALL_DIR/bin/krinry-flutter" "$BIN_DIR/krinry-flutter"
print_success "Symlink created at $BIN_DIR/krinry-flutter"

# Add to PATH if needed
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    print_step "Adding to PATH..."
    
    SHELL_RC=""
    if [[ -n "$BASH_VERSION" ]]; then
        SHELL_RC="${HOME}/.bashrc"
    elif [[ -n "$ZSH_VERSION" ]]; then
        SHELL_RC="${HOME}/.zshrc"
    else
        SHELL_RC="${HOME}/.profile"
    fi
    
    if ! grep -q "$BIN_DIR" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# krinry-flutter" >> "$SHELL_RC"
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_RC"
        print_success "Added to $SHELL_RC"
    fi
    
    export PATH="$BIN_DIR:$PATH"
fi

# GitHub auth check
echo ""
print_step "Checking GitHub authentication..."
if gh auth status &>/dev/null; then
    print_success "GitHub authenticated"
else
    print_warning "Not logged into GitHub"
    echo ""
    echo "To use cloud builds, please authenticate:"
    echo "  gh auth login"
    echo ""
fi

# Done!
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓${NC} ${BOLD}krinry-flutter installed successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Quick start:"
echo "  krinry-flutter --help         Show all commands"
echo "  krinry-flutter install flutter Install Flutter SDK"
echo "  krinry-flutter doctor          Check your setup"
echo ""
echo "In a Flutter project:"
echo "  krinry-flutter init            Setup cloud build"
echo "  krinry-flutter build apk       Build APK in cloud"
echo ""
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    print_warning "Please restart your terminal or run:"
    echo "  source ${SHELL_RC}"
    echo ""
fi
