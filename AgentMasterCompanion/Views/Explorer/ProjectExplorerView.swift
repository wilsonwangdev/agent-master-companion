import SwiftUI

struct ProjectExplorerView: View {
    @ObservedObject var vm: ExplorerViewModel
    let project: Project

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { vm.closeProject() }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 1) {
                    Text(project.name).font(.headline).lineLimit(1)
                    Text(project.path)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Button(action: { vm.scan() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .disabled(vm.isScanning)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

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
                Section {
                    ForEach(group.files) { file in
                        Button(action: { onSelect(file) }) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 16)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(file.relativePath)
                                        .font(.body)
                                        .lineLimit(1)
                                    Text(file.description)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Label(group.tool.rawValue, systemImage: group.tool.icon)
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .listStyle(.sidebar)
    }
}
