---
layout: home
pageClass: my-index-page

hero:
  name: "Fontist"
  text: "Cross-platform font management"
  tagline: Install, manage, and build fonts programmatically. Works identically on Windows, macOS, and Linux.
  actions:
    - theme: brand
      text: Get Started
      link: /guide/
    - theme: alt
      text: CLI Reference
      link: /cli/
    - theme: alt
      text: Ruby API
      link: /api/

features:
  - title: "🌐 Cross-Platform"
    details: Same commands work identically on Windows, macOS, and Linux. No platform-specific paths to remember.
  - title: "📦 Formula-Based"
    details: 3000+ fonts available through community-maintained formulas with automatic download and license handling.
  - title: "📋 Manifest Support"
    details: Define font requirements in YAML for reproducible installations across environments and CI/CD pipelines.
  - title: "🔄 CI/CD Ready"
    details: Perfect for automated environments with non-interactive installation. GitHub Action available.
  - title: "🔍 System Detection"
    details: Detects and indexes fonts already installed on your system. No redundant downloads.
  - title: "⚡ Fontconfig Integration"
    details: Optional fontconfig integration for seamless font discovery in Linux environments.
---

<WithinHero>
<HeroCodeBlock title="fontist"><div class="line"><span class="comment"># 🚀 Install a font by name</span></div><div class="line"><span class="prompt">$</span> <span class="cmd">fontist</span> install "Open Sans"</div><div class="line"><span class="success">✓</span> Open Sans installed to ~/.fontist/fonts</div><div class="line">&nbsp;</div><div class="line"><span class="comment"># 📜 Install from manifest</span></div><div class="line"><span class="prompt">$</span> <span class="cmd">fontist</span> manifest-install manifest.yml</div><div class="line"><span class="success">✓</span> All fonts from manifest installed</div><div class="line">&nbsp;</div><div class="line"><span class="comment"># 🔍 Check font status</span></div><div class="line"><span class="prompt">$</span> <span class="cmd">fontist</span> status "Fira Code"</div><div class="line"><span class="success">✓</span> Fira Code Regular, Bold installed</div></HeroCodeBlock>
</WithinHero>

## Quick Start

```bash
# Install a font by name
fontist install "Open Sans"

# Install from a manifest file
fontist manifest-install manifest.yml

# Check font status
fontist status "Fira Code"
```

## Use Cases

**CI/CD Pipelines** — Automatically install fonts in GitHub Actions, GitLab CI, or any automation system. Non-interactive mode ensures reliable, reproducible builds.

**Document Publishing** — Essential for Metanorma, Asciidoctor, and other document generation tools that require specific fonts for PDF rendering.

**Development Environments** — Ensure consistent fonts across team machines without manual installation. One command sets up everything.

## Why Fontist?

Most font management approaches are either manual (download, unzip, install) or platform-specific (apt-get, brew). Fontist provides a unified, scriptable interface that works the same everywhere.

| Feature | Fontist | Manual Install | apt-get/brew |
|--------|---------|----------------|--------------|
| Cross-platform | Same commands | Platform-specific | No |
| Formula-based | 3000+ fonts | Manual download | Limited selection |
| Manifest support | YAML-based | Not available | Not available |
| CI/CD Ready | Non-interactive | Complex setup | Complex setup |
| System Detection | Detects existing fonts | May miss fonts | May miss fonts |

[Learn more about why Fontist might be right for your project →](/guide/why)
