#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting blog publishing process..."

# Configuration
DEPLOY_REPO="lgallard.github.io"
DEPLOY_BRANCH="master"
TEMP_DEPLOY_DIR="/tmp/$(basename $PWD)_deploy_$$"

# Cleanup function for trap
cleanup() {
    local exit_code=$?
    if [ -d "$TEMP_DEPLOY_DIR" ]; then
        echo "🧹 Cleaning up temporary files..."
        rm -rf "$TEMP_DEPLOY_DIR"
    fi
    exit $exit_code
}

# Set trap to cleanup on EXIT, INT, TERM
trap cleanup EXIT INT TERM

# Safety check: ensure we're not running from inside the deployment directory
CURRENT_DIR=$(basename "$PWD")
if [ "$CURRENT_DIR" = "$DEPLOY_REPO" ]; then
    echo "❌ Error: Do not run this script from inside the $DEPLOY_REPO directory!"
    echo "Please run it from the main blog repository directory."
    exit 1
fi

# Step 1: Build the Jekyll site using Jekyll 4.x Docker image
echo "📦 Building Jekyll site with Jekyll 4.x..."
docker run --rm --entrypoint bash -v "$PWD:/site" -w /site bretfisher/jekyll -c "bundle install --retry 5 --jobs 20 && bundle exec jekyll build --trace"

# Step 2: Check if _site directory exists
if [ ! -d "_site" ]; then
    echo "❌ Error: _site directory not found. Build may have failed."
    exit 1
fi

# Step 3: Ensure _site doesn't contain deployment directory (safety check)
if [ -d "_site/$DEPLOY_REPO" ]; then
    echo "🚨 WARNING: Found deployment directory in _site, removing..."
    rm -rf "_site/$DEPLOY_REPO"
fi

# Step 4: Prepare clean deployment directory
echo "🧹 Preparing clean deployment environment..."

# Remove any existing deployment directory that might be corrupted
if [ -d "$DEPLOY_REPO" ]; then
    echo "🗑️ Removing existing deployment directory from working dir..."
    rm -rf "$DEPLOY_REPO"
fi

# Create temporary deployment directory in /tmp to avoid any conflicts
echo "📂 Creating temporary deployment workspace..."
rm -rf "$TEMP_DEPLOY_DIR"
mkdir -p "$TEMP_DEPLOY_DIR"

# Clone repository to temporary location
echo "📂 Cloning deployment repository to temporary location..."
git clone https://github.com/lgallard/lgallard.github.io.git "$TEMP_DEPLOY_DIR"

# Step 5: Clear existing content and copy new content
echo "📋 Updating deployment content..."
cd "$TEMP_DEPLOY_DIR"

# Remove all content except .git directory
find . -mindepth 1 -name '.git' -prune -o -type f -exec rm {} + 2>/dev/null || true
find . -mindepth 1 -name '.git' -prune -o -type d -exec rm -rf {} + 2>/dev/null || true

# Copy built site content (go back to original directory first)
cd "$OLDPWD"
cp -r _site/* "$TEMP_DEPLOY_DIR"/

# Step 6: Deploy from temporary directory
echo "🌐 Deploying to GitHub Pages..."
cd "$TEMP_DEPLOY_DIR"

# Check if there are any changes
if [ -z "$(git status --porcelain)" ]; then
    echo "✅ No changes to deploy"
    exit 0
fi

# Commit and push changes
git add --all
git commit -m "Deploy blog: $(date '+%Y-%m-%d %H:%M:%S')"

if [ -n "$GITTOKEN" ]; then
    git push https://$GITTOKEN@github.com/lgallard/lgallard.github.io.git $DEPLOY_BRANCH
else
    git push origin $DEPLOY_BRANCH
fi

echo "✅ Blog published successfully!"
