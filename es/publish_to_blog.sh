#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting blog publishing process..."

# Configuration
export JEKYLL_VERSION=3.8.6
DEPLOY_REPO="lgallard.github.io"
DEPLOY_BRANCH="master"

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

# Step 3: Prepare deployment directory
echo "🧹 Preparing deployment directory..."
if [ -d "$DEPLOY_REPO" ]; then
    echo "📂 Deployment directory exists, cleaning up nested directories..."
    # Remove any nested lgallard.github.io directories to fix infinite loop
    find $DEPLOY_REPO -name "lgallard.github.io" -type d | grep -v "^$DEPLOY_REPO$" | xargs rm -rf 2>/dev/null || true
    
    cd $DEPLOY_REPO
    
    # Handle any uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        echo "🧹 Found uncommitted changes, stashing them..."
        git add --all
        git stash
    fi
    
    # Pull latest changes
    git pull origin $DEPLOY_BRANCH
    cd ..
else
    echo "📂 Cloning deployment repository..."
    git clone https://github.com/lgallard/lgallard.github.io.git $DEPLOY_REPO
fi

# Step 4: Copy built site to deployment directory
echo "📋 Copying built site files..."
rsync -av --delete _site/ $DEPLOY_REPO/ --exclude='.git' --exclude='lgallard.github.io'

# Step 5: Deploy to GitHub Pages
echo "🌐 Deploying to GitHub Pages..."
cd $DEPLOY_REPO

# Check if there are any changes
if [ -z "$(git status --porcelain)" ]; then
    echo "✅ No changes to deploy"
    cd ..
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

cd ..

echo "✅ Blog published successfully!"
