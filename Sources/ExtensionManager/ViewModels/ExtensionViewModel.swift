import SwiftUI

@MainActor
class ExtensionViewModel: ObservableObject {
    @Published var extensions: [SystemExtension] = []
    @Published var selectedCategory: ExtensionCategory? = nil
    @Published var searchText: String = ""
    @Published var selectedExtension: SystemExtension? = nil
    @Published var isScanning: Bool = false
    @Published var errorMessage: String? = nil
    @Published var aiDescriptions: [String: String] = [:]
    @Published var aiLoadingIDs: Set<String> = []

    private let scanner = ExtensionScanner()

    var filteredExtensions: [SystemExtension] {
        var result = extensions
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.appName.lowercased().contains(query) ||
                $0.bundleIdentifier.lowercased().contains(query) ||
                $0.displayName.lowercased().contains(query) ||
                $0.parentName.lowercased().contains(query)
            }
        }
        return result.sorted { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }
    }

    var categoryCounts: [ExtensionCategory: Int] {
        Dictionary(grouping: extensions, by: \.category).mapValues(\.count)
    }

    var totalCount: Int { extensions.count }

    /// Extensions grouped by parent app name
    var groupedByApp: [(appName: String, extensions: [SystemExtension])] {
        let grouped = Dictionary(grouping: filteredExtensions) { $0.appName }
        return grouped.sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { (appName: $0.key, extensions: $0.value) }
    }

    func scan() async {
        isScanning = true
        errorMessage = nil
        let results = await scanner.scanAll()
        extensions = results
        isScanning = false
    }

    func refresh() async {
        aiDescriptions.removeAll()
        aiLoadingIDs.removeAll()
        AppIconProvider.shared.clearCache()
        await scan()
    }

    func revealInFinder(_ ext: SystemExtension) {
        // Walk up from parentBundlePath or path to find the top-level .app
        let rawPath: String
        if !ext.parentBundlePath.isEmpty {
            rawPath = ext.parentBundlePath
        } else {
            rawPath = ext.path
        }
        let appPath = findTopLevelApp(rawPath)
        let url = URL(fileURLWithPath: appPath)
        // activateFileViewerSelecting highlights the file in Finder
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func moveToTrash(_ ext: SystemExtension) {
        let path: String
        if !ext.parentBundlePath.isEmpty {
            path = findTopLevelApp(ext.parentBundlePath)
        } else {
            path = ext.path
        }
        guard !path.isEmpty else {
            errorMessage = "This extension has no file location and can't be moved to the Trash. Manage it in System Settings instead."
            return
        }
        let url = URL(fileURLWithPath: path)
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            extensions.removeAll { $0.bundleIdentifier == ext.bundleIdentifier }
            if selectedExtension?.bundleIdentifier == ext.bundleIdentifier {
                selectedExtension = nil
            }
        } catch {
            errorMessage = "Failed to move to trash: \(error.localizedDescription)"
        }
    }

    func toggleExtension(_ ext: SystemExtension) {
        let newEnabled = !ext.isEnabled

        // Update UI state immediately (optimistic update)
        if let index = extensions.firstIndex(where: { $0.bundleIdentifier == ext.bundleIdentifier }) {
            let updated = SystemExtension(
                id: ext.id,
                bundleIdentifier: ext.bundleIdentifier,
                version: ext.version,
                path: ext.path,
                sdk: ext.sdk,
                displayName: ext.displayName,
                shortName: ext.shortName,
                parentBundlePath: ext.parentBundlePath,
                parentName: ext.parentName,
                platform: ext.platform,
                category: ext.category,
                isEnabled: newEnabled,
                source: ext.source
            )
            extensions[index] = updated
            selectedExtension = updated
        }

        // Run pluginkit command in background (doesn't block main thread)
        if ext.source == .pluginKit {
            let action = newEnabled ? "use" : "ignore"
            let bundleID = ext.bundleIdentifier
            Task.detached {
                _ = ShellCommand.run("/usr/bin/pluginkit", arguments: ["-e", action, "-i", bundleID])
            }
        } else {
            openSystemSettings(for: ext)
        }
    }

    func openSystemSettings(for ext: SystemExtension) {
        // Open the Login Items & Extensions pane in System Settings
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    func exportExtensionList() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "extensions.json"
        panel.title = "Export Extensions"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let exportData = extensions.map { ext -> [String: Any] in
            [
                "bundleIdentifier": ext.bundleIdentifier,
                "appName": ext.appName,
                "displayName": ext.displayName,
                "version": ext.version,
                "category": ext.category.rawValue,
                "path": ext.path,
                "parentName": ext.parentName,
                "parentBundlePath": ext.parentBundlePath,
                "isEnabled": ext.isEnabled,
                "source": ext.source.rawValue,
                "platform": ext.platform,
                "sdk": ext.sdk,
            ]
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
            try jsonData.write(to: url)
        } catch {
            errorMessage = "Failed to export: \(error.localizedDescription)"
        }
    }

    func fetchAIDescription(for ext: SystemExtension) {
        let apiKey = AppSettings.shared.openAIAPIKey
        guard !apiKey.isEmpty else { return }
        guard aiDescriptions[ext.bundleIdentifier] == nil else { return }
        guard !aiLoadingIDs.contains(ext.bundleIdentifier) else { return }

        aiLoadingIDs.insert(ext.bundleIdentifier)

        Task {
            let description = await OpenAIService.analyzeExtension(
                bundleID: ext.bundleIdentifier,
                displayName: ext.displayName,
                parentName: ext.parentName,
                category: ext.category.rawValue,
                apiKey: apiKey
            )
            aiDescriptions[ext.bundleIdentifier] = description ?? "Unable to analyze this extension."
            aiLoadingIDs.remove(ext.bundleIdentifier)
        }
    }

    private func findTopLevelApp(_ path: String) -> String {
        var current = path
        var lastApp = path
        while current != "/" && current != "" {
            if current.hasSuffix(".app") {
                lastApp = current
            }
            current = (current as NSString).deletingLastPathComponent
        }
        return lastApp
    }
}
