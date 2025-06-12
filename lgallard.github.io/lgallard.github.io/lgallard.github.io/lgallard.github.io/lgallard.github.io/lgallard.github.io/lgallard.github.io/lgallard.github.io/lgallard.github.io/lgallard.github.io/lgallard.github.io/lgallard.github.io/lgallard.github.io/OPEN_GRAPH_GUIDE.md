# Open Graph Configuration for Slack Previews

Your Jekyll site is now configured with comprehensive Open Graph tags to enable rich previews when sharing links on Slack, Twitter, Facebook, and other social media platforms.

## What's Been Configured

### Site-wide Settings (`_config.yml`)
- ✅ **Site description**: Added a professional description for your blog
- ✅ **Default Open Graph image**: Set to your profile picture (`/assets/images/luis.jpg`)
- ✅ **Twitter username**: Already configured as `@lgallard`

### SEO Template (`_includes/seo.html`)
- ✅ **Complete Open Graph tags**: Including `og:type`, `og:title`, `og:description`, `og:image`
- ✅ **Twitter Card support**: With `summary_large_image` for posts with images
- ✅ **Article metadata**: Publication time, author, tags, and categories for blog posts
- ✅ **Image dimensions**: Proper width/height for optimal display
- ✅ **Schema.org structured data**: For better SEO

## How to Optimize Individual Posts

To get the best Slack previews for your blog posts, add these to your post's front matter:

```yaml
---
title: "Your Post Title"
excerpt: "A compelling description that will appear in social media previews"
header:
  image: "/assets/images/your-post-image.jpg"  # 1200x630px recommended
  teaser: "/assets/images/your-post-teaser.jpg" # For smaller previews
tags: [devops, kubernetes, aws]
categories: [tutorials]
---
```

### Image Recommendations

1. **Header Image**: 1200x630 pixels (optimal for Facebook/Slack)
2. **Teaser Image**: 400x400 pixels (for smaller previews)
3. **Format**: JPG or PNG
4. **File Size**: Keep under 300KB for fast loading

## Testing Your Open Graph Tags

### Using Online Tools
1. **Facebook Debugger**: https://developers.facebook.com/tools/debug/
2. **Twitter Card Validator**: https://cards-dev.twitter.com/validator
3. **LinkedIn Post Inspector**: https://www.linkedin.com/post-inspector/

### Manual Testing
1. Share a blog post link in Slack
2. Check if the preview shows:
   - Post title
   - Description/excerpt
   - Featured image
   - Your site name

## Priority Hierarchy for Images

The system will use images in this order:
1. `page.header.image` (if specified in post)
2. `page.header.overlay_image` (if specified)
3. `page.header.teaser` (if specified)
4. `site.og_image` (your default profile picture)

## Example Post Front Matter

```yaml
---
layout: single
title: "Deploying Kubernetes with Terraform on AWS"
excerpt: "Learn how to set up a production-ready Kubernetes cluster on AWS using Infrastructure as Code principles with Terraform and Terragrunt."
header:
  image: "/assets/images/posts/k8s-terraform-aws.jpg"
  teaser: "/assets/images/posts/k8s-terraform-aws-teaser.jpg"
tags: [kubernetes, terraform, aws, devops, infrastructure]
categories: [tutorials, devops]
author_profile: true
read_time: true
comments: true
share: true
related: true
---
```

## Troubleshooting

### Cache Issues
- Social media platforms cache Open Graph data
- Use debugging tools to refresh the cache
- Changes may take a few minutes to appear

### Missing Images
- Ensure images exist in your `assets/images/` directory
- Check that paths are correct (relative to site root)
- Verify images are accessible via direct URL

### No Preview Appearing
1. Check that your site is publicly accessible
2. Verify the URL structure is correct
3. Ensure `site.url` in `_config.yml` matches your domain
4. Test with the debugging tools mentioned above 