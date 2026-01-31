#!/bin/bash
# krinry-flutter - Run Command (Web Server)

cmd_run() {
    local run_target="${1:-web}"
    shift 2>/dev/null || true
    
    case "$run_target" in
        web)
            cmd_run_web "$@"
            ;;
        *)
            print_error "Unknown run target: $run_target"
            echo "Usage: krinry-flutter run web"
            exit 1
            ;;
    esac
}

cmd_run_web() {
    local port="${1:-8080}"
    
    print_header "Run Flutter Web Server"
    
    # Check if in Flutter project
    if ! is_flutter_project; then
        die "Not a Flutter project. Please run this in a Flutter project directory."
    fi
    
    # Check if Flutter is installed
    if ! is_flutter_installed; then
        die "Flutter not installed. Run 'krinry-flutter install flutter' first."
    fi
    
    # Get Flutter binary path
    local flutter_bin=""
    if [[ -f "${FLUTTER_HOME}/bin/flutter" ]]; then
        flutter_bin="${FLUTTER_HOME}/bin/flutter"
    elif is_command_available flutter; then
        flutter_bin="flutter"
    else
        die "Flutter binary not found"
    fi
    
    # Enable web support if not already
    print_step "Ensuring web support is enabled..."
    $flutter_bin config --enable-web 2>/dev/null || true
    
    # Get dependencies
    print_step "Getting dependencies..."
    $flutter_bin pub get
    
    print_success "Dependencies ready"
    
    # Start web server
    print_header "Starting Web Server"
    echo ""
    echo "Port: ${port}"
    echo ""
    
    # Get local IP for Termux
    local local_ip=""
    if is_termux; then
        local_ip=$(ip route get 1 2>/dev/null | awk '{print $7}' | head -1)
        if [[ -z "$local_ip" ]]; then
            local_ip=$(ifconfig 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' | sed 's/addr://')
        fi
    fi
    
    local url="http://localhost:${port}"
    if [[ -n "$local_ip" ]]; then
        url="http://${local_ip}:${port}"
    fi
    
    echo -e "${BOLD}Access URL:${NC}"
    echo -e "  ${CYAN}${url}${NC}"
    echo ""
    
    # Try to open in browser automatically
    print_step "Opening in browser..."
    if is_termux; then
        # Termux - use termux-open-url if available
        if is_command_available termux-open-url; then
            (sleep 5 && termux-open-url "$url") &
            print_success "Browser will open automatically"
        else
            print_warning "Install termux-api for auto-open: pkg install termux-api"
            echo "Open manually: ${url}"
        fi
    elif is_command_available xdg-open; then
        (sleep 5 && xdg-open "$url") &
    elif is_command_available open; then
        (sleep 5 && open "$url") &
    fi
    
    echo ""
    print_info "Press Ctrl+C to stop the server"
    echo ""
    echo "─────────────────────────────────────"
    
    # Run Flutter web server
    $flutter_bin run -d web-server --web-port "$port" --web-hostname 0.0.0.0
}
