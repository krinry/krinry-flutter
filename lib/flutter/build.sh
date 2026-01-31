#!/bin/bash
# krinry flutter - Build Command

cmd_build_apk() {
    cmd_build "apk" "$@"
}

cmd_build() {
    local output_type="${1:-apk}"
    shift
    
    local build_type="debug"
    local target_platform="all"
    local install_after=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --release)
                build_type="release"
                shift
                ;;
            --debug)
                build_type="debug"
                shift
                ;;
            --profile)
                build_type="profile"
                shift
                ;;
            --split)
                output_type="apk-split"
                shift
                ;;
            --arm64)
                target_platform="android-arm64"
                shift
                ;;
            --arm)
                target_platform="android-arm"
                shift
                ;;
            --x64)
                target_platform="android-x64"
                shift
                ;;
            --install)
                install_after=true
                shift
                ;;
            --help|-h)
                show_build_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_build_help
                exit 1
                ;;
        esac
    done
    
    # Determine artifact name for workflow
    local artifact_name="build-${build_type}-${output_type}"
    
    print_header "Build ${output_type^^} (${build_type})"
    
    if [[ "$target_platform" != "all" && "$output_type" == "apk" ]]; then
        echo "Target: ${target_platform}"
    fi
    echo ""
    
    # Validate environment (with detailed errors)
    validate_build_environment
    
    # Check for uncommitted changes
    if has_uncommitted_changes; then
        print_warning "You have uncommitted changes"
        echo ""
        git status --short
        echo ""
        if ask_yes_no "Commit changes before building?" "y"; then
            read -r -p "Commit message: " commit_msg
            git add .
            git commit -m "${commit_msg:-'Build commit'}"
            print_success "Changes committed"
        else
            print_warning "Building with uncommitted changes (they won't be in the build)"
        fi
    fi
    
    # Push latest changes
    print_step "Pushing to GitHub..."
    local push_output
    push_output=$(git push 2>&1)
    if [[ $? -ne 0 ]]; then
        print_warning "Failed to push changes"
        echo "$push_output"
        echo ""
        echo "Please resolve this and try again."
        exit 1
    else
        print_success "Pushed to GitHub"
    fi
    
    # Trigger workflow
    print_step "Triggering cloud build..."
    
    local repo_owner repo_name
    repo_owner=$(get_repo_owner)
    repo_name=$(get_repo_name)
    
    if [[ -z "$repo_owner" || -z "$repo_name" ]]; then
        print_error "Could not determine repository owner/name from remote URL"
        echo ""
        echo "Your remote URL: $(get_remote_url)"
        echo ""
        echo "Make sure it's a valid GitHub URL like:"
        echo "  https://github.com/username/repo.git"
        echo "  git@github.com:username/repo.git"
        exit 1
    fi
    
    # Trigger the workflow with all parameters
    local trigger_output
    trigger_output=$(gh workflow run krinry-build.yml \
        -f build_type="${build_type}" \
        -f output_type="${output_type}" \
        -f target_platform="${target_platform}" \
        2>&1)
    
    if [[ $? -ne 0 ]]; then
        print_error "Failed to trigger workflow"
        echo ""
        echo "$trigger_output"
        echo ""
        echo "Possible solutions:"
        echo "  1. Make sure workflow file exists: .github/workflows/krinry-build.yml"
        echo "  2. Push the workflow: git push"
        echo "  3. Check GitHub authentication: gh auth status"
        echo "  4. Re-run init: krinry flutter init"
        exit 1
    fi
    
    print_success "Build triggered!"
    echo ""
    
    # Wait a moment for the run to be created
    sleep 3
    
    # Get the run ID
    print_step "Getting build status..."
    
    local run_id
    run_id=$(gh run list --workflow=krinry-build.yml --limit=1 --json databaseId -q '.[0].databaseId' 2>/dev/null)
    
    if [[ -z "$run_id" ]]; then
        print_error "Could not find the triggered workflow run"
        echo ""
        echo "View your workflows at:"
        echo "  https://github.com/${repo_owner}/${repo_name}/actions"
        exit 1
    fi
    
    echo "Run ID: ${run_id}"
    echo "View online: https://github.com/${repo_owner}/${repo_name}/actions/runs/${run_id}"
    echo ""
    
    # Poll for completion
    poll_build_status "$run_id" "$repo_owner" "$repo_name" "$artifact_name" "$output_type" "$install_after"
}

show_build_help() {
    echo ""
    echo "Usage: krinry flutter build <type> [OPTIONS]"
    echo ""
    echo "Build Flutter app using GitHub Actions cloud build."
    echo ""
    echo "BUILD TYPES:"
    echo "  apk         Build APK (Android Package)"
    echo "  appbundle   Build AAB (Android App Bundle)"
    echo ""
    echo "BUILD MODE:"
    echo "  --debug     Debug build (default, faster)"
    echo "  --profile   Profile build (for performance testing)"
    echo "  --release   Release build (optimized, slower)"
    echo ""
    echo "APK OPTIONS:"
    echo "  --split     Split APK by ABI (smaller individual files)"
    echo "  --arm64     Build only for ARM64 devices"
    echo "  --arm       Build only for ARM devices"
    echo "  --x64       Build only for x64 devices"
    echo ""
    echo "OTHER OPTIONS:"
    echo "  --install   Install APK on device after download (Termux only)"
    echo "  --help      Show this help"
    echo ""
    echo "EXAMPLES:"
    echo "  krinry flutter build apk                    # Debug APK"
    echo "  krinry flutter build apk --release          # Release APK"
    echo "  krinry flutter build apk --release --split  # Split release APKs"
    echo "  krinry flutter build apk --release --arm64  # ARM64 only"
    echo "  krinry flutter build appbundle --release    # Release App Bundle"
    echo "  krinry flutter build apk --install          # Build & install"
    echo ""
}

validate_build_environment() {
    echo ""
    print_step "Validating environment..."
    echo ""
    
    local has_error=false
    
    # Check Flutter project
    if ! is_flutter_project; then
        print_error "Not a Flutter project"
        echo "  → Make sure you're in a Flutter project directory (with pubspec.yaml)"
        has_error=true
    else
        print_success "Flutter project detected"
    fi
    
    # Check git repo
    if ! is_git_repo; then
        print_error "Not a git repository"
        echo "  → Run: git init"
        has_error=true
    else
        print_success "Git repository detected"
    fi
    
    # Check GitHub remote
    local remote_url
    remote_url=$(get_remote_url)
    if [[ -z "$remote_url" ]]; then
        print_error "No GitHub remote configured"
        echo "  → Run: git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
        has_error=true
    else
        print_success "Remote: ${remote_url}"
    fi
    
    # Check workflow file
    if ! has_workflow_file; then
        print_error "No workflow file found"
        echo "  → Run: krinry flutter init"
        has_error=true
    else
        print_success "Workflow file exists"
    fi
    
    # Check gh installed
    if ! is_command_available gh; then
        print_error "GitHub CLI not installed"
        echo "  → Install: pkg install gh"
        has_error=true
    else
        # Check gh auth
        local auth_status
        auth_status=$(gh auth status 2>&1)
        if [[ $? -ne 0 ]]; then
            print_error "Not logged into GitHub CLI"
            echo "  → Run: gh auth login"
            echo ""
            echo "  Quick setup:"
            echo "    1. Run: gh auth login"
            echo "    2. Choose: GitHub.com"
            echo "    3. Choose: HTTPS"
            echo "    4. Choose: Login with a web browser"
            echo "    5. Copy the code and open the URL"
            has_error=true
        else
            print_success "GitHub authenticated"
        fi
    fi
    
    # Check internet
    if ! check_internet; then
        print_error "No internet connection"
        has_error=true
    else
        print_success "Internet connection OK"
    fi
    
    echo ""
    
    if [[ "$has_error" == "true" ]]; then
        print_error "Please fix the above issues and try again"
        exit 1
    fi
    
    print_success "Environment validated"
}

poll_build_status() {
    local run_id="$1"
    local repo_owner="$2"
    local repo_name="$3"
    local artifact_name="$4"
    local output_type="$5"
    local install_after="$6"
    
    local poll_interval=8
    local status=""
    local conclusion=""
    
    print_header "Build Progress"
    
    while true; do
        # Get run status
        local run_info
        run_info=$(gh run view "$run_id" --json status,conclusion 2>/dev/null)
        
        status=$(echo "$run_info" | grep -o '"status":"[^"]*"' | sed 's/"status":"\([^"]*\)"/\1/')
        conclusion=$(echo "$run_info" | grep -o '"conclusion":"[^"]*"' | sed 's/"conclusion":"\([^"]*\)"/\1/')
        
        # Display status
        case "$status" in
            queued)
                echo -ne "\r${YELLOW}⏳${NC} Status: Queued...                    "
                ;;
            in_progress)
                echo -ne "\r${CYAN}🔄${NC} Status: Building...                   "
                ;;
            completed)
                echo ""
                break
                ;;
            *)
                echo -ne "\r${BLUE}⏳${NC} Status: ${status}...                  "
                ;;
        esac
        
        sleep "$poll_interval"
    done
    
    # Handle completion
    case "$conclusion" in
        success)
            print_success "Build completed successfully!"
            echo ""
            download_artifact "$run_id" "$artifact_name" "$output_type" "$install_after"
            ;;
        failure)
            print_error "Build failed!"
            echo ""
            echo "View logs at:"
            echo "https://github.com/${repo_owner}/${repo_name}/actions/runs/${run_id}"
            echo ""
            print_step "Fetching build logs..."
            gh run view "$run_id" --log-failed 2>/dev/null | tail -50
            exit 1
            ;;
        cancelled)
            print_warning "Build was cancelled"
            exit 1
            ;;
        *)
            print_error "Build ended with: ${conclusion}"
            exit 1
            ;;
    esac
}

download_artifact() {
    local run_id="$1"
    local artifact_name="$2"
    local output_type="$3"
    local install_after="$4"
    
    print_header "Downloading Build Output"
    
    local output_dir
    if [[ "$output_type" == "appbundle" ]]; then
        output_dir="build/app/outputs/bundle"
    else
        output_dir="build/app/outputs/flutter-apk"
    fi
    ensure_dir "$output_dir"
    
    print_step "Downloading artifact: ${artifact_name}..."
    
    # Download the artifact
    local download_output
    download_output=$(gh run download "$run_id" -n "${artifact_name}" -D "$output_dir" 2>&1)
    if [[ $? -eq 0 ]]; then
        # Find the downloaded files
        local files
        if [[ "$output_type" == "appbundle" ]]; then
            files=$(find "$output_dir" -name "*.aab" -type f 2>/dev/null)
        else
            files=$(find "$output_dir" -name "*.apk" -type f 2>/dev/null)
        fi
        
        if [[ -n "$files" ]]; then
            print_success "Downloaded!"
            echo ""
            echo "📦 Output Location(s):"
            
            local first_apk=""
            while IFS= read -r file; do
                echo "   ${file}"
                
                # Get file size
                local size
                if is_command_available stat; then
                    size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
                    if [[ -n "$size" ]]; then
                        local size_mb
                        size_mb=$(awk "BEGIN {printf \"%.2f\", $size / 1048576}" 2>/dev/null)
                        if [[ -n "$size_mb" ]]; then
                            echo "      Size: ${size_mb} MB"
                        fi
                    fi
                fi
                
                # Save first APK for install
                if [[ -z "$first_apk" && "$file" == *.apk ]]; then
                    first_apk="$file"
                fi
            done <<< "$files"
            
            echo ""
            print_success "Build complete! 🎉"
            
            # Install on device if requested
            if [[ "$install_after" == "true" && -n "$first_apk" ]]; then
                install_apk "$first_apk"
            fi
        else
            print_warning "Downloaded but file not found in expected location"
        fi
    else
        print_error "Failed to download artifact"
        echo "$download_output"
        echo ""
        echo "You can download it manually from:"
        echo "  https://github.com/$(get_repo_owner)/$(get_repo_name)/actions"
        exit 1
    fi
}

install_apk() {
    local apk_file="$1"
    
    echo ""
    print_header "Installing APK"
    
    # Check if we're in Termux
    if ! is_termux; then
        print_warning "Install only works in Termux on Android"
        echo ""
        echo "APK path: ${apk_file}"
        return
    fi
    
    # Check if termux-open is available
    if ! is_command_available termux-open; then
        print_warning "termux-api not installed"
        echo "Install it with: pkg install termux-api"
        echo ""
        echo "Then you can manually install:"
        echo "  termux-open ${apk_file}"
        return
    fi
    
    print_step "Opening APK installer..."
    
    # Use termux-open to trigger Android's package installer
    if termux-open "$apk_file" 2>/dev/null; then
        print_success "APK installer opened!"
        echo ""
        echo "Follow the prompts on your screen to install the app."
    else
        print_warning "Could not open installer"
        echo "Try manually: termux-open ${apk_file}"
    fi
}
