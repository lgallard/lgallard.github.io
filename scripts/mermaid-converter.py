#!/usr/bin/env python3
"""
Mermaid Diagram to Image Converter
Converts Mermaid diagrams to images using online service or local CLI
"""

import base64
import json
import os
import sys
import subprocess
from urllib.parse import quote

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

def generate_mermaid_live_url(diagram_code):
    """Generate a Mermaid Live Editor URL with the diagram"""
    # Encode the diagram
    diagram_json = {
        "code": diagram_code,
        "mermaid": {
            "theme": "default"
        },
        "updateEditor": False
    }
    
    # Convert to base64
    json_str = json.dumps(diagram_json)
    encoded = base64.b64encode(json_str.encode()).decode()
    
    # Create URL
    url = f"https://mermaid.live/edit#base64:{encoded}"
    return url

def generate_kroki_url(diagram_code, format='png'):
    """Generate a Kroki.io URL for the diagram"""
    import zlib
    
    # Compress and encode
    compressed = zlib.compress(diagram_code.encode('utf-8'), 9)
    encoded = base64.urlsafe_b64encode(compressed).decode('ascii')
    
    # Create URL
    url = f"https://kroki.io/mermaid/{format}/{encoded}"
    return url

def download_image(url, output_file):
    """Download image from URL"""
    try:
        import urllib.request
        urllib.request.urlretrieve(url, output_file)
        return True
    except Exception as e:
        print_color(f"Error downloading image: {e}", 'red')
        return False

def create_sample_diagrams():
    """Create sample Mermaid diagram files"""
    samples = {
        'traditional-workflow.mmd': '''graph LR
    A[Quick Google<br/>Search] --> B[Browse Terraform<br/>Registry]
    B --> C[Skim<br/>Documentation]
    C --> D[Start<br/>Implementing]
    D --> E["🔴 Discover<br/>Limitations"]
    E --> F["🔴 Costly<br/>Refactor/Switch"]
    
    style A fill:#f8f9fa,stroke:#dee2e6,stroke-width:2px
    style B fill:#f8f9fa,stroke:#dee2e6,stroke-width:2px
    style C fill:#f8f9fa,stroke:#dee2e6,stroke-width:2px
    style D fill:#f8f9fa,stroke:#dee2e6,stroke-width:2px
    style E fill:#ffe3e3,stroke:#ff6b6b,stroke-width:3px,color:#c92a2a
    style F fill:#ffe3e3,stroke:#ff6b6b,stroke-width:3px,color:#c92a2a''',
        
        'mcp-workflow.mmd': '''graph LR
    A["🟢 Terraform<br/>MCP Server"] --> B[Registry API<br/>Search]
    B --> C["🟢 Context7<br/>Docs Retrieval"]
    C --> D[Generate<br/>Comparisons]
    D --> E[Analyze<br/>Features]
    E --> F["🔵 Informed<br/>Decision"]
    F --> G["🔵 Confident<br/>Implementation"]
    
    style A fill:#d3f9d8,stroke:#51cf66,stroke-width:3px,color:#2b8a3e
    style B fill:#f3f4f6,stroke:#9ca3af,stroke-width:2px
    style C fill:#d3f9d8,stroke:#51cf66,stroke-width:3px,color:#2b8a3e
    style D fill:#f3f4f6,stroke:#9ca3af,stroke-width:2px
    style E fill:#f3f4f6,stroke:#9ca3af,stroke-width:2px
    style F fill:#dbe4ff,stroke:#4c6ef5,stroke-width:3px,color:#364fc7
    style G fill:#dbe4ff,stroke:#4c6ef5,stroke-width:3px,color:#364fc7'''
    }
    
    os.makedirs('diagrams', exist_ok=True)
    
    for filename, content in samples.items():
        filepath = os.path.join('diagrams', filename)
        with open(filepath, 'w') as f:
            f.write(content)
        print_color(f"✅ Created sample: {filepath}", 'green')

def main():
    print_color("🎨 Mermaid Diagram to Image Converter", 'blue')
    print()
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python mermaid-converter.py <input.mmd> [output.png]")
        print("  python mermaid-converter.py --samples    # Create sample diagrams")
        print("  python mermaid-converter.py --online <input.mmd>  # Get online editor URL")
        print()
        sys.exit(1)
    
    if sys.argv[1] == '--samples':
        create_sample_diagrams()
        sys.exit(0)
    
    if sys.argv[1] == '--online':
        if len(sys.argv) < 3:
            print_color("Error: Please provide input file", 'red')
            sys.exit(1)
        
        input_file = sys.argv[2]
        if not os.path.exists(input_file):
            print_color(f"Error: File {input_file} not found", 'red')
            sys.exit(1)
        
        with open(input_file, 'r') as f:
            diagram_code = f.read()
        
        # Generate URLs
        mermaid_url = generate_mermaid_live_url(diagram_code)
        kroki_url = generate_kroki_url(diagram_code)
        
        print_color("📎 Mermaid Live Editor URL:", 'green')
        print(mermaid_url)
        print()
        print_color("🖼️ Direct Image URL (Kroki.io):", 'green')
        print(kroki_url)
        print()
        print_color("💡 Tip: You can save the image from Kroki.io URL directly", 'yellow')
        
        # Offer to download
        response = input("Download image from Kroki.io? (y/n): ")
        if response.lower() == 'y':
            output_file = input_file.replace('.mmd', '.png')
            if download_image(kroki_url, output_file):
                print_color(f"✅ Image saved to: {output_file}", 'green')
        
        sys.exit(0)
    
    # Regular conversion
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else input_file.replace('.mmd', '.png')
    
    if not os.path.exists(input_file):
        print_color(f"Error: File {input_file} not found", 'red')
        sys.exit(1)
    
    with open(input_file, 'r') as f:
        diagram_code = f.read()
    
    # Try local mmdc first
    try:
        result = subprocess.run(['mmdc', '--version'], capture_output=True)
        if result.returncode == 0:
            print_color("Using local Mermaid CLI...", 'yellow')
            cmd = ['mmdc', '-i', input_file, '-o', output_file, '-b', 'white', '-w', '1200']
            result = subprocess.run(cmd)
            if result.returncode == 0:
                print_color(f"✅ Image saved to: {output_file}", 'green')
            sys.exit(0)
    except FileNotFoundError:
        pass
    
    # Fallback to online service
    print_color("Mermaid CLI not found, using online service...", 'yellow')
    kroki_url = generate_kroki_url(diagram_code)
    
    if download_image(kroki_url, output_file):
        print_color(f"✅ Image saved to: {output_file}", 'green')
        
        # Generate Jekyll markdown
        print()
        print_color("📝 Jekyll/Markdown code:", 'blue')
        markdown = f'![Workflow Diagram](/assets/images/{os.path.basename(output_file)}){{:style="display:block; margin-left:auto; margin-right:auto; width:100%; max-width:1200px;"}}'
        print(markdown)
    else:
        print_color("Failed to generate image", 'red')
        print_color(f"You can manually save the image from: {kroki_url}", 'yellow')

if __name__ == "__main__":
    main()