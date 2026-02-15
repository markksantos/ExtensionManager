import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var apiKeyVisible = false
    @State private var testStatus: String? = nil
    @State private var isTesting = false

    var body: some View {
        Form {
            Section {
                Picker("Show app icon in:", selection: $settings.iconMode) {
                    ForEach(AppIconMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(iconModeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Appearance", systemImage: "paintbrush")
            }

            Section {
                HStack {
                    if apiKeyVisible {
                        TextField("sk-...", text: $settings.openAIAPIKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        SecureField("sk-...", text: $settings.openAIAPIKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }
                    Button {
                        apiKeyVisible.toggle()
                    } label: {
                        Image(systemName: apiKeyVisible ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }

                HStack {
                    Text("Model: **gpt-4o-mini**")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let status = testStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(status.contains("Success") ? .green : .red)
                    }
                    Button("Test API Key") {
                        testAPIKey()
                    }
                    .disabled(settings.openAIAPIKey.isEmpty || isTesting)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Text("Used to get AI-powered descriptions of what each extension does. Your key is stored locally only.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("OpenAI API", systemImage: "brain")
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 320)
        .navigationTitle("Settings")
    }

    private var iconModeDescription: String {
        switch settings.iconMode {
        case .dock: return "App appears only in the Dock"
        case .menuBar: return "App appears only in the menu bar (no Dock icon)"
        case .both: return "App appears in both the Dock and menu bar"
        }
    }

    private func testAPIKey() {
        isTesting = true
        testStatus = nil
        Task { @MainActor in
            let result = await OpenAIService.analyzeExtension(
                bundleID: "com.test.example",
                displayName: "Test",
                parentName: "Test App",
                category: "Test",
                apiKey: settings.openAIAPIKey
            )
            isTesting = false
            testStatus = result != nil ? "Success" : "Failed - check key"
        }
    }
}
