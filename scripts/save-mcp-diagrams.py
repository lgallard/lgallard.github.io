#!/usr/bin/env python3
"""
Script to generate and save MCP workflow diagrams
Uses the same Mermaid code that was used with the MCP server
"""

import base64
import urllib.request
import os

def generate_mermaid_ink_url(diagram_code, format='png', width=1200, height=400):
    """Generate Mermaid.ink URL for diagrams"""
    diagram_code = diagram_code.strip()
    encoded = base64.b64encode(diagram_code.encode('utf-8')).decode('ascii')
    url = f"https://mermaid.ink/img/{encoded}?type={format}&width={width}&height={height}"
    return url

def download_image(url, output_file):
    """Download image from URL"""
    try:
        print(f"📥 Downloading: {output_file}")
        req = urllib.request.Request(
            url,
            headers={
                'User-Agent': 'Mozilla/5.0 (MCP Diagram Generator)',
                'Accept': 'image/png,image/*,*/*'
            }
        )
        
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                os.makedirs(os.path.dirname(output_file), exist_ok=True)
                with open(output_file, 'wb') as f:
                    f.write(response.read())
                print(f"✅ Saved: {output_file}")
                return True
            else:
                print(f"❌ HTTP {response.status}: {response.reason}")
                return False
                
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    print("🎨 Generating MCP Workflow Diagrams")
    print()
    
    # Traditional workflow diagram
    traditional_workflow = '''graph LR
    A[Quick Google<br/>Search] --> B[Browse Terraform<br/>Registry]
    B --> C[Skim<br/>Documentation]
    C --> D[Start<br/>Implementing]
    D --> E[Discover<br/>Limitations ⚠️]
    E --> F[Costly<br/>Refactor/Switch 💸]
    
    style A fill:#f8f9fa,stroke:#495057,stroke-width:2px,color:#212529
    style B fill:#f8f9fa,stroke:#495057,stroke-width:2px,color:#212529
    style C fill:#f8f9fa,stroke:#495057,stroke-width:2px,color:#212529
    style D fill:#fff5f5,stroke:#fa5252,stroke-width:2px,color:#212529
    style E fill:#ffe3e3,stroke:#ff6b6b,stroke-width:3px,color:#c92a2a
    style F fill:#ffc9c9,stroke:#ff6b6b,stroke-width:3px,color:#a61e4d'''
    
    # MCP workflow diagram
    mcp_workflow = '''graph LR
    A[Terraform MCP Server 🤖] --> B[Registry API<br/>Search 🔍]
    B --> C[Context7<br/>Docs Retrieval 📚]
    C --> D[Generate<br/>Comparisons 📊]
    D --> E[Analyze<br/>Features ⚙️]
    E --> F[Informed<br/>Decision ✅]
    F --> G[Confident<br/>Implementation 🚀]
    
    style A fill:#d3f9d8,stroke:#37b24d,stroke-width:3px,color:#2b8a3e
    style B fill:#e7f5ff,stroke:#339af0,stroke-width:2px,color:#1864ab
    style C fill:#d3f9d8,stroke:#37b24d,stroke-width:3px,color:#2b8a3e
    style D fill:#e7f5ff,stroke:#339af0,stroke-width:2px,color:#1864ab
    style E fill:#e7f5ff,stroke:#339af0,stroke-width:2px,color:#1864ab
    style F fill:#dbe4ff,stroke:#5c7cfa,stroke-width:3px,color:#364fc7
    style G fill:#d0bfff,stroke:#9775fa,stroke-width:3px,color:#6741d9'''
    
    # Generate URLs and download images
    traditional_url = generate_mermaid_ink_url(traditional_workflow, width=1200, height=400)
    mcp_url = generate_mermaid_ink_url(mcp_workflow, width=1400, height=400)
    
    success1 = download_image(traditional_url, 'assets/images/traditional-workflow-mcp.png')
    success2 = download_image(mcp_url, 'assets/images/mcp-workflow-mcp.png')
    
    if success1 and success2:
        print()
        print("🎉 All diagrams generated successfully!")
        print()
        print("📝 Jekyll markdown for traditional workflow:")
        print('![Traditional Development Workflow](/assets/images/traditional-workflow-mcp.png){:style="display:block; margin-left:auto; margin-right:auto; width:100%; max-width:1200px;"}')
        print()
        print("📝 Jekyll markdown for MCP workflow:")
        print('![MCP Server Development Workflow](/assets/images/mcp-workflow-mcp.png){:style="display:block; margin-left:auto; margin-right:auto; width:100%; max-width:1200px;"}')
    else:
        print("❌ Some diagrams failed to generate")

if __name__ == "__main__":
    main()