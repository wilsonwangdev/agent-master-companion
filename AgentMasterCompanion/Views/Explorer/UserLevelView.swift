import SwiftUI

struct UserLevelView: View {
    @State private var results: [FileScanner.UserLevelResult] = []
    @State private var selectedFile: AgentFile?
    private let scanner = FileScanner()

    var body: some View {
        if let file = selectedFile {
            FileViewerView(file: file, onBack: { selectedFile = nil })
        } else {
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

                userLevelList
            }
            .onAppear { results = scanner.scanUserLevel() }
        }
    }

    @ViewBuilder
    private var userLevelList: some View {
        let globalItems = results.filter { $0.groupName == nil }
        let memoryItems = results.filter { $0.groupName != nil }
        let projectGroups = Dictionary(grouping: memoryItems) { $0.groupName! }
        let sortedProjects = projectGroups.keys.sorted()

        if results.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("No user-level agent files found")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            List {
                if !globalItems.isEmpty {
                    Section("Global Config") {
                        ForEach(globalItems) { item in
                            userLevelRow(item: item)
                        }
                    }
                }

                if !sortedProjects.isEmpty {
                    Section("Claude Code Memory") {
                        ForEach(sortedProjects, id: \.self) { project in
                            DisclosureGroup {
                                ForEach(projectGroups[project]!) { item in
                                    fileButton(item: item)
                                }
                            } label: {
                                Label(readableProjectName(project), systemImage: "folder")
                                    .font(.body)
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }

    private func readableProjectName(_ encoded: String) -> String {
        let path = encoded.replacingOccurrences(of: "-", with: "/")
        let components = path.split(separator: "/")
        if components.count >= 2 {
            return components.suffix(2).joined(separator: "/")
        }
        return String(components.last ?? Substring(encoded))
    }

    private func fileButton(item: FileScanner.UserLevelResult) -> some View {
        Button(action: {
            selectedFile = AgentFile(
                tool: item.tool,
                path: URL(fileURLWithPath: item.expandedPath),
                relativePath: item.path,
                layer: .user,
                description: item.description
            )
        }) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text(URL(fileURLWithPath: item.expandedPath).lastPathComponent)
                    .font(.body)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
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
                    .foregroundStyle(.secondary)
            }
        }
    }
}
