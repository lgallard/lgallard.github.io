#!/bin/bash

# Jekyll 4.x preview server using bretfisher/jekyll
# Includes future posts for testing scheduled content

# First install dependencies
echo "📦 Installing dependencies..."
docker run --rm --entrypoint bash -v "$PWD:/site" -w /site bretfisher/jekyll -c "bundle install --retry 5 --jobs 20"

# Start the preview server with future posts enabled
echo "🚀 Starting Jekyll preview server at http://localhost:4000"
docker run --rm -p 4000:4000 --entrypoint bash -v "$PWD:/site" -w /site bretfisher/jekyll -c "bundle exec jekyll serve --host 0.0.0.0 --future"
