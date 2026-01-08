= macOS Font Platform Versioning Architecture

**DEPRECATED:** This documentation has been superseded.

Please refer to the comprehensive Import Source Architecture documentation:

* link:import-source-architecture.md[Import Source Architecture]

The new architecture covers:

* macOS framework versioning (Font7, Font8)
* Import source polymorphism
* Framework metadata externalization
* Platform compatibility checks
* Versioned filename strategy

All macOS-specific platform versioning is now handled through the `import_source`
attribute with framework metadata stored separately in `MacosFrameworkMetadata`.