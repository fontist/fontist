---
title: Maintainer Documentation
---

# Maintainer Documentation

::: warning For Fontist Maintainers Only
This section contains documentation for Fontist formula maintainers. End users typically do not need these commands.
:::

## Topics

### [Import Commands](/guide/maintainer/import)

Import fonts from external sources to create Fontist formulas:
- Google Fonts
- macOS supplementary fonts
- SIL International fonts

---

## Who Should Use These Commands?

You should use these commands if you are:

- A **Fontist formula maintainer** updating the official formula repository
- Creating formulas from **large font collections** (Google Fonts, macOS, SIL)
- Contributing new formulas to the **fontist/formulas** repository

## Regular Users

If you just want to install fonts, you don't need these commands. Instead:

- Use `fontist install "Font Name"` to install fonts
- Use `fontist create-formula <url>` to create a single formula from a font archive

See the [Getting Started Guide](/guide/) for regular usage.
