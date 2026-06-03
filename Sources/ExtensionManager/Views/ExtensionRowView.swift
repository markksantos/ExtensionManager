import SwiftUI

struct ExtensionRowView: View {
    let ext: SystemExtension
    @ObservedObject var viewModel: ExtensionViewModel

    var body: some View {
        HStack(spacing: 10) {
            AppIconView(extension: ext, size: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(ext.appName)
                    .font(.headline)
                    .lineLimit(1)
                Text(ext.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(ext.category.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ext.category.color.opacity(0.15))
                    .foregroundStyle(ext.category.color)
                    .clipShape(Capsule())

                if !ext.isEnabled {
                    Text("Disabled")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 3)
        .contextMenu {
            Button("Copy Bundle ID") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(ext.bundleIdentifier, forType: .string)
            }
            Button("Reveal in Finder") {
                viewModel.revealInFinder(ext)
            }
            .disabled(!ext.hasFileLocation)
            Divider()
            Button("Move to Trash", role: .destructive) {
                viewModel.moveToTrash(ext)
            }
            .disabled(!ext.hasFileLocation)
        }
    }
}
