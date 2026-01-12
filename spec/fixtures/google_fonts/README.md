# Google Fonts Metadata Fixtures

This directory contains sample METADATA.pb files from the Google Fonts repository for testing purposes.

These files are used by `spec/fontist/import/google/metadata_adapter_spec.rb` to test the metadata parsing functionality without requiring the full google-fonts repository.

## Files

- `abeezee/METADATA.pb` - Simple font with 2 variants (Regular, Italic)
- `alexandria/METADATA.pb` - Variable font with 1 axis (wght) 
- `robotoflex/METADATA.pb` - Complex variable font with 13 axes
- `notosans/METADATA.pb` - Large font with 800+ language support

## Source

These files are copied from the [google/fonts](https://github.com/google/fonts) repository.

## License

These metadata files are used for testing purposes. The actual fonts are licensed under their respective licenses (typically OFL).
