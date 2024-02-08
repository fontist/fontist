---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  # name: "Fontist"
  text: "Manage your fonts effortlessly"
  tagline: Fontist brings cross-platform font management to the command line for Windows, Linux, and macOS. Free and open source.
  image:
    src: /hero.png
  actions:
    - theme: brand
      text: 🚀 Get started
      link: /guide/
    - theme: alt
      text: 💎 Ruby API
      link: /guide/api-ruby
    - theme: alt
      text: 🍰 Formulas
      link: https://fontist.org/formulas/
      target: _self
---

<!-- Excerpt from the Getting Started guide page. Try to keep it in sync! -->

```sh
gem install fontist
```

💎 Don't have Ruby installed? You can [download Ruby from the official Ruby website](https://www.ruby-lang.org/en/downloads/).

Now you're ready to start using Fontist to install fonts on your machine! 🤩

```sh
fontist install "Fira Code"
fontist install "Open Sans"
fontist install "Consolas"
```

<sup>👩‍⚖️ Some fonts may require you to accept license terms regarding their use.</sup>

[📚 Read more in the Getting Started guide](/guide/)
