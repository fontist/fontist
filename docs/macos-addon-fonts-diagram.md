# macOS Add-on Fonts - Visual Architecture

## Component Hierarchy

```mermaid
graph TB
    subgraph "User Interface Layer"
        CLI[fontist CLI<br/>macos commands]
        API[Ruby API<br/>Fontist::Font]
    end
    
    subgraph "Core Logic Layer"
        Font[Fontist::Font<br/>install/find/status]
        Formula[Fontist::Formula<br/>formula lookup]
        FontInstaller[Fontist::FontInstaller<br/>orchestrates installation]
    end
    
    subgraph "Resource Layer"
        MacOSResource[Resources::<br/>MacOSAssetResource<br/>files method]
        ArchiveResource[Resources::<br/>ArchiveResource]
        GoogleResource[Resources::<br/>GoogleResource]
    end
    
    subgraph "macOS Integration Layer"
        AssetCatalog[MacOS::<br/>AssetCatalog<br/>XML parser]
        AssetInstaller[MacOS::<br/>AssetInstaller<br/>system integration]
        AssetFont[MacOS::<br/>AssetFont<br/>Lutaml Model]
    end
    
    subgraph "System Layer"
        XML[/System/Library/<br/>AssetsV2/*.xml]
        Assets[/System/Library/<br/>AssetsV2/*.asset/]
        FontBook[Font Book.app]
    end
    
    CLI --> Font
    API --> Font
    Font --> Formula
    Font --> FontInstaller
    FontInstaller --> MacOSResource
    FontInstaller --> ArchiveResource
    FontInstaller --> GoogleResource
    MacOSResource --> AssetCatalog
    MacOSResource --> AssetInstaller
    AssetCatalog --> AssetFont
    AssetCatalog --> XML
    AssetInstaller --> AssetFont
    AssetInstaller --> Assets
    AssetInstaller -.fallback.-> FontBook
    
    style MacOSResource fill:#e1f5ff
    style AssetCatalog fill:#e1f5ff
    style AssetInstaller fill:#e1f5ff
    style AssetFont fill:#e1f5ff
```

## Installation Flow

```mermaid
sequenceDiagram
    actor User
    participant CLI as fontist CLI
    participant Font as Fontist::Font
    participant Installer as FontInstaller
    participant Resource as MacOSAssetResource
    participant Catalog as AssetCatalog
    participant SysInstaller as AssetInstaller
    participant System as macOS System
    
    User->>CLI: fontist install "SF Mono"
    CLI->>Font: install("SF Mono")
    Font->>Font: find_system_font?
    
    alt Font not installed
        Font->>Formula: find("SF Mono")
        Formula-->>Font: formula (source: macos_asset)
        Font->>Installer: install(formula)
        Installer->>Resource: files(["SFMono-Regular", ...])
        
        loop For each PostScript name
            Resource->>Catalog: find_by_postscript_name(ps_name)
            Catalog-->>Resource: AssetFont
            Resource->>SysInstaller: install(asset)
            
            alt Not installed
                SysInstaller->>System: trigger_installation()
                System-->>SysInstaller: installation_started
                
                loop Wait for completion
                    SysInstaller->>System: check if installed
                    System-->>SysInstaller: status
                end
                
                SysInstaller-->>Resource: font_files
            else Already installed
                SysInstaller-->>Resource: font_files
            end
            
            Resource-->>Installer: yield path
        end
        
        Installer-->>Font: installed_paths
        Font-->>CLI: success
        CLI-->>User: "Fonts installed at: ..."
    else Already installed
        Font-->>CLI: paths
        CLI-->>User: "Fonts found at: ..."
    end
```

## Class Relationships

```mermaid
classDiagram
    class AssetFont {
        +String asset_id
        +String asset_type
        +String relative_path
        +String font_family
        +String display_name
        +Array~String~ postscript_names
        +installed?() bool
        +installation_path() String
        +font_files() Array~String~
    }
    
    class AssetCatalog {
        -Array~AssetFont~ assets
        -String catalog_path
        +find_by_family(name) Array~AssetFont~
        +find_by_postscript_name(name) AssetFont
        +all_assets() Array~AssetFont~
        -parse_catalog() Array~AssetFont~
    }
    
    class AssetInstaller {
        -AssetFont asset
        -Integer timeout
        -Boolean no_progress
        +install() Array~String~
        -trigger_installation()
        -wait_for_installation()
        -verify_installation()
    }
    
    class MacOSAssetResource {
        -Resource resource
        -Hash options
        +files(source_names) Array~String~
        -install_and_yield_font(ps_name)
        -find_asset(ps_name) AssetFont
    }
    
    class FontInstaller {
        -Formula formula
        -String font_name
        +install(confirmation) Array~String~
        -resource() BaseResource
        -install_font_file(source) String
    }
    
    class Resource {
        +String source
        +Array~String~ urls
        +Array~String~ postscript_names
        +String family
    }
    
    AssetCatalog "1" --> "*" AssetFont : manages
    AssetInstaller "1" --> "1" AssetFont : installs
    MacOSAssetResource "1" --> "1" AssetCatalog : queries
    MacOSAssetResource "1" --> "*" AssetInstaller : uses
    FontInstaller "1" --> "1" MacOSAssetResource : delegates
    FontInstaller "1" --> "1" Resource : uses
    Resource "1" --> "*" AssetFont : references
```

## Data Flow - Formula to Installed Font

```mermaid
flowchart LR
    subgraph Input
        Formula[Formula YAML<br/>source: macos_asset<br/>postscript_names: ...]
    end
    
    subgraph Processing
        Parse[Parse Formula]
        Lookup[Lookup in Catalog]
        Check[Check Installed?]
        Trigger[Trigger Installation]
        Wait[Wait & Verify]
    end
    
    subgraph Output
        Paths[Font File Paths]
        SystemIndex[Update System Index]
    end
    
    Formula --> Parse
    Parse --> Lookup
    Lookup --> Check
    Check -->|Not Installed| Trigger
    Check -->|Already Installed| Paths
    Trigger --> Wait
    Wait --> Paths
    Paths --> SystemIndex
    
    style Formula fill:#fff4e6
    style Paths fill:#e7f5e7
```

## Platform Detection Flow

```mermaid
flowchart TD
    Start[fontist install font_name]
    DetectOS{Utils::System<br/>user_os}
    
    DetectOS -->|macos| CheckFormula{Formula<br/>source type?}
    DetectOS -->|linux/windows| OtherPlatform[Use ArchiveResource<br/>or GoogleResource]
    
    CheckFormula -->|macos_asset| CheckPlatforms{platforms<br/>attribute?}
    CheckFormula -->|other| OtherPlatform
    
    CheckPlatforms -->|includes macos| Proceed[Use MacOSAssetResource]
    CheckPlatforms -->|excludes macos| Error[Raise<br/>Platform Not Supported]
    CheckPlatforms -->|nil/empty| Proceed
    
    Proceed --> Install[Install via<br/>macOS System]
    
    style Start fill:#e1f5ff
    style Install fill:#e7f5e7
    style Error fill:#ffe7e7
```

## Error Handling Strategy

```mermaid
flowchart TD
    InstallAttempt[Attempt Installation]
    
    InstallAttempt --> Check1{macOS System?}
    Check1 -->|No| E1[NotMacOSError]
    Check1 -->|Yes| Check2{Catalog Found?}
    
    Check2 -->|No| E2[MacOSAssetCatalogNotFound]
    Check2 -->|Yes| Check3{Asset in Catalog?}
    
    Check3 -->|No| E3[MacOSAssetNotFound]
    Check3 -->|Yes| Check4{Installation Method<br/>Available?}
    
    Check4 -->|No| E4[MacOSAssetManualInstallRequired<br/>Show Font Book Instructions]
    Check4 -->|Yes| TriggerInstall[Trigger Installation]
    
    TriggerInstall --> Wait[Wait for Completion]
    
    Wait --> Check5{Timeout?}
    Check5 -->|Yes| E5[MacOSAssetInstallationTimeout]
    Check5 -->|No| Check6{Installation Failed?}
    
    Check6 -->|Yes| E6[MacOSAssetInstallationFailed]
    Check6 -->|No| Success[Return Font Paths]
    
    style Success fill:#e7f5e7
    style E1 fill:#ffe7e7
    style E2 fill:#ffe7e7
    style E3 fill:#ffe7e7
    style E4 fill:#fff4e6
    style E5 fill:#ffe7e7
    style E6 fill:#ffe7e7
```

## Import Process

```mermaid
flowchart TB
    Start[fontist import<br/>macos-assets]
    
    Read[Read Asset Catalog XML]
    Parse[Parse All Assets]
    
    Filter{For Each Asset}
    Skip[Skip Pre-installed]
    Build[Build Formula]
    
    AddResource[Add Resource:<br/>source: macos_asset<br/>postscript_names: ...]
    AddFonts[Add Font Styles]
    
    Save[Save YAML to<br/>Formulas/macos/]
    
    Done[Complete:<br/>~700 formulas generated]
    
    Start --> Read
    Read --> Parse
    Parse --> Filter
    Filter -->|Installed| Skip
    Filter -->|Not Installed| Build
    Skip --> Filter
    Build --> AddResource
    AddResource --> AddFonts
    AddFonts --> Save
    Save --> Filter
    Filter -->|All Done| Done
    
    style Start fill:#e1f5ff
    style Done fill:#e7f5e7
```

## Formula Structure Comparison

```mermaid
graph LR
    subgraph "Traditional Formula"
        T1[resources:<br/>  urls: [...]<br/>  sha256: ...]
        T2[fonts:<br/>  styles with files]
        T3[Extract archive<br/>Copy to ~/.fontist]
    end
    
    subgraph "macOS Asset Formula"
        M1[resources:<br/>  source: macos_asset<br/>  postscript_names: [...]<br/>  family: ...]
        M2[fonts:<br/>  styles with PS names]
        M3[Request from system<br/>Stay in system location]
    end
    
    T1 --> T2
    T2 --> T3
    
    M1 --> M2
    M2 --> M3
    
    style T1 fill:#fff
    style T2 fill:#fff
    style T3 fill:#fff
    style M1 fill:#e1f5ff
    style M2 fill:#e1f5ff
    style M3 fill:#e1f5ff