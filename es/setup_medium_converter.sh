#!/bin/bash

# Setup script for Jekyll to Medium converter

set -e

echo "🔧 Setting up Jekyll to Medium converter..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

# Check if we're in the right directory
check_directory() {
    if [ ! -f "_config.yml" ]; then
        log_error "This doesn't appear to be a Jekyll blog directory"
        log_info "Please run this script from your blog's root directory"
        exit 1
    fi
    
    log_success "Jekyll blog directory detected"
}

# Check Python 3
check_python() {
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is required but not installed"
        echo ""
        echo "Please install Python 3:"
        echo "  macOS: brew install python3"
        echo "  Ubuntu/Debian: sudo apt install python3 python3-pip python3-venv"
        echo "  CentOS/RHEL: sudo yum install python3 python3-pip"
        exit 1
    fi
    
    log_success "Python 3 found: $(python3 --version)"
}

# Create scripts directory and files
setup_files() {
    log_info "Creating scripts directory..."
    mkdir -p scripts
    
    # Make scripts executable
    if [ -f "scripts/convert_for_medium.sh" ]; then
        chmod +x scripts/convert_for_medium.sh
        log_success "Made convert_for_medium.sh executable"
    fi
    
    if [ -f "scripts/convert_for_medium.py" ]; then
        log_success "Python converter script found"
    fi
    
    if [ -f "scripts/requirements.txt" ]; then
        log_success "Requirements file found"
    fi
}

# Test the setup
test_setup() {
    log_info "Testing the setup..."
    
    # Find a recent post to test with
    local test_post
    test_post=$(find _i18n/en/_posts -name "*.md" -type f | head -1)
    
    if [ -n "$test_post" ]; then
        log_info "Running test conversion with: $(basename "$test_post")"
        ./scripts/convert_for_medium.sh convert "$test_post" --no-browser
        
        if [ $? -eq 0 ]; then
            log_success "Test conversion successful!"
        else
            log_warning "Test conversion had issues, but setup is complete"
        fi
    else
        log_warning "No test post found, but setup appears complete"
    fi
}

# Main setup
main() {
    echo "Jekyll to Medium Converter Setup"
    echo "================================"
    echo ""
    
    # Step 1: Check directory
    check_directory
    
    # Step 2: Check Python
    check_python
    
    # Step 3: Setup files
    setup_files
    
    # Step 4: Initialize converter
    log_info "Initializing converter..."
    ./scripts/convert_for_medium.sh setup
    
    # Step 5: Test setup
    test_setup
    
    # Success message
    echo ""
    log_success "Setup complete!"
    echo ""
    echo "🎉 You can now convert Jekyll posts for Medium!"
    echo ""
    echo "Usage examples:"
    echo "  ./scripts/convert_for_medium.sh latest"
    echo "  ./scripts/convert_for_medium.sh convert _i18n/en/_posts/my-post.md"
    echo "  ./scripts/convert_for_medium.sh recent 7"
    echo ""
    echo "Enhanced publishing (Jekyll + Medium):"
    echo "  ./publish_to_blog_and_medium.sh"
    echo ""
    echo "📁 Converted files will be saved in '_medium_output' directory"
    echo "🌐 HTML preview files will open in your browser for easy copy/paste"
}

# Run main function
main 