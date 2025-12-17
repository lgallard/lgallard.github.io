#!/usr/bin/env python3
"""
Enhanced Mermaid to PNG converter with larger image support
Uses Mermaid.ink service for better quality images
"""

import base64
import json
import os
import sys
import urllib.request
import urllib.parse

def print_color(message, color='green'):
    """Print colored messages"""
    colors = {
        'red': '\033[0;31m',
        'green': '\033[0;32m',
        'yellow': '\033[1;33m',
        'blue': '\033[0;34m',
        'reset': '\033[0m'
    }
    print(f"{colors.get(color, '')}{message}{colors['reset']}")

def generate_mermaid_ink_url(diagram_code, format='png', width=1200, height=800):
    """Generate Mermaid.ink URL for larger, better quality images"""
    # Clean up the diagram code
    diagram_code = diagram_code.strip()
    
    # Encode for URL
    encoded = base64.b64encode(diagram_code.encode('utf-8')).decode('ascii')
    
    # Create URL with size parameters
    url = f"https://mermaid.ink/img/{encoded}?type={format}&width={width}&height={height}"
    return url

def generate_mermaid_live_url(diagram_code):
    """Generate Mermaid Live Editor URL"""
    config = {
        "code": diagram_code,
        "mermaid": {
            "theme": "default",
            "themeVariables": {
                "fontSize": "16px",
                "fontFamily": "Inter, system-ui, sans-serif"
            }
        }
    }
    
    # Encode for URL
    json_str = json.dumps(config)
    encoded = base64.b64encode(json_str.encode()).decode()
    
    return f"https://mermaid.live/edit#base64:{encoded}"

def download_image(url, output_file):
    """Download image from URL with better error handling"""
    try:
        print_color(f"📥 Downloading from: {url[:100]}...", 'yellow')
        
        # Create headers to avoid blocking
        req = urllib.request.Request(
            url,
            headers={
                'User-Agent': 'Mozilla/5.0 (Mermaid Converter)',
                'Accept': 'image/png,image/*,*/*'
            }
        )
        
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                with open(output_file, 'wb') as f:
                    f.write(response.read())
                return True
            else:
                print_color(f"HTTP {response.status}: {response.reason}", 'red')
                return False
                
    except Exception as e:
        print_color(f"Error downloading image: {e}", 'red')
        return False

def get_image_info(filename):
    """Get image dimensions and file size"""
    if not os.path.exists(filename):
        return None
        
    file_size = os.path.getsize(filename)
    size_mb = file_size / (1024 * 1024)
    
    # Try to get dimensions using file command or basic analysis
    try:
        import subprocess
        result = subprocess.run(['file', filename], capture_output=True, text=True)
        if result.returncode == 0 and 'PNG' in result.stdout:
            # Extract dimensions if available
            output = result.stdout
            if 'x' in output:
                return f"PNG image, {size_mb:.2f} MB"
    except:
        pass
    
    return f"{size_mb:.2f} MB"

def main():
    print_color("🎨 Enhanced Mermaid to PNG Converter", 'blue')
    print_color("   (Large, high-quality images with emoji support)", 'blue')
    print()
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python3 mermaid-to-png.py <input.mmd> [output.png] [width] [height]")
        print("  python3 mermaid-to-png.py --url <input.mmd>     # Get editor URL only")
        print()
        print("Examples:")
        print("  python3 mermaid-to-png.py diagram.mmd")
        print("  python3 mermaid-to-png.py diagram.mmd large-diagram.png 1400 900")
        print("  python3 mermaid-to-png.py --url diagram.mmd")
        print()
        sys.exit(1)
    
    if sys.argv[1] == '--url':
        if len(sys.argv) < 3:
            print_color("Error: Please provide input file", 'red')
            sys.exit(1)
        
        input_file = sys.argv[2]
        if not os.path.exists(input_file):
            print_color(f"Error: File {input_file} not found", 'red')
            sys.exit(1)
        
        with open(input_file, 'r') as f:
            diagram_code = f.read()
        
        live_url = generate_mermaid_live_url(diagram_code)
        ink_url = generate_mermaid_ink_url(diagram_code, width=1200, height=800)
        
        print_color("🔗 Mermaid Live Editor URL:", 'green')
        print(live_url)
        print()
        print_color("🖼️ Direct PNG URL (mermaid.ink):", 'green')
        print(ink_url)
        print()
        print_color("💡 Tip: You can adjust width/height in the URL", 'yellow')
        sys.exit(0)
    
    # Parse arguments
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else input_file.replace('.mmd', '.png')
    width = int(sys.argv[3]) if len(sys.argv) > 3 else 1200
    height = int(sys.argv[4]) if len(sys.argv) > 4 else 800
    
    if not os.path.exists(input_file):
        print_color(f"Error: File {input_file} not found", 'red')
        sys.exit(1)
    
    print_color(f"📝 Input: {input_file}", 'blue')
    print_color(f"🖼️ Output: {output_file}", 'blue')
    print_color(f"📐 Dimensions: {width}x{height}", 'blue')
    print()
    
    # Read diagram
    with open(input_file, 'r') as f:
        diagram_code = f.read()
    
    # Show preview of diagram
    lines = diagram_code.strip().split('\n')
    print_color("📋 Diagram preview:", 'yellow')
    for i, line in enumerate(lines[:5]):
        print(f"  {line}")
    if len(lines) > 5:
        print(f"  ... ({len(lines) - 5} more lines)")
    print()
    
    # Generate and download image
    ink_url = generate_mermaid_ink_url(diagram_code, width=width, height=height)
    
    if download_image(ink_url, output_file):
        print_color(f"✅ Image saved successfully!", 'green')
        
        # Show file info
        info = get_image_info(output_file)
        if info:
            print_color(f"📊 File info: {info}", 'green')
        
        # Generate Jekyll markdown
        print()
        print_color("📝 Jekyll/Markdown code:", 'blue')
        basename = os.path.basename(output_file)
        markdown = f'![Workflow Diagram](/assets/images/{basename}){{:style="display:block; margin-left:auto; margin-right:auto; width:100%; max-width:1200px;"}}'
        print(markdown)
        
        # Show URLs for reference
        print()
        print_color("🔗 For editing, use Mermaid Live:", 'yellow')
        live_url = generate_mermaid_live_url(diagram_code)
        print(live_url[:100] + "...")
        
    else:
        print_color("❌ Failed to generate image", 'red')
        print_color("🔗 Try manually downloading from:", 'yellow')
        print(ink_url)

if __name__ == "__main__":
    main()