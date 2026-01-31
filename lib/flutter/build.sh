#!/bin/bash
# krinry-flutter - Build APK Command

cmd_build_apk() {
    local build_type="release"
    
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
            *)
                print_error "Unknown option: $1"
                echo "Usage: krinry-flutter build apk [--release|--debug]"
                exit 1
                ;;
        esac
    done
    
    print_header "Build APK (${build_type})"
    
    # Validate environment
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
    if ! git push 2>/dev/null; then
        print_warning "Failed to push. You may need to push manually."
    else
        print_success "Pushed to GitHub"
    fi
    
    # Trigger workflow
    print_step "Triggering cloud build..."
    
    local repo_owner repo_name
    repo_owner=$(get_repo_owner)
    repo_name=$(get_repo_name)
    
    if [[ -z "$repo_owner" || -z "$repo_name" ]]; then
        die "Could not determine repository owner/name from remote URL"
    fi
    
    # Trigger the workflow
    if ! gh workflow run krinry-build.yml -f build_type="${build_type}" 2>/dev/null; then
        die "Failed to trigger workflow. Make sure you've pushed the workflow file."
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
        die "Could not find the triggered workflow run"
    fi
    
    echo "Run ID: ${run_id}"
    echo "View online: https://github.com/${repo_owner}/${repo_name}/actions/runs/${run_id}"
    echo ""
    
    # Poll for completion
    poll_build_status "$run_id" "$repo_owner" "$repo_name" "$build_type"
}

validate_build_environment() {
    # Check Flutter project
    if ! is_flutter_project; then
        die "Not a Flutter project. Please run this in a Flutter project directory."
    fi
    
    # Check git repo
    if ! is_git_repo; then
        die "Not a git repository. Run 'git init' first."
    fi
    
    # Check GitHub remote
    local remote_url
    remote_url=$(get_remote_url)
    if [[ -z "$remote_url" ]]; then
        die "No GitHub remote. Run 'git remote add origin <url>' first."
    fi
    
    # Check workflow file
    if ! has_workflow_file; then
        die "No workflow file found. Run 'krinry-flutter init' first."
    fi
    
    # Check gh auth
    if ! gh auth status &>/dev/null; then
        die "Not logged into GitHub CLI. Run 'gh auth login' first."
    fi
    
    # Check internet
    if ! check_internet; then
        die "No internet connection"
    fi
    
    print_success "Environment validated"
}

poll_build_status() {
    local run_id="$1"
    local repo_owner="$2"
    local repo_name="$3"
    local build_type="$4"
    
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
            download_artifact "$run_id" "$build_type"
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
    local build_type="$2"
    
    print_header "Downloading APK"
    
    local output_dir="build/app/outputs/flutter-apk"
    ensure_dir "$output_dir"
    
    print_step "Downloading artifact..."
    
    # Download the artifact
    if gh run download "$run_id" -n "apk-${build_type}" -D "$output_dir" 2>/dev/null; then
        # Find the downloaded APK
        local apk_file
        apk_file=$(find "$output_dir" -name "*.apk" -type f | head -1)
        
        if [[ -n "$apk_file" ]]; then
            print_success "APK downloaded!"
            echo ""
            echo "📦 APK Location:"
            echo "   ${apk_file}"
            echo ""
            
            # Get file size
            local size
            if is_command_available stat; then
                size=$(stat -f%z "$apk_file" 2>/dev/null || stat -c%s "$apk_file" 2>/dev/null)
                if [[ -n "$size" ]]; then
                    local size_mb
                    size_mb=$(echo "scale=2; $size / 1048576" | bc 2>/dev/null || echo "")
                    if [[ -n "$size_mb" ]]; then
                        echo "   Size: ${size_mb} MB"
                    fi
                fi
            fi
            
            echo ""
            print_success "Build complete! 🎉"
        else
            print_warning "APK downloaded but file not found in expected location"
        fi
    else
        print_error "Failed to download artifact"
        echo "You can download it manually from GitHub Actions"
        exit 1
    fi
}
