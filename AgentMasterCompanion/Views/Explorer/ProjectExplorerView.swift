import SwiftUI

struct ProjectExplorerView: View {
    @ObservedObject var vm: ExplorerViewModel
    let project: Project

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                HoverIconButton("chevron.left", help: "Back to projects") {
                    withAnimation(AnimationToken.viewSwitch) { vm.closeProject() }
                }

                Text(project.name)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(project.path)

                Spacer()

                RefreshButton { vm.scan() }
                    .disabled(vm.isScanning)
                    .opacity(vm.isScanning ? 0.4 : 1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()

            ZStack {
                if vm.isScanning {
                    VStack { Spacer(); ProgressView("Scanning..."); Spacer() }
                        .transition(.opacity)
                } else if vm.toolGroups.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "doc.questionmark")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No agent files found")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .transition(.opacity)
                } else if let file = vm.selectedFile {
                    FileViewerView(file: file, onBack: {
                        withAnimation(AnimationToken.viewSwitch) { vm.selectedFile = nil }
                    })
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 20)),
                        removal: .opacity.combined(with: .offset(x: 20))
                    ))
                } else {
                    AgentFileTreeView(groups: vm.toolGroups, onSelect: { file in
                        withAnimation(AnimationToken.viewSwitch) { vm.selectedFile = file }
                    })
                    .transition(.opacity)
                }
            }
        }
    }
}

struct AgentFileTreeView: View {
    let groups: [AgentToolGroup]
    let onSelect: (AgentFile) -> Void

    @State private var expanded: Set<String> = []

    var body: some View {
        List {
            ForEach(groups) { group in
                sectionView(for: group)
            }
        }
        .listStyle(.sidebar)
        .onAppear {
            if expanded.isEmpty {
                expanded = Set(groups.flatMap { g in Self.groupByParent(g.files).dirs.map { "\(g.tool.rawValue)::\($0.dir)" } })
            }
        }
    }

    @ViewBuilder
    private func sectionView(for group: AgentToolGroup) -> some View {
        let (rootFiles, dirGroups) = Self.groupByParent(group.files)

        Section {
            ForEach(rootFiles) { file in
                fileRow(file: file, showDescription: true)
            }
            ForEach(dirGroups, id: \.dir) { entry in
                let sharedDesc = Self.commonValue(entry.files.map(\.description))
                let key = "\(group.tool.rawValue)::\(entry.dir)"
                ExpandableFolderRow(
                    dir: entry.dir,
                    sharedDesc: sharedDesc,
                    expanded: Binding(
                        get: { expanded.contains(key) },
                        set: { isOn in
                            if isOn { expanded.insert(key) } else { expanded.remove(key) }
                        }
                    )
                )
                if expanded.contains(key) {
                    ForEach(entry.files) { file in
                        fileRow(file: file, showDescription: sharedDesc == nil, indented: true)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                    }
                }
            }
        } header: {
            Label(group.tool.rawValue, systemImage: group.tool.icon)
                .font(.subheadline.weight(.semibold))
        }
    }

    private func fileRow(file: AgentFile, showDescription: Bool, indented: Bool = false) -> some View {
        Group {
            if showDescription {
                AgentListRow(
                    icon: "doc.text",
                    title: file.name,
                    subtitle: file.description,
                    tooltip: file.relativePath,
                    indented: indented,
                    onTap: { onSelect(file) }
                )
            } else {
                AgentListRow(
                    icon: "doc.text",
                    title: file.name,
                    tooltip: file.relativePath,
                    indented: indented,
                    onTap: { onSelect(file) }
                )
            }
        }
    }

    struct DirEntry {
        let dir: String
        let files: [AgentFile]
    }

    static func groupByParent(_ files: [AgentFile]) -> (root: [AgentFile], dirs: [DirEntry]) {
        var root: [AgentFile] = []
        var buckets: [String: [AgentFile]] = [:]
        var order: [String] = []

        for file in files {
            if let slash = file.relativePath.lastIndex(of: "/") {
                let dir = String(file.relativePath[..<slash])
                if buckets[dir] == nil { order.append(dir) }
                buckets[dir, default: []].append(file)
            } else {
                root.append(file)
            }
        }
        let dirs = order.map { DirEntry(dir: $0, files: buckets[$0] ?? []) }
        return (root, dirs)
    }

    private static func commonValue(_ values: [String]) -> String? {
        guard values.count > 1, let first = values.first else { return nil }
        return values.allSatisfy { $0 == first } ? first : nil
    }
}
