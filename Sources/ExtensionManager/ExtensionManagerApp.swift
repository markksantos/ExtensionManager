import SwiftUI

@main
struct ExtensionManagerApp: App {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var viewModel = ExtensionViewModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 900, minHeight: 600)
                .environmentObject(settings)
                .onAppear { applyIconMode() }
                .onChange(of: settings.iconMode) { _ in applyIconMode() }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 700)
        .commands {
            // Disable File > New Window to prevent duplicate main windows
            CommandGroup(replacing: .newItem) {}

            CommandGroup(after: .appSettings) {
                Button("Settings...") {
                    openWindow(id: "settings")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        Window("Settings", id: "settings") {
            SettingsView(settings: settings)
        }
        .windowResizability(.contentSize)

        MenuBarExtra("Extension Manager", systemImage: "puzzlepiece.extension") {
            Button("Open Extension Manager") {
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("Refresh Extensions") {
                Task { await viewModel.refresh() }
            }
            Divider()
            Text("\(viewModel.totalCount) extensions found")
                .foregroundStyle(.secondary)
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }

    private func applyIconMode() {
        switch settings.iconMode {
        case .dock:
            NSApplication.shared.setActivationPolicy(.regular)
        case .menuBar:
            NSApplication.shared.setActivationPolicy(.accessory)
        case .both:
            NSApplication.shared.setActivationPolicy(.regular)
        }
    }
}
