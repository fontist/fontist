# Why Fontist?

In general, fonts can be downloaded manually and placed in a system folder. Some fonts are even pre-installed with an OS. **This is inconsistent across Windows, macOS, and Linux.**

Fontist is a higher level abstraction that lets you use `fontist install` (or the `Fontist::Fontist` Ruby library) to manage your fonts with the same API across multiple platforms.

Fontist uses a formula repository to find where to download a requested font. The main formula repository contains a lot of fonts, including Google Fonts, SIL Fonts, and macOS add-on fonts.
