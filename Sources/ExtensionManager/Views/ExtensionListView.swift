import SwiftUI

struct ExtensionListView: View {
    @ObservedObject var viewModel: ExtensionViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(headerTitle)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                if viewModel.isScanning {
                    ProgressView()
                        .controlSize(.small)
                    Text("Scanning...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if viewModel.isScanning && viewModel.extensions.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Scanning for extensions...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else if viewModel.filteredExtensions.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("No extensions found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    if !viewModel.searchText.isEmpty {
                        Text("Try adjusting your search")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
            } else {
                List(viewModel.filteredExtensions, selection: $viewModel.selectedExtension) { ext in
                    ExtensionRowView(ext: ext, viewModel: viewModel)
                        .tag(ext)
                }
                .listStyle(.inset)
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search extensions")
    }

    private var headerTitle: String {
        let count = viewModel.filteredExtensions.count
        if let category = viewModel.selectedCategory {
            return "\(count) \(category.rawValue) Extension\(count == 1 ? "" : "s")"
        }
        return "\(count) Extension\(count == 1 ? "" : "s")"
    }
}
