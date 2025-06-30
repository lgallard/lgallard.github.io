#!/bin/bash

# Enhanced Jekyll Publishing Script with Medium Conversion
# Builds Jekyll site, deploys to GitHub Pages, and prepares content for Medium

set -e

echo "🚀 Starting enhanced blog publishing process..."

# Configuration
export JEKYLL_VERSION=3.8.6
DEPLOY_REPO="lgallard.github.io"
DEPLOY_BRANCH="master"
TEMP_DEPLOY_DIR="/tmp/$(basename $PWD)_deploy_$$"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Medium conversion configuration
CONVERT_TO_MEDIUM=true
MEDIUM_RECENT_DAYS=7

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Safety check: ensure we're not running from inside the deployment directory
safety_check() {
    CURRENT_DIR=$(basename "$PWD")
    if [ "$CURRENT_DIR" = "$DEPLOY_REPO" ]; then
        log_error "Do not run this script from inside the $DEPLOY_REPO directory!"
        echo "Please run it from the main blog repository directory."
        exit 1
    fi
}

# Build Jekyll site
build_jekyll() {
    log_step "Building Jekyll site..."
    docker run --rm --volume="$PWD:/srv/jekyll" -it jekyll/jekyll:$JEKYLL_VERSION jekyll build -t

    # Check if _site directory exists
    if [ ! -d "_site" ]; then
        log_error "_site directory not found. Build may have failed."
        exit 1
    fi

    log_success "Jekyll site built successfully"
}

# Deploy to GitHub Pages
deploy_to_github() {
    log_step "Deploying to GitHub Pages..."

    # Ensure _site doesn't contain deployment directory (safety check)
    if [ -d "_site/$DEPLOY_REPO" ]; then
        log_info "Found deployment directory in _site, removing..."
        rm -rf "_site/$DEPLOY_REPO"
    fi

    # Prepare clean deployment directory
    log_info "Preparing clean deployment environment..."
    rm -rf "$TEMP_DEPLOY_DIR"
    mkdir -p "$TEMP_DEPLOY_DIR"

    # Clone repository to temporary location
    log_info "Cloning deployment repository..."
    git clone https://github.com/lgallard/lgallard.github.io.git "$TEMP_DEPLOY_DIR"

    # Clear existing content and copy new content
    log_info "Updating deployment content..."
    cd "$TEMP_DEPLOY_DIR"

    # Remove all content except .git directory
    find . -mindepth 1 -name '.git' -prune -o -type f -exec rm {} + 2>/dev/null || true
    find . -mindepth 1 -name '.git' -prune -o -type d -exec rm -rf {} + 2>/dev/null || true

    # Copy built site content
    cd "$OLDPWD"
    cp -r _site/* "$TEMP_DEPLOY_DIR"/

    # Deploy from temporary directory
    log_info "Committing and pushing changes..."
    cd "$TEMP_DEPLOY_DIR"

    # Check if there are any changes
    if [ -z "$(git status --porcelain)" ]; then
        log_info "No changes to deploy to GitHub Pages"
        cd "$OLDPWD"
        rm -rf "$TEMP_DEPLOY_DIR"
        return 0
    fi

    # Commit and push changes
    git add --all
    git commit -m "Deploy blog: $(date '+%Y-%m-%d %H:%M:%S')"

    if [ -n "$GITTOKEN" ]; then
        git push https://$GITTOKEN@github.com/lgallard/lgallard.github.io.git $DEPLOY_BRANCH
    else
        git push origin $DEPLOY_BRANCH
    fi

    cd "$OLDPWD"
    rm -rf "$TEMP_DEPLOY_DIR"
    log_success "Blog deployed to GitHub Pages successfully!"
}

# Convert recent posts for Medium
convert_for_medium() {
    if [ "$CONVERT_TO_MEDIUM" != "true" ]; then
        log_info "Medium conversion disabled, skipping..."
        return 0
    fi

    log_step "Converting recent posts for Medium..."

    # Check if converter script exists
    if [ ! -f "$SCRIPT_DIR/scripts/convert_for_medium.sh" ]; then
        log_info "Medium converter not found, skipping Medium conversion"
        log_info "Run 'scripts/convert_for_medium.sh setup' to enable Medium conversion"
        return 0
    fi

    # Check if there are recent changes in posts
    if git log --since="$MEDIUM_RECENT_DAYS days ago" --pretty=format: --name-only | grep -q "_posts/"; then
        log_info "Found recent post changes, converting for Medium..."
        
        cd "$SCRIPT_DIR"
        ./scripts/convert_for_medium.sh recent "$MEDIUM_RECENT_DAYS"
        
        if [ -d "_medium_output" ] && [ "$(ls -A _medium_output 2>/dev/null)" ]; then
            log_success "Medium conversion completed!"
            log_info "Check the '_medium_output' directory for converted files"
            log_info "Open the HTML preview files to copy content for Medium"
        else
            log_info "No content converted for Medium"
        fi
    else
        log_info "No recent post changes detected, skipping Medium conversion"
    fi
}

# Show help
show_help() {
    echo "Enhanced Jekyll + Medium Publishing Script"
    echo ""
    echo "Builds Jekyll site, deploys to GitHub Pages, and prepares content for Medium"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --skip-medium       Skip Medium conversion"
    echo "  --medium-days N     Number of days to look back for Medium conversion (default: 7)"
    echo "  --help              Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                           # Normal publishing with Medium conversion"
    echo "  $0 --skip-medium             # Publish only to GitHub Pages"
    echo "  $0 --medium-days 14          # Convert posts from last 14 days for Medium"
    echo ""
    echo "What this script does:"
    echo "  1. 🏗️  Builds Jekyll site using Docker"
    echo "  2. 🚀 Deploys to GitHub Pages"
    echo "  3. 📝 Converts recent posts for Medium (optional)"
    echo "  4. 🌐 Opens preview files for easy copy/paste to Medium"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-medium)
            CONVERT_TO_MEDIUM=false
            shift
            ;;
        --medium-days)
            MEDIUM_RECENT_DAYS="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
main() {
    echo "🌟 Enhanced Jekyll + Medium Publishing"
    echo "======================================"
    
    # Safety checks
    safety_check
    
    # Step 1: Build Jekyll site
    build_jekyll
    
    # Step 2: Deploy to GitHub Pages
    deploy_to_github
    
    # Step 3: Convert for Medium
    convert_for_medium
    
    # Summary
    echo ""
    log_success "Publishing process completed!"
    echo ""
    echo "📊 Summary:"
    echo "  ✅ Jekyll site built and deployed to GitHub Pages"
    echo "  🌍 Blog available at: https://lgallardo.com"
    
    if [ "$CONVERT_TO_MEDIUM" = "true" ]; then
        echo "  📝 Recent posts converted for Medium (if any)"
        echo "  📁 Check '_medium_output' directory for Medium-ready content"
        echo ""
        echo "🔗 Next steps for Medium:"
        echo "  1. Open HTML preview files from '_medium_output'"
        echo "  2. Copy content using the 'Copy Content' button"
        echo "  3. Go to https://medium.com/new-story"
        echo "  4. Paste and publish!"
    fi
}

# Run main function
main 