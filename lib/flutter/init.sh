#!/bin/bash
# krinry flutter - Init Command

cmd_init() {
    print_header "Initialize krinry flutter"
    
    # Check if in Flutter project
    if ! is_flutter_project; then
        die "Not a Flutter project. Please run this in a Flutter project directory."
    fi
    print_success "Flutter project detected"
    
    # Check if git repo
    if ! is_git_repo; then
        print_warning "Not a git repository"
        if ask_yes_no "Initialize git repository?"; then
            git init
            print_success "Git repository initialized"
        else
            die "Git repository required for cloud builds"
        fi
    fi
    print_success "Git repository detected"
    
    # Check remote
    local remote_url
    remote_url=$(get_remote_url)
    if [[ -z "$remote_url" ]]; then
        print_warning "No GitHub remote configured"
        echo ""
        echo "Please add a GitHub remote:"
        echo "  git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
        echo ""
        die "GitHub remote required for cloud builds"
    fi
    
    # Verify it's a GitHub URL
    if [[ "$remote_url" != *"github.com"* ]]; then
        print_warning "Remote doesn't appear to be GitHub: ${remote_url}"
        echo "krinry currently only supports GitHub for cloud builds"
        if ! ask_yes_no "Continue anyway?"; then
            exit 1
        fi
    fi
    print_success "GitHub remote: ${remote_url}"
    
    # Create workflow directory
    print_step "Setting up GitHub Actions workflow..."
    ensure_dir ".github/workflows"
    
    # Get project name from pubspec
    local app_name
    app_name=$(grep "^name:" pubspec.yaml 2>/dev/null | sed 's/name:[[:space:]]*//' | tr -d '"' | tr -d "'")
    if [[ -z "$app_name" ]]; then
        app_name="app"
    fi
    
    # Check for existing workflow file and remove it (auto-overwrite)
    local workflow_file=".github/workflows/krinry-build.yml"
    if [[ -f "$workflow_file" ]]; then
        print_warning "Existing workflow found - updating..."
        rm -f "$workflow_file"
    fi
    
    # Also remove old workflow names
    rm -f ".github/workflows/krinry-flutter-build.yml" 2>/dev/null
    
    # Copy workflow from krinry template directory
    local template_file="${KRINRY_HOME}/workflows/krinry-flutter-build.yml"
    
    if [[ -f "$template_file" ]]; then
        # Copy from template
        cp "$template_file" "$workflow_file"
        print_success "Copied workflow from template"
    else
        # Fallback: download latest from GitHub
        print_step "Downloading latest workflow..."
        curl -fsSL "https://raw.githubusercontent.com/krinry/krinry-cli/main/workflows/krinry-flutter-build.yml" -o "$workflow_file" 2>/dev/null
        
        if [[ ! -f "$workflow_file" || ! -s "$workflow_file" ]]; then
            print_error "Failed to download workflow template"
            echo "Please check your internet connection and try again"
            exit 1
        fi
        print_success "Downloaded latest workflow"
    fi
    
    # Rename workflow to krinry-build.yml (standard name)
    if [[ -f "$workflow_file" ]]; then
        print_success "Created .github/workflows/krinry-build.yml"
    fi
    
    # Create/update config file
    print_step "Creating configuration file..."
    
    cat > ".krinry.yaml" << CONFIG_EOF
# krinry configuration v${VERSION}
project:
  name: ${app_name}
  type: flutter

build:
  default_type: debug
  output_path: build/app/outputs/flutter-apk

cloud:
  provider: github
  workflow: krinry-build.yml
  poll_interval: 8
CONFIG_EOF
    
    print_success "Created .krinry.yaml"
    
    # Add to .gitignore if not present
    if [[ -f ".gitignore" ]]; then
        if ! grep -q "# krinry" .gitignore 2>/dev/null; then
            echo "" >> .gitignore
            echo "# krinry" >> .gitignore
            echo ".krinry-cache/" >> .gitignore
        fi
    fi
    
    # Summary
    echo ""
    print_header "Initialization Complete"
    echo ""
    echo "Created/Updated files:"
    echo "  • .github/workflows/krinry-build.yml"
    echo "  • .krinry.yaml"
    echo ""
    echo "Next steps:"
    echo "  1. Commit and push:"
    echo "     git add . && git commit -m 'Add krinry cloud build' && git push"
    echo ""
    echo "  2. Build commands (same as flutter build):"
    echo ""
    echo -e "${CYAN}# APK builds${NC}"
    echo "     krinry flutter build apk --debug"
    echo "     krinry flutter build apk --release"
    echo ""
    echo -e "${CYAN}# Split APK (smaller per-device)${NC}"
    echo "     krinry flutter build apk --release --split-per-abi"
    echo ""
    echo -e "${CYAN}# Target specific architecture${NC}"
    echo "     krinry flutter build apk --release --target-platform android-arm64"
    echo ""
    echo -e "${CYAN}# App Bundle (for Play Store)${NC}"
    echo "     krinry flutter build appbundle --release"
    echo ""
    echo -e "${CYAN}# Build and install on device${NC}"
    echo "     krinry flutter build apk --release --install"
    echo ""
    echo -e "${GREEN}💡 Pro tips:${NC}"
    echo "  • Use --split-per-abi for ~60% smaller APKs"
    echo "  • Use --install to auto-install after build"
    echo "  • ARM64 devices: use --target-platform android-arm64"
    echo ""
}
