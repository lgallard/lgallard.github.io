#!/bin/bash

# Script to update Jekyll posts with Open Graph optimizations
# Usage: ./update_posts_og.sh

# Function to process a single post
process_post() {
    local post_file=$1
    local temp_file="${post_file}.tmp"
    local is_spanish=false
    
    # Check if it's a Spanish post
    if [[ "$post_file" == *"/es/_posts/"* ]]; then
        is_spanish=true
    fi
    
    # Extract the first image from the post content (after front matter)
    local first_image=$(sed '1,/^---$/d' "$post_file" | grep -m 1 '!\[.*\](.*)' | sed -E 's/.*\((.*)\).*/\1/')
    
    # If no image found in content, use default
    if [ -z "$first_image" ]; then
        first_image="/assets/images/luis.jpg"
    fi
    
    # Extract title and create excerpt
    local title=$(grep -m 1 '^title:' "$post_file" | sed 's/^title: *//' | sed "s/'//g")
    
    # Create excerpt based on language
    if [ "$is_spanish" = true ]; then
        local excerpt="Lee sobre ${title} en lgallardo.com - Ingeniero DevOps y Desarrollador Backend especializado en Kubernetes, AWS, Python y Terraform."
    else
        local excerpt="Read about ${title} on lgallardo.com - DevOps Engineer and Backend Solutions Developer specializing in Kubernetes, AWS, Python, and Terraform."
    fi
    
    # Create new front matter
    cat > "$temp_file" << EOF
---
layout: single
title: ${title}
excerpt: "${excerpt}"
header:
  image: "${first_image}"
  teaser: "${first_image}"
$(grep -A 20 '^---' "$post_file" | grep -v '^---' | grep -v '^layout:' | grep -v '^excerpt:' | grep -v '^header:')
---

EOF
    
    # Append the rest of the content
    sed '1,/^---/d' "$post_file" >> "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$post_file"
}

# Process English posts
for post in _i18n/en/_posts/*.md; do
    if [ -f "$post" ]; then
        echo "Processing $post..."
        process_post "$post"
    fi
done

# Process Spanish posts
for post in _i18n/es/_posts/*.md; do
    if [ -f "$post" ]; then
        echo "Processing $post..."
        process_post "$post"
    fi
done

echo "Done! All posts have been updated with Open Graph optimizations." 