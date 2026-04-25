import SwiftUI

struct UserLevelView: View {
    @State private var results: [FileScanner.UserLevelResult] = []
    private let scanner = FileScanner()

    var body: some View {
        VStack(spacing: 0) {
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
                                HStack {
                                    Image(systemName: item.exists ? "checkmark.circle.fill" : "circle.dashed")
                                        .foregroundStyle(item.exists ? .green : .secondary)
                                        .frame(width: 16)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.path).font(.body)
                                        Text(item.description)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
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
        .onAppear { results = scanner.scanUserLevel() }
    }
}
