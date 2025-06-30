#!/usr/bin/env python3
"""
Jekyll to Medium Converter
Converts Jekyll posts to Medium-friendly format for easy copy/paste
Author: Luis Gallardo
"""

import os
import sys
import yaml
import re
import argparse
import webbrowser
from pathlib import Path
from datetime import datetime
from typing import Dict, Optional, List
import frontmatter

class JekyllToMediumConverter:
    """Convert Jekyll posts to Medium-friendly format"""
    
    def __init__(self, base_url: str = "https://lgallardo.com"):
        self.base_url = base_url
        self.output_dir = Path("_medium_output")
        self.output_dir.mkdir(exist_ok=True)
        
    def read_jekyll_post(self, post_path: str) -> Optional[Dict]:
        """Read and parse Jekyll post"""
        try:
            with open(post_path, 'r', encoding='utf-8') as f:
                post = frontmatter.load(f)
                
            return {
                'metadata': post.metadata,
                'content': post.content,
                'file_path': post_path,
                'filename': os.path.basename(post_path)
            }
        except Exception as e:
            print(f"❌ Error reading post {post_path}: {e}")
            return None
    
    def convert_to_medium_format(self, post_data: Dict) -> Dict:
        """Convert Jekyll post to Medium format"""
        metadata = post_data['metadata']
        content = post_data['content']
        
        # Extract basic information
        title = metadata.get('title', 'Untitled')
        excerpt = metadata.get('excerpt', '')
        
        # Process content
        medium_content = self.process_content(content, metadata)
        
        # Extract and clean tags
        jekyll_tags = metadata.get('tags', [])
        categories = metadata.get('categories', [])
        all_tags = jekyll_tags + categories
        medium_tags = self.clean_tags_for_medium(all_tags)
        
        # Generate canonical URL
        canonical_url = self.generate_canonical_url(metadata)
        
        return {
            'title': title,
            'subtitle': excerpt,
            'content': medium_content,
            'tags': medium_tags[:5],  # Medium allows max 5 tags
            'canonical_url': canonical_url,
            'original_metadata': metadata
        }
    
    def process_content(self, content: str, metadata: Dict) -> str:
        """Process Jekyll content for Medium compatibility"""
        
        # Remove Jekyll-specific syntax
        content = self.remove_jekyll_syntax(content)
        
        # Convert markdown tables to Medium-friendly format
        content = self.convert_tables_for_medium(content)
        
        # Convert relative image URLs to absolute
        content = self.convert_image_urls(content)
        
        # Fix internal links
        content = self.convert_internal_links(content)
        
        # Add subtitle if available
        excerpt = metadata.get('excerpt', '')
        if excerpt and excerpt.strip():
            # Add subtitle as italic text
            content = f"*{excerpt.strip()}*\n\n{content}"
        
        # Add canonical link footer
        canonical_url = self.generate_canonical_url(metadata)
        if canonical_url:
            footer = f"\n\n---\n\n*Originally published at [{self.base_url}]({canonical_url})*"
            content += footer
        
        return content
    
    def remove_jekyll_syntax(self, content: str) -> str:
        """Remove Jekyll-specific syntax"""
        
        # Remove Jekyll attributes like {:target="_blank"}
        content = re.sub(r'\{:.*?\}', '', content)
        
        # Remove Jekyll liquid tags like {% include %}
        content = re.sub(r'\{%.*?%\}', '', content)
        
        # Remove Jekyll variables like {{ site.url }}
        content = re.sub(r'\{\{.*?\}\}', '', content)
        
        # Clean up extra whitespace
        content = re.sub(r'\n{3,}', '\n\n', content)
        
        return content.strip()
    
    def convert_image_urls(self, content: str) -> str:
        """Convert relative image URLs to absolute URLs"""
        
        # Match markdown images: ![alt text](/path/to/image)
        def replace_image_url(match):
            alt_text = match.group(1)
            image_path = match.group(2)
            
            # If it's already an absolute URL, leave it
            if image_path.startswith(('http://', 'https://')):
                return match.group(0)
            
            # Convert relative path to absolute
            if image_path.startswith('/'):
                absolute_url = f"{self.base_url}{image_path}"
            else:
                absolute_url = f"{self.base_url}/{image_path}"
            
            return f"![{alt_text}]({absolute_url})"
        
        # Replace image URLs
        content = re.sub(r'!\[(.*?)\]\(([^)]+)\)', replace_image_url, content)
        
        return content
    
    def convert_internal_links(self, content: str) -> str:
        """Convert internal links to absolute URLs"""
        
        def replace_internal_link(match):
            link_text = match.group(1)
            link_url = match.group(2)
            
            # If it's already an absolute URL, leave it
            if link_url.startswith(('http://', 'https://', 'mailto:', '#')):
                return match.group(0)
            
            # Convert relative path to absolute
            if link_url.startswith('/'):
                absolute_url = f"{self.base_url}{link_url}"
            else:
                absolute_url = f"{self.base_url}/{link_url}"
            
            return f"[{link_text}]({absolute_url})"
        
        # Replace internal links
        content = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', replace_internal_link, content)
        
        return content
    
    def convert_tables_for_medium(self, content: str) -> str:
        """Convert markdown tables to Medium-friendly format"""
        
        def replace_table(match):
            table_content = match.group(0)
            lines = table_content.strip().split('\n')
            
            # Parse table
            header_line = None
            data_lines = []
            
            for line in lines:
                line = line.strip()
                if not line or '|' not in line:
                    continue
                # Skip separator lines like |---|---|
                if re.match(r'^\|[\s\-\|:]+\|?$', line):
                    continue
                    
                if header_line is None:
                    header_line = line
                else:
                    data_lines.append(line)
            
            if not header_line or not data_lines:
                return table_content  # Return original if can't parse
            
            # Parse headers and data
            headers = [cell.strip() for cell in header_line.split('|') if cell.strip()]
            
            # Convert to Medium-friendly format
            result = []
            result.append("**📊 Comparison Table:**")
            result.append("")
            
            # Process each row
            for line in data_lines:
                # Split by | and clean up empty cells
                raw_cells = line.split('|')
                cells = []
                for cell in raw_cells:
                    cell = cell.strip()
                    if cell:  # Only add non-empty cells
                        cells.append(cell)
                
                if len(cells) >= 2 and cells[0]:  # Need at least feature name + one value
                    # Use first cell as the feature/row name
                    feature_name = cells[0]
                    result.append(f"🔸 **{feature_name}**")
                    
                    # Add the other columns as bullet points
                    # Match cells to headers, accounting for the fact that first header is the row label
                    for i in range(1, min(len(headers), len(cells))):
                        header = headers[i]
                        cell_content = cells[i]
                        result.append(f"• **{header}:** {cell_content}")
                    result.append("")
            
            result.append("---")
            result.append("")
            
            return '\n'.join(result)
        
        # Find and replace markdown tables
        # This pattern matches tables with at least 2 rows (header + data)
        table_pattern = r'(\|[^\n]*\|(?:\n\|[^\n]*\|)+)'
        content = re.sub(table_pattern, replace_table, content, flags=re.MULTILINE)
        
        return content
    
    def clean_tags_for_medium(self, tags: List[str]) -> List[str]:
        """Clean and format tags for Medium"""
        medium_tags = []
        
        # Mapping of common Jekyll tags to Medium-friendly tags
        tag_mapping = {
            'DevOps': 'devops',
            'Terraform': 'terraform',
            'Kubernetes': 'kubernetes',
            'AWS': 'aws',
            'Docker': 'docker',
            'Python': 'python',
            'JavaScript': 'javascript',
            'Blog': 'blogging',
            'Tutorial': 'tutorial',
            'Guide': 'guide'
        }
        
        for tag in tags:
            # Use mapping if available
            if tag in tag_mapping:
                medium_tags.append(tag_mapping[tag])
            else:
                # Clean up the tag
                clean_tag = re.sub(r'[^a-zA-Z0-9\s-]', '', str(tag))
                clean_tag = re.sub(r'\s+', '-', clean_tag.strip().lower())
                if clean_tag and len(clean_tag) > 1:
                    medium_tags.append(clean_tag)
        
        # Remove duplicates and return max 5
        return list(set(medium_tags))[:5]
    
    def generate_canonical_url(self, metadata: Dict) -> Optional[str]:
        """Generate canonical URL from Jekyll metadata"""
        permalink = metadata.get('permalink')
        if permalink:
            return f"{self.base_url}{permalink}"
        
        # Try to construct from date and title
        date = metadata.get('date')
        title = metadata.get('title')
        
        if date and title:
            if isinstance(date, str):
                try:
                    date = datetime.strptime(date, '%Y-%m-%d')
                except:
                    return None
            
            # Create slug from title
            slug = re.sub(r'[^a-zA-Z0-9\s-]', '', title.lower())
            slug = re.sub(r'\s+', '-', slug.strip())
            
            year = date.year
            month = date.month
            day = date.day
            
            return f"{self.base_url}/{year}/{month:02d}/{day:02d}/{slug}/"
        
        return None
    
    def create_preview_html(self, medium_data: Dict) -> str:
        """Create HTML preview of the Medium post"""
        
        # Simple HTML template
        html_template = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Medium Preview: {title}</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 40px 20px;
            line-height: 1.6;
            color: #333;
        }}
        .header {{
            border-bottom: 2px solid #f0f0f0;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }}
        .title {{
            font-size: 2.5em;
            margin-bottom: 10px;
            color: #2c3e50;
        }}
        .subtitle {{
            font-size: 1.2em;
            color: #7f8c8d;
            font-style: italic;
        }}
        .tags {{
            margin: 20px 0;
        }}
        .tag {{
            display: inline-block;
            background: #e8f5e8;
            color: #2e7d2e;
            padding: 4px 12px;
            margin: 2px 4px 2px 0;
            border-radius: 15px;
            font-size: 0.9em;
        }}
        .content {{
            margin-top: 30px;
        }}
        .copy-section {{
            background: #f8f9fa;
            border: 1px solid #e9ecef;
            border-radius: 8px;
            padding: 20px;
            margin: 30px 0;
        }}
        .copy-button {{
            background: #28a745;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            margin-bottom: 15px;
        }}
        .copy-button:hover {{
            background: #218838;
        }}
        .copy-text {{
            font-family: monospace;
            background: white;
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 15px;
            white-space: pre-wrap;
            max-height: 300px;
            overflow-y: auto;
        }}
        .info {{
            background: #d1ecf1;
            border: 1px solid #bee5eb;
            border-radius: 5px;
            padding: 15px;
            margin: 20px 0;
        }}
        .canonical {{
            margin-top: 20px;
            padding: 15px;
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 5px;
        }}
    </style>
</head>
<body>
    <div class="header">
        <h1 class="title">{title}</h1>
        {subtitle_html}
        <div class="tags">
            {tags_html}
        </div>
        {canonical_html}
    </div>
    
    <div class="info">
        <strong>📋 Instructions:</strong>
        <ol>
            <li>Click "Copy Content" below</li>
            <li>Go to <a href="https://medium.com/new-story" target="_blank">Medium's New Story page</a></li>
            <li>Paste the content</li>
            <li>Add any additional formatting as needed</li>
            <li>Publish!</li>
        </ol>
    </div>
    
    <div class="copy-section">
        <button class="copy-button" onclick="copyContent()">📋 Copy Content for Medium</button>
        <div class="copy-text" id="content-to-copy">{content}</div>
    </div>
    
    <div class="content">
        <h2>Preview (Rendered):</h2>
        <div id="rendered-content"></div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <script>
        function copyContent() {{
            const content = document.getElementById('content-to-copy');
            const textArea = document.createElement('textarea');
            textArea.value = content.textContent;
            document.body.appendChild(textArea);
            textArea.select();
            document.execCommand('copy');
            document.body.removeChild(textArea);
            
            const button = document.querySelector('.copy-button');
            const originalText = button.textContent;
            button.textContent = '✅ Copied!';
            button.style.background = '#28a745';
            
            setTimeout(() => {{
                button.textContent = originalText;
                button.style.background = '#007bff';
            }}, 2000);
        }}
        
        // Render markdown preview
        document.addEventListener('DOMContentLoaded', function() {{
            const content = document.getElementById('content-to-copy').textContent;
            const rendered = marked.parse(content);
            document.getElementById('rendered-content').innerHTML = rendered;
        }});
    </script>
</body>
</html>"""
        
        # Prepare template variables
        subtitle_html = f'<p class="subtitle">{medium_data["subtitle"]}</p>' if medium_data.get("subtitle") else ''
        
        tags_html = ''.join([f'<span class="tag">{tag}</span>' for tag in medium_data["tags"]])
        
        canonical_html = ''
        if medium_data.get("canonical_url"):
            canonical_html = f'''
            <div class="canonical">
                <strong>🔗 Canonical URL:</strong> 
                <a href="{medium_data["canonical_url"]}" target="_blank">{medium_data["canonical_url"]}</a>
            </div>'''
        
        return html_template.format(
            title=medium_data["title"],
            subtitle_html=subtitle_html,
            tags_html=tags_html,
            canonical_html=canonical_html,
            content=medium_data["content"]
        )
    
    def save_output_files(self, medium_data: Dict, post_filename: str) -> Dict[str, str]:
        """Save output files and return their paths"""
        
        # Create base filename without extension
        base_name = Path(post_filename).stem
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # Save markdown content
        md_filename = f"{base_name}_medium_{timestamp}.md"
        md_path = self.output_dir / md_filename
        
        md_content = f"""# {medium_data['title']}

**Tags:** {', '.join(medium_data['tags'])}

**Canonical URL:** {medium_data.get('canonical_url', 'N/A')}

---

{medium_data['content']}
"""
        
        with open(md_path, 'w', encoding='utf-8') as f:
            f.write(md_content)
        
        # Save HTML preview
        html_filename = f"{base_name}_medium_preview_{timestamp}.html"
        html_path = self.output_dir / html_filename
        
        html_content = self.create_preview_html(medium_data)
        
        with open(html_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        return {
            'markdown': str(md_path),
            'html': str(html_path)
        }
    
    def convert_post(self, post_path: str, open_browser: bool = True) -> bool:
        """Convert a Jekyll post to Medium format"""
        
        print(f"📖 Reading Jekyll post: {post_path}")
        
        # Read Jekyll post
        post_data = self.read_jekyll_post(post_path)
        if not post_data:
            return False
        
        # Convert to Medium format
        print("🔄 Converting to Medium format...")
        medium_data = self.convert_to_medium_format(post_data)
        
        # Save output files
        print("💾 Saving output files...")
        file_paths = self.save_output_files(medium_data, post_data['filename'])
        
        # Print summary
        print(f"\n✅ Conversion completed!")
        print(f"📝 Title: {medium_data['title']}")
        print(f"🏷️  Tags: {', '.join(medium_data['tags'])}")
        if medium_data.get('canonical_url'):
            print(f"🔗 Canonical: {medium_data['canonical_url']}")
        
        print(f"\n📁 Output files:")
        print(f"   📄 Markdown: {file_paths['markdown']}")
        print(f"   🌐 Preview:  {file_paths['html']}")
        
        # Open browser preview
        if open_browser:
            print(f"\n🌐 Opening preview in browser...")
            webbrowser.open(f"file://{os.path.abspath(file_paths['html'])}")
        
        return True

def main():
    parser = argparse.ArgumentParser(description='Convert Jekyll posts to Medium format')
    parser.add_argument('post_path', help='Path to Jekyll post file')
    parser.add_argument('--base-url', default='https://lgallardo.com', 
                       help='Base URL for your blog (default: https://lgallardo.com)')
    parser.add_argument('--no-browser', action='store_true', 
                       help='Don\'t open browser preview')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.post_path):
        print(f"❌ Post file not found: {args.post_path}")
        sys.exit(1)
    
    converter = JekyllToMediumConverter(base_url=args.base_url)
    success = converter.convert_post(args.post_path, open_browser=not args.no_browser)
    
    if success:
        print("\n🎉 Ready to publish to Medium!")
        print("   1. Copy the content from the preview page")
        print("   2. Go to https://medium.com/new-story")
        print("   3. Paste and publish!")
    else:
        print("❌ Conversion failed")
        sys.exit(1)

if __name__ == '__main__':
    main() 