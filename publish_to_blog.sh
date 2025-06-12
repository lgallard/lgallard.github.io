#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting blog publishing process..."

# Configuration
export JEKYLL_VERSION=3.8.6
DEPLOY_REPO="lgallard.github.io"
DEPLOY_BRANCH="master"
TEMP_DEPLOY_DIR="/tmp/$(basename $PWD)_deploy_$$"

# Safety check: ensure we're not running from inside the deployment directory
CURRENT_DIR=$(basename "$PWD")
if [ "$CURRENT_DIR" = "$DEPLOY_REPO" ]; then
    echo "❌ Error: Do not run this script from inside the $DEPLOY_REPO directory!"
    echo "Please run it from the main blog repository directory."
    exit 1
fi

# Step 1: Build the Jekyll site
echo "📦 Building Jekyll site..."
docker run --rm --volume="$PWD:/srv/jekyll" -it jekyll/jekyll:$JEKYLL_VERSION jekyll build -t

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
    echo "🗑️ Removing existing deployment directory..."
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
    cd "$OLDPWD"
    rm -rf "$TEMP_DEPLOY_DIR"
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

# Step 7: Cleanup
echo "🧹 Cleaning up temporary files..."
cd "$OLDPWD"
rm -rf "$TEMP_DEPLOY_DIR"

echo "✅ Blog published successfully!"
