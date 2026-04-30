import SwiftUI

struct UserLevelView: View {
    @State private var results: [FileScanner.UserLevelResult] = []
    @State private var selectedFile: AgentFile?
    private let scanner = FileScanner()

    var body: some View {
        VStack(spacing: 0) {
            if let file = selectedFile {
                FileViewerView(file: file, onBack: { selectedFile = nil })
            } else {
                HStack {
                    Text("User-Level Agent Config")
                        .font(.headline)
                    Spacer()
                    Button(action: { results = scanner.scanUserLevel() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                List {
                    let grouped = Dictionary(grouping: results) { $0.tool }
                    ForEach(AgentTool.allCases, id: \.self) { tool in
                        if let items = grouped[tool], !items.isEmpty {
                            Section {
                                ForEach(items) { item in
                                    if item.exists && item.expandedPath.hasSuffix(".md") {
                                        Button(action: {
                                            selectedFile = AgentFile(
                                                tool: item.tool,
                                                path: URL(fileURLWithPath: item.expandedPath),
                                                relativePath: item.path,
                                                layer: .user,
                                                description: item.description
                                            )
                                        }) {
                                            userLevelRow(item: item)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        userLevelRow(item: item)
                                    }
                                }
                            } header: {
                                Label(tool.rawValue, systemImage: tool.icon)
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .onAppear { results = scanner.scanUserLevel() }
    }

    private func userLevelRow(item: FileScanner.UserLevelResult) -> some View {
        HStack {
            Image(systemName: item.exists ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(item.exists ? .green : .secondary)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.path).font(.body).lineLimit(1).truncationMode(.middle)
                Text(item.description)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
