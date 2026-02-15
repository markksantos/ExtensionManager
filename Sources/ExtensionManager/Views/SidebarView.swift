import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: ExtensionViewModel

    var body: some View {
        List {
            // "All Extensions"
            sidebarRow(
                title: "All Extensions",
                icon: "square.grid.2x2",
                color: .blue,
                count: viewModel.totalCount,
                isSelected: viewModel.selectedCategory == nil
            ) {
                viewModel.selectedCategory = nil
            }

            Divider()

            Section("Categories") {
                ForEach(categoriesWithExtensions) { category in
                    sidebarRow(
                        title: category.rawValue,
                        icon: category.iconName,
                        color: category.color,
                        count: viewModel.categoryCounts[category] ?? 0,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectedCategory = category
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Extensions")
    }

    @ViewBuilder
    private func sidebarRow(
        title: String,
        icon: String,
        color: Color,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label {
                HStack {
                    Text(title)
                        .foregroundStyle(isSelected ? Color.accentColor : .primary)
                    Spacer()
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        )
    }

    private var categoriesWithExtensions: [ExtensionCategory] {
        ExtensionCategory.allCases.filter { category in
            (viewModel.categoryCounts[category] ?? 0) > 0
        }
    }
}
