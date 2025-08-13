#!/bin/bash

# Mermaid Diagram to Image Converter
# Converts Mermaid diagram definitions to PNG images for Jekyll blog posts
# Usage: ./mermaid-to-image.sh [input.mmd] [output.png]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Mermaid CLI
install_mermaid() {
    print_message "$YELLOW" "📦 Installing Mermaid CLI..."
    
    if command_exists npm; then
        npm install -g @mermaid-js/mermaid-cli
        print_message "$GREEN" "✅ Mermaid CLI installed successfully!"
    else
        print_message "$RED" "❌ Error: npm is not installed. Please install Node.js first."
        echo "Visit: https://nodejs.org/"
        exit 1
    fi
}

# Check if Mermaid CLI is installed
if ! command_exists mmdc; then
    print_message "$YELLOW" "⚠️  Mermaid CLI (mmdc) is not installed."
    read -p "Would you like to install it now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_mermaid
    else
        print_message "$RED" "❌ Mermaid CLI is required. Exiting."
        exit 1
    fi
fi

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [input.mmd] [output.png]

OPTIONS:
    -h, --help          Show this help message
    -t, --theme THEME   Set theme (default, dark, forest, neutral)
    -b, --bgcolor COLOR Set background color (e.g., white, transparent)
    -w, --width WIDTH   Set width in pixels (default: 800)
    -s, --scale FACTOR  Set scale factor (default: 2)
    -c, --config FILE   Use custom config file
    -i, --interactive   Interactive mode to create diagram

EXAMPLES:
    # Convert a file
    $0 diagram.mmd diagram.png
    
    # Interactive mode
    $0 -i
    
    # With options
    $0 -t dark -b transparent -w 1200 diagram.mmd diagram.png

EOF
}

# Default values
THEME="default"
BGCOLOR="white"
WIDTH="800"
SCALE="2"
CONFIG=""
INTERACTIVE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -t|--theme)
            THEME="$2"
            shift 2
            ;;
        -b|--bgcolor)
            BGCOLOR="$2"
            shift 2
            ;;
        -w|--width)
            WIDTH="$2"
            shift 2
            ;;
        -s|--scale)
            SCALE="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG="$2"
            shift 2
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Interactive mode
if [ "$INTERACTIVE" = true ]; then
    print_message "$GREEN" "🎨 Interactive Mermaid Diagram Creator"
    echo ""
    
    # Get output filename
    read -p "Enter output image filename (e.g., workflow.png): " OUTPUT_FILE
    if [[ ! "$OUTPUT_FILE" =~ \.png$ ]]; then
        OUTPUT_FILE="${OUTPUT_FILE}.png"
    fi
    
    # Select diagram type
    echo ""
    echo "Select diagram type:"
    echo "1) Flowchart (graph)"
    echo "2) Sequence diagram"
    echo "3) Gantt chart"
    echo "4) Pie chart"
    echo "5) Custom (write your own)"
    read -p "Choice (1-5): " DIAGRAM_TYPE
    
    # Create temporary file for diagram
    TEMP_FILE=$(mktemp /tmp/mermaid-XXXXXX.mmd)
    
    case $DIAGRAM_TYPE in
        1)
            cat > "$TEMP_FILE" << 'EOF'
graph LR
    A[Start] --> B{Decision}
    B -->|Yes| C[Do this]
    B -->|No| D[Do that]
    C --> E[End]
    D --> E
EOF
            ;;
        2)
            cat > "$TEMP_FILE" << 'EOF'
sequenceDiagram
    participant User
    participant System
    participant Database
    
    User->>System: Request data
    System->>Database: Query
    Database-->>System: Results
    System-->>User: Response
EOF
            ;;
        3)
            cat > "$TEMP_FILE" << 'EOF'
gantt
    title Project Timeline
    dateFormat  YYYY-MM-DD
    section Planning
    Research           :done,    des1, 2024-01-01, 2024-01-07
    Design             :active,  des2, 2024-01-08, 10d
    section Development
    Backend            :         des3, after des2, 20d
    Frontend           :         des4, after des2, 25d
EOF
            ;;
        4)
            cat > "$TEMP_FILE" << 'EOF'
pie title Technology Stack
    "JavaScript" : 45
    "Python" : 30
    "Go" : 15
    "Other" : 10
EOF
            ;;
        5)
            print_message "$YELLOW" "Enter your Mermaid diagram (press Ctrl+D when done):"
            cat > "$TEMP_FILE"
            ;;
        *)
            print_message "$RED" "Invalid choice"
            rm "$TEMP_FILE"
            exit 1
            ;;
    esac
    
    # Show the diagram
    echo ""
    print_message "$GREEN" "📝 Diagram content:"
    cat "$TEMP_FILE"
    echo ""
    
    # Ask for confirmation
    read -p "Generate image with this diagram? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        rm "$TEMP_FILE"
        exit 0
    fi
    
    INPUT_FILE="$TEMP_FILE"
else
    # Non-interactive mode
    INPUT_FILE="$1"
    OUTPUT_FILE="$2"
    
    if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
        print_message "$RED" "❌ Error: Input and output files are required"
        show_usage
        exit 1
    fi
    
    if [ ! -f "$INPUT_FILE" ]; then
        print_message "$RED" "❌ Error: Input file '$INPUT_FILE' not found"
        exit 1
    fi
fi

# Build mmdc command
MMDC_CMD="mmdc -i \"$INPUT_FILE\" -o \"$OUTPUT_FILE\""
MMDC_CMD="$MMDC_CMD -t $THEME -b $BGCOLOR -w $WIDTH -s $SCALE"

if [ -n "$CONFIG" ]; then
    MMDC_CMD="$MMDC_CMD -c \"$CONFIG\""
fi

# Convert diagram to image
print_message "$YELLOW" "🔄 Converting Mermaid diagram to image..."
eval $MMDC_CMD

if [ $? -eq 0 ]; then
    print_message "$GREEN" "✅ Success! Image saved to: $OUTPUT_FILE"
    
    # Get image dimensions
    if command_exists identify; then
        DIMENSIONS=$(identify -format "%wx%h" "$OUTPUT_FILE" 2>/dev/null)
        if [ -n "$DIMENSIONS" ]; then
            print_message "$GREEN" "📐 Image dimensions: $DIMENSIONS"
        fi
    fi
    
    # Show file size
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    print_message "$GREEN" "📦 File size: $FILE_SIZE"
    
    # Cleanup temp file if in interactive mode
    if [ "$INTERACTIVE" = true ]; then
        rm "$TEMP_FILE"
    fi
    
    # Offer to copy Jekyll/Markdown code
    echo ""
    read -p "Would you like to copy the Jekyll/Markdown code to clipboard? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        MARKDOWN_CODE="![Diagram]($(basename "$OUTPUT_FILE")){:style=\"display:block; margin-left:auto; margin-right:auto; width:100%; max-width:1200px;\"}"
        
        if command_exists pbcopy; then
            echo "$MARKDOWN_CODE" | pbcopy
            print_message "$GREEN" "📋 Markdown code copied to clipboard!"
        elif command_exists xclip; then
            echo "$MARKDOWN_CODE" | xclip -selection clipboard
            print_message "$GREEN" "📋 Markdown code copied to clipboard!"
        else
            print_message "$YELLOW" "📝 Copy this for your Jekyll post:"
            echo "$MARKDOWN_CODE"
        fi
    fi
else
    print_message "$RED" "❌ Error: Failed to convert diagram"
    if [ "$INTERACTIVE" = true ] && [ -f "$TEMP_FILE" ]; then
        rm "$TEMP_FILE"
    fi
    exit 1
fi