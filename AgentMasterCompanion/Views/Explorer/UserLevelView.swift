import SwiftUI

struct UserLevelView: View {
    @State private var results: [FileScanner.UserLevelResult] = []
    @State private var dynamicGroups: [FileScanner.DynamicDirectoryGroup] = []
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
                    Button(action: refresh) {
                        Image(systemName: "arrow.clockwise")
                            .frame(minWidth: 28, minHeight: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

                Divider()

                userLevelList
            }
            .onAppear(perform: refresh)
        }
    }

    private func refresh() {
        results = scanner.scanUserLevel()
        dynamicGroups = scanner.scanUserDynamicDirectories()
    }

    @ViewBuilder
    private var userLevelList: some View {
        if results.isEmpty && dynamicGroups.isEmpty {
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
                if !results.isEmpty {
                    Section("Global Config") {
                        ForEach(results) { item in
                            userLevelRow(item: item)
                        }
                    }
                }

                ForEach(dynamicGroups) { group in
                    dynamicSection(group: group)
                }
            }
            .listStyle(.sidebar)
        }
    }

    @ViewBuilder
    private func dynamicSection(group: FileScanner.DynamicDirectoryGroup) -> some View {
        let grouped = Dictionary(grouping: group.items) { $0.groupName ?? "" }
        let hasSubgroups = grouped.keys.contains { !$0.isEmpty }

        Section {
            if hasSubgroups {
                let keys = grouped.keys.filter { !$0.isEmpty }.sorted()
                ForEach(keys, id: \.self) { key in
                    DisclosureGroup {
                        ForEach(grouped[key] ?? []) { item in
                            itemButton(item: item)
                        }
                    } label: {
                        Label(readableProjectName(key), systemImage: "folder")
                            .font(.body)
                    }
                }
            } else {
                ForEach(group.items) { item in
                    itemButton(item: item)
                }
            }
        } header: {
            HStack(spacing: 4) {
                Text(group.directory.sectionTitle)
                Text("(\(group.items.count))")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    private func itemButton(item: FileScanner.DynamicDirectoryItem) -> some View {
        Button(action: {
            selectedFile = AgentFile(
                tool: item.directory.tool,
                path: item.path,
                relativePath: relativePath(for: item),
                layer: .user,
                description: item.directory.itemDescription
            )
        }) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: item.directory.icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.displayTitle)
                        .font(.body)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    HStack(spacing: 4) {
                        if let subtitle = item.subtitle {
                            Text(subtitle).lineLimit(1).truncationMode(.middle)
                            Text("·")
                        }
                        Text(Self.relativeFormatter.localizedString(for: item.modifiedAt, relativeTo: Date()))
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .help("\(item.displayTitle)\n\(item.fileName)")
        }
        .buttonStyle(.plain)
    }

    private func relativePath(for item: FileScanner.DynamicDirectoryItem) -> String {
        let base = item.directory.basePath
        if let group = item.groupName {
            return "\(base)/\(group)/\(item.fileName)"
        }
        return "\(base)/\(item.fileName)"
    }

    private func readableProjectName(_ encoded: String) -> String {
        let path = encoded.replacingOccurrences(of: "-", with: "/")
        let components = path.split(separator: "/")
        if components.count >= 2 {
            return components.suffix(2).joined(separator: "/")
        }
        return String(components.last ?? Substring(encoded))
    }

    private func userLevelRow(item: FileScanner.UserLevelResult) -> some View {
        HStack {
            Image(systemName: item.exists ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(item.exists ? .green : .secondary)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.path).font(.body).lineLimit(1).truncationMode(.middle)
                    .help(item.path)
                Text(item.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
