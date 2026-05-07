import SwiftUI

struct ProjectExplorerView: View {
    @ObservedObject var vm: ExplorerViewModel
    let project: Project

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button(action: { vm.closeProject() }) {
                    Image(systemName: "chevron.left")
                        .frame(minWidth: 28, minHeight: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 1) {
                    Text(project.name).font(.headline).lineLimit(1)
                    Text(project.path)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(project.path)
                }

                Spacer()

                Button(action: { vm.scan() }) {
                    Image(systemName: "arrow.clockwise")
                        .frame(minWidth: 28, minHeight: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(vm.isScanning)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()

            if vm.isScanning {
                Spacer()
                ProgressView("Scanning...")
                Spacer()
            } else if vm.toolGroups.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "doc.questionmark")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No agent files found")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else if let file = vm.selectedFile {
                FileViewerView(file: file, onBack: { vm.selectedFile = nil })
            } else {
                AgentFileTreeView(groups: vm.toolGroups, onSelect: { vm.selectedFile = $0 })
            }
        }
    }
}

struct AgentFileTreeView: View {
    let groups: [AgentToolGroup]
    let onSelect: (AgentFile) -> Void

    var body: some View {
        List {
            ForEach(groups) { group in
                sectionView(for: group)
            }
        }
        .listStyle(.sidebar)
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
                DisclosureGroup {
                    ForEach(entry.files) { file in
                        fileRow(file: file, showDescription: sharedDesc == nil)
                    }
                } label: {
                    folderLabel(dir: entry.dir, sharedDesc: sharedDesc)
                }
            }
        } header: {
            Label(group.tool.rawValue, systemImage: group.tool.icon)
                .font(.subheadline.weight(.semibold))
        }
    }

    private func folderLabel(dir: String, sharedDesc: String?) -> some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "folder")
                .foregroundStyle(.secondary)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(dir)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(dir)
                if let sharedDesc {
                    Text(sharedDesc)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func fileRow(file: AgentFile, showDescription: Bool) -> some View {
        Button(action: { onSelect(file) }) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(file.name)
                        .font(.body)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(file.relativePath)
                    if showDescription {
                        Text(file.description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private struct DirEntry {
        let dir: String
        let files: [AgentFile]
    }

    private static func groupByParent(_ files: [AgentFile]) -> (root: [AgentFile], dirs: [DirEntry]) {
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
