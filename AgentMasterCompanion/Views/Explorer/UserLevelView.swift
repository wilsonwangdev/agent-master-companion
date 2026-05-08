import SwiftUI

struct UserLevelView: View {
    @State private var results: [FileScanner.UserLevelResult] = []
    @State private var dynamicGroups: [FileScanner.DynamicDirectoryGroup] = []
    @State private var selectedFile: AgentFile?
    @State private var expanded: Set<String> = []
    private let scanner = FileScanner()

    var body: some View {
        ZStack {
            if let file = selectedFile {
                FileViewerView(file: file, onBack: {
                    withAnimation(AnimationToken.viewSwitch) { selectedFile = nil }
                })
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(x: 20)),
                    removal: .opacity.combined(with: .offset(x: 20))
                ))
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text("User-Level Agent Config")
                            .font(.headline)
                        Spacer()
                        RefreshButton(action: refresh)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    Divider()

                    userLevelList
                }
                .transition(.opacity)
            }
        }
        .onAppear(perform: refresh)
    }

    private func refresh() {
        withAnimation(AnimationToken.snappy) {
            results = scanner.scanUserLevel()
            dynamicGroups = scanner.scanUserDynamicDirectories()
        }
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
                    let compoundKey = "\(group.id)::\(key)"
                    ExpandableFolderRow(
                        dir: readableProjectName(key),
                        sharedDesc: nil,
                        expanded: Binding(
                            get: { expanded.contains(compoundKey) },
                            set: { isOn in
                                if isOn { expanded.insert(compoundKey) } else { expanded.remove(compoundKey) }
                            }
                        )
                    )
                    if expanded.contains(compoundKey) {
                        ForEach(grouped[key] ?? []) { item in
                            itemButton(item: item, indented: true)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity.combined(with: .move(edge: .top))
                                ))
                        }
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

    private func itemButton(item: FileScanner.DynamicDirectoryItem, indented: Bool = false) -> some View {
        AgentListRow(
            icon: item.directory.icon,
            title: item.displayTitle,
            tooltip: "\(item.displayTitle)\n\(item.fileName)",
            indented: indented,
            onTap: {
                withAnimation(AnimationToken.viewSwitch) {
                    selectedFile = AgentFile(
                        tool: item.directory.tool,
                        path: item.path,
                        relativePath: relativePath(for: item),
                        layer: .user,
                        description: item.directory.itemDescription,
                        modifiedAt: item.modifiedAt
                    )
                }
            }
        ) {
            HStack(spacing: 4) {
                if let subtitle = item.subtitle {
                    Text(subtitle).lineLimit(1).truncationMode(.middle)
                    Text("·")
                }
                RelativeTimeText(date: item.modifiedAt)
            }
        }
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
