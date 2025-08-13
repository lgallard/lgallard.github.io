#!/usr/bin/env python3
"""
Save the improved vertical workflow diagrams
"""

import base64
import urllib.request
import os

def generate_mermaid_ink_url(diagram_code, format='png', width=800, height=1000):
    """Generate Mermaid.ink URL for vertical diagrams"""
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
                'User-Agent': 'Mozilla/5.0 (Vertical Diagram Generator)',
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
    print("🎨 Generating Vertical Workflow Diagrams")
    print()
    
    # Traditional workflow diagram - vertical layout
    traditional_workflow = '''graph TD
    A[🔍 Quick Google Search] --> B[📋 Browse Terraform Registry]
    B --> C[📖 Skim Documentation<br/><small>Often outdated</small>]
    C --> D[⚡ Start Implementing<br/><small>Based on limited info</small>]
    D --> E[❌ Discover Limitations<br/><small>During development</small>]
    E --> F[💸 Costly Refactor/Switch<br/><small>Time & resources wasted</small>]
    
    style A fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    style B fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    style C fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    style D fill:#fff8e1,stroke:#fbc02d,stroke-width:2px
    style E fill:#ffebee,stroke:#d32f2f,stroke-width:3px
    style F fill:#fce4ec,stroke:#c2185b,stroke-width:3px'''
    
    # MCP workflow diagram - improved structure
    mcp_workflow = '''graph TD
    A[🤖 Terraform MCP Server] --> B[🔍 Registry API Search]
    A --> C[📚 Context7 Docs Retrieval]
    
    B --> D[📊 Generate Comparisons]
    C --> D
    
    D --> E[⚙️ Analyze Features<br/><small>Comprehensive analysis</small>]
    E --> F[✅ Informed Decision<br/><small>Data-backed choice</small>]
    F --> G[🚀 Confident Implementation<br/><small>Optimal solution</small>]
    
    style A fill:#c8e6c9,stroke:#388e3c,stroke-width:3px
    style B fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style C fill:#c8e6c9,stroke:#388e3c,stroke-width:3px
    style D fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style E fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
    style F fill:#e8eaf6,stroke:#3f51b5,stroke-width:3px
    style G fill:#f3e5f5,stroke:#7b1fa2,stroke-width:3px'''
    
    # Generate URLs and download images with optimal sizing
    traditional_url = generate_mermaid_ink_url(traditional_workflow, width=800, height=1000)
    mcp_url = generate_mermaid_ink_url(mcp_workflow, width=800, height=1200)
    
    success1 = download_image(traditional_url, 'assets/images/traditional-workflow-vertical.png')
    success2 = download_image(mcp_url, 'assets/images/mcp-workflow-vertical.png')
    
    if success1 and success2:
        print()
        print("🎉 All vertical diagrams generated successfully!")
        print()
        print("📝 Jekyll markdown for traditional workflow:")
        print('![Traditional Development Workflow](/assets/images/traditional-workflow-vertical.png){:style="display:block; margin-left:auto; margin-right:auto; width:80%; max-width:800px;"}')
        print()
        print("📝 Jekyll markdown for MCP workflow:")
        print('![MCP Server Development Workflow](/assets/images/mcp-workflow-vertical.png){:style="display:block; margin-left:auto; margin-right:auto; width:80%; max-width:800px;"}')
    else:
        print("❌ Some diagrams failed to generate")

if __name__ == "__main__":
    main()