import Foundation

enum AppIconMode: String, CaseIterable, Identifiable {
    case dock = "Dock"
    case menuBar = "Menu Bar"
    case both = "Both"
    var id: String { rawValue }
}

@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var iconMode: AppIconMode {
        didSet { UserDefaults.standard.set(iconMode.rawValue, forKey: "iconMode") }
    }

    @Published var openAIAPIKey: String {
        didSet { KeychainHelper.save(key: "openAIAPIKey", value: openAIAPIKey) }
    }

    private init() {
        let savedMode = UserDefaults.standard.string(forKey: "iconMode") ?? AppIconMode.dock.rawValue
        self.iconMode = AppIconMode(rawValue: savedMode) ?? .dock
        self.openAIAPIKey = KeychainHelper.load(key: "openAIAPIKey") ?? ""
    }
}
