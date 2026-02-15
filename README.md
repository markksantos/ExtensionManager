<div align="center">

# 🧩 Extension Manager

**macOS app to discover, browse, and manage all system extensions and plugins on your Mac**

[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=for-the-badge&logo=swift&logoColor=white)](#)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-007AFF?style=for-the-badge&logo=apple&logoColor=white)](#)
[![macOS](https://img.shields.io/badge/macOS-13.0+-000000?style=for-the-badge&logo=apple&logoColor=white)](#)

[Features](#-features) · [Getting Started](#-getting-started) · [Tech Stack](#️-tech-stack)

</div>

---

## ✨ Features

- **Extension Discovery** — Scans PluginKit plugins and System Extensions to find all third-party extensions on your Mac
- **Category Browsing** — Extensions organized by category (Finder, Share, Network, Content Blockers, etc.)
- **Detail View** — See bundle identifier, version, path, parent app, SDK, and enabled/disabled status
- **Enable/Disable** — Toggle extensions on or off directly from the app
- **AI Descriptions** — Optional AI-powered descriptions via OpenAI to explain what each extension does
- **Menu Bar Extra** — Quick access from the macOS menu bar with extension count
- **Flexible Display** — Run as a dock app, menu bar app, or both
- **Smart Filtering** — Automatically filters out Apple system extensions, shows only user-installed

## 🚀 Getting Started

### Prerequisites

- macOS 13.0+
- Xcode 15+ or Swift 5.9+

### Installation

```bash
git clone https://github.com/your-username/ExtensionManager.git
cd ExtensionManager
swift build
swift run
```

Or open `Package.swift` in Xcode.

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| Language | Swift 5.9 |
| UI | SwiftUI |
| Build | Swift Package Manager |
| Scanning | pluginkit CLI, systemextensionsctl |
| Security | Keychain (API key storage) |
| Platform | macOS 13.0+ |

## 📁 Project Structure

```
ExtensionManager/
├── Package.swift
└── Sources/ExtensionManager/
    ├── ExtensionManagerApp.swift    # App entry with MenuBarExtra
    ├── Models/
    │   ├── SystemExtension.swift    # Extension data model
    │   ├── ExtensionCategory.swift  # Category classification
    │   └── AppSettings.swift        # User preferences
    ├── Scanner/
    │   ├── ExtensionScanner.swift   # PluginKit & sysext scanning
    │   └── ShellCommand.swift       # Shell command runner
    ├── Services/
    │   ├── OpenAIService.swift      # AI description generation
    │   ├── KeychainHelper.swift     # Secure key storage
    │   └── AppIconProvider.swift    # Parent app icon lookup
    ├── ViewModels/
    │   └── ExtensionViewModel.swift
    └── Views/
        ├── ContentView.swift
        ├── SidebarView.swift
        ├── ExtensionListView.swift
        ├── ExtensionRowView.swift
        ├── ExtensionDetailView.swift
        └── SettingsView.swift
```

## 📄 License

MIT License © 2025 Mark Santos
