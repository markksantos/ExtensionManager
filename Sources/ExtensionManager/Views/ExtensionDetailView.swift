import SwiftUI

struct ExtensionDetailView: View {
    @ObservedObject var viewModel: ExtensionViewModel
    @State private var showTrashConfirmation = false
    @State private var copiedBundleID = false

    var body: some View {
        if let ext = viewModel.selectedExtension {
            ScrollView {
                VStack(spacing: 20) {
                    header(ext)
                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        aiSection(ext)
                        aboutSection(ext)
                        detailsSection(ext)
                        if !ext.parentName.isEmpty {
                            parentAppSection(ext)
                        }
                        sourceSection(ext)
                    }

                    Divider()
                    actionButtons(ext)
                }
                .padding(24)
            }
            .id(ext.id) // Reset scroll position when switching extensions
            .alert("Move to Trash?", isPresented: $showTrashConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Move to Trash", role: .destructive) {
                    // Read from viewModel at action time to avoid stale capture
                    if let current = viewModel.selectedExtension {
                        viewModel.moveToTrash(current)
                    }
                }
            } message: {
                if let current = viewModel.selectedExtension {
                    Text("This will move \"\(current.appName)\" to the Trash. You can restore it from the Trash if needed.")
                }
            }
            .onAppear {
                viewModel.fetchAIDescription(for: ext)
            }
            .onChange(of: viewModel.selectedExtension) { newValue in
                copiedBundleID = false
                if let ext = newValue {
                    viewModel.fetchAIDescription(for: ext)
                }
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "puzzlepiece.extension")
                    .font(.system(size: 48))
                    .foregroundStyle(.tertiary)
                Text("Select an extension to view details")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func header(_ ext: SystemExtension) -> some View {
        HStack(spacing: 16) {
            AppIconView(extension: ext, size: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(ext.appName)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(ext.displayName.isEmpty ? ext.bundleIdentifier : ext.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(ext.category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ext.category.color.opacity(0.15))
                        .foregroundStyle(ext.category.color)
                        .clipShape(Capsule())
                    Text(ext.isEnabled ? "Enabled" : "Disabled")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ext.isEnabled ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .foregroundStyle(ext.isEnabled ? .green : .red)
                        .clipShape(Capsule())
                    if ext.source == .systemExtension {
                        Text("System")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
        }
    }

    // MARK: - AI Analysis Section

    @ViewBuilder
    private func aiSection(_ ext: SystemExtension) -> some View {
        let apiKey = AppSettings.shared.openAIAPIKey
        if !apiKey.isEmpty {
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.aiLoadingIDs.contains(ext.bundleIdentifier) {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Analyzing extension...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else if let desc = viewModel.aiDescriptions[ext.bundleIdentifier] {
                        Text(desc)
                            .font(.subheadline)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            } label: {
                Label("AI Analysis", systemImage: "brain")
                    .font(.headline)
            }
        }
    }

    // MARK: - About Section

    @ViewBuilder
    private func aboutSection(_ ext: SystemExtension) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: ext.category.iconName)
                        .foregroundStyle(ext.category.color)
                    Text(ext.category.rawValue)
                        .fontWeight(.medium)
                }
                Text(ext.categoryDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        } label: {
            Text("About")
                .font(.headline)
        }
    }

    // MARK: - Details Section

    @ViewBuilder
    private func detailsSection(_ ext: SystemExtension) -> some View {
        GroupBox {
            VStack(spacing: 10) {
                HStack(alignment: .top) {
                    Text("Bundle ID")
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)
                    Text(ext.bundleIdentifier)
                        .font(.system(.subheadline, design: .monospaced))
                        .textSelection(.enabled)
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(ext.bundleIdentifier, forType: .string)
                        copiedBundleID = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copiedBundleID = false
                        }
                    } label: {
                        Image(systemName: copiedBundleID ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("Copy bundle ID")
                }
                Divider()
                detailRow("Version", value: ext.version.isEmpty ? "Unknown" : ext.version)
                Divider()
                detailRow("Platform", value: ext.platform.isEmpty ? "macOS" : ext.platform)
                Divider()
                HStack(alignment: .top) {
                    Text("Path")
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)
                    Text(ext.path)
                        .font(.subheadline)
                        .textSelection(.enabled)
                    Spacer()
                }
            }
            .padding(4)
        } label: {
            Text("Details")
                .font(.headline)
        }
    }

    // MARK: - Parent App Section

    @ViewBuilder
    private func parentAppSection(_ ext: SystemExtension) -> some View {
        GroupBox {
            HStack(spacing: 12) {
                AppIconView(extension: ext, size: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 4) {
                    Text(ext.parentName)
                        .fontWeight(.medium)
                    if !ext.parentBundlePath.isEmpty {
                        Text(ext.parentBundlePath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                Spacer()
            }
            .padding(4)
        } label: {
            Text("Parent App")
                .font(.headline)
        }
    }

    // MARK: - Source Section

    @ViewBuilder
    private func sourceSection(_ ext: SystemExtension) -> some View {
        GroupBox {
            VStack(spacing: 10) {
                detailRow("Discovery Source", value: ext.source.rawValue)
                Divider()
                detailRow("SDK", value: ext.sdk)
            }
            .padding(4)
        } label: {
            Text("Source")
                .font(.headline)
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private func actionButtons(_ ext: SystemExtension) -> some View {
        VStack(spacing: 14) {
            // Enable/Disable toggle
            GroupBox {
                Toggle(isOn: Binding(
                    get: { viewModel.selectedExtension?.isEnabled ?? ext.isEnabled },
                    set: { _ in
                        if let current = viewModel.selectedExtension {
                            viewModel.toggleExtension(current)
                        }
                    }
                )) {
                    HStack {
                        Image(systemName: ext.isEnabled ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(ext.isEnabled ? .green : .red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Extension \(ext.isEnabled ? "Enabled" : "Disabled")")
                                .fontWeight(.medium)
                            if ext.source == .systemExtension {
                                Text("System extensions must be managed in System Settings")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .toggleStyle(.switch)
                .padding(4)
            }

            HStack(spacing: 12) {
                Button {
                    viewModel.revealInFinder(ext)
                } label: {
                    Label("Reveal in Finder", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.openSystemSettings(for: ext)
                } label: {
                    Label("System Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button(role: .destructive) {
                showTrashConfirmation = true
            } label: {
                Label("Move to Trash", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func detailRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
            Spacer()
        }
    }
}
