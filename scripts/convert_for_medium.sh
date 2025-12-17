#!/bin/bash

# Jekyll to Medium Converter Wrapper Script
# Converts Jekyll posts to Medium-friendly format for easy copy/paste

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
REQUIREMENTS_FILE="$SCRIPT_DIR/requirements.txt"
CONVERTER_SCRIPT="$SCRIPT_DIR/convert_for_medium.py"
BASE_URL="https://lgallardo.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Setup Python virtual environment
setup_venv() {
    if [ ! -d "$VENV_DIR" ]; then
        log_info "Creating Python virtual environment..."
        python3 -m venv "$VENV_DIR"
    fi
    
    source "$VENV_DIR/bin/activate"
    
    log_info "Installing/updating dependencies..."
    pip install --upgrade pip > /dev/null 2>&1
    pip install -r "$REQUIREMENTS_FILE" > /dev/null 2>&1
    
    log_success "Python environment ready"
}

# Check if Python 3 is available
check_python() {
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is required but not installed"
        echo "Please install Python 3 to use this script"
        exit 1
    fi
}

# Convert a single post
convert_post() {
    local post_file="$1"
    local no_browser="$2"
    
    if [ ! -f "$post_file" ]; then
        log_error "Post file not found: $post_file"
        return 1
    fi
    
    setup_venv
    source "$VENV_DIR/bin/activate"
    
    log_info "Converting $post_file to Medium format..."
    
    if [ "$no_browser" = "true" ]; then
        python3 "$CONVERTER_SCRIPT" "$post_file" --base-url "$BASE_URL" --no-browser
    else
        python3 "$CONVERTER_SCRIPT" "$post_file" --base-url "$BASE_URL"
    fi
}

# Convert recent posts
convert_recent() {
    local days="${1:-7}"
    local posts_dir="_i18n/en/_posts"
    
    if [ ! -d "$posts_dir" ]; then
        log_error "Posts directory not found: $posts_dir"
        return 1
    fi
    
    log_info "Looking for posts modified in the last $days days..."
    
    # Find posts modified in the last N days
    local recent_posts
    recent_posts=$(find "$posts_dir" -name "*.md" -mtime "-$days" -type f)
    
    if [ -z "$recent_posts" ]; then
        log_warning "No posts found modified in the last $days days"
        return 0
    fi
    
    log_info "Found recent posts:"
    echo "$recent_posts" | while read -r post; do
        echo "  📄 $(basename "$post")"
    done
    
    echo "$recent_posts" | while read -r post; do
        echo ""
        convert_post "$post" "true"
    done
    
    log_success "All recent posts converted!"
    log_info "Check the _medium_output directory for converted files"
}

# Find latest post
convert_latest() {
    local posts_dir="_i18n/en/_posts"
    
    if [ ! -d "$posts_dir" ]; then
        log_error "Posts directory not found: $posts_dir"
        return 1
    fi
    
    local latest_post
    latest_post=$(find "$posts_dir" -name "*.md" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [ -z "$latest_post" ]; then
        log_error "No posts found in $posts_dir"
        return 1
    fi
    
    log_info "Converting latest post: $(basename "$latest_post")"
    convert_post "$latest_post"
}

# Show help
show_help() {
    echo "Jekyll to Medium Converter"
    echo ""
    echo "Converts Jekyll posts to Medium-friendly format for easy copy/paste"
    echo ""
    echo "Usage: $0 <action> [options]"
    echo ""
    echo "Actions:"
    echo "  convert <file>       - Convert specific Jekyll post file"
    echo "  latest               - Convert the most recent post"
    echo "  recent [days]        - Convert posts modified in last N days (default: 7)"
    echo "  setup                - Setup Python environment and dependencies"
    echo "  clean                - Clean up output files and virtual environment"
    echo "  help                 - Show this help"
    echo ""
    echo "Options:"
    echo "  --no-browser         - Don't open browser preview (for batch processing)"
    echo ""
    echo "Examples:"
    echo "  $0 convert _i18n/en/_posts/2025-01-14-my-post.md"
    echo "  $0 latest"
    echo "  $0 recent 14"
    echo "  $0 convert my-post.md --no-browser"
    echo ""
    echo "Output:"
    echo "  Converted files are saved in '_medium_output/' directory"
    echo "  Each conversion creates:"
    echo "    - A .md file with Medium-ready content"
    echo "    - An .html preview file that opens in your browser"
}

# Clean up
clean_up() {
    log_info "Cleaning up..."
    
    if [ -d "$VENV_DIR" ]; then
        rm -rf "$VENV_DIR"
        log_success "Removed Python virtual environment"
    fi
    
    if [ -d "_medium_output" ]; then
        rm -rf "_medium_output"
        log_success "Removed output directory"
    fi
    
    log_success "Cleanup complete"
}

# Main function
main() {
    local action="${1:-help}"
    
    # Check if we're in the right directory
    if [ ! -f "_config.yml" ]; then
        log_warning "Not in Jekyll blog root directory?"
        log_info "Make sure you're running this from your blog's root directory"
    fi
    
    case "$action" in
        "setup")
            log_info "Setting up Jekyll to Medium converter..."
            check_python
            setup_venv
            log_success "Setup complete! You can now convert posts."
            ;;
        
        "convert")
            local post_file="$2"
            local no_browser="false"
            
            if [ "$3" = "--no-browser" ] || [ "$3" = "-n" ]; then
                no_browser="true"
            fi
            
            if [ -z "$post_file" ]; then
                log_error "Please specify a post file"
                echo "Usage: $0 convert <post_file> [--no-browser]"
                exit 1
            fi
            
            check_python
            convert_post "$post_file" "$no_browser"
            ;;
        
        "latest")
            check_python
            convert_latest
            ;;
        
        "recent")
            local days="${2:-7}"
            check_python
            convert_recent "$days"
            ;;
        
        "clean")
            clean_up
            ;;
        
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@" 