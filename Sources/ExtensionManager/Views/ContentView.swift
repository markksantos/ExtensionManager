import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: ExtensionViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 300)
        } content: {
            ExtensionListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 280, ideal: 340, max: 500)
        } detail: {
            ExtensionDetailView(viewModel: viewModel)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isScanning)
                .help("Rescan for extensions")

                Button {
                    viewModel.exportExtensionList()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(viewModel.extensions.isEmpty)
                .help("Export extension list as JSON")

                Button {
                    openWindow(id: "settings")
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .help("Open settings")
            }
        }
        .task {
            await viewModel.scan()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
