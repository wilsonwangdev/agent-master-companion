import SwiftUI

class ExplorerViewModel: ObservableObject {
    @Published var currentProject: Project?
    @Published var toolGroups: [AgentToolGroup] = []
    @Published var recentProjects: [Project] = []
    @Published var selectedFile: AgentFile?
    @Published var isScanning = false

    private let scanner = FileScanner()
    private let storage = StorageService.shared

    init() {
        recentProjects = storage.loadProjects()
    }

    func openProject(url: URL) {
        let project = Project(url: url)
        currentProject = project
        storage.addProject(project)
        recentProjects = storage.loadProjects()
        scan()
    }

    func openRecent(_ project: Project) {
        var p = project
        p.lastOpened = Date()
        currentProject = p
        storage.addProject(p)
        recentProjects = storage.loadProjects()
        scan()
    }

    func closeProject() {
        currentProject = nil
        toolGroups = []
        selectedFile = nil
    }

    func removeRecent(_ project: Project) {
        storage.removeProject(project)
        recentProjects = storage.loadProjects()
    }

    func scan() {
        guard let project = currentProject else { return }
        isScanning = true
        selectedFile = nil
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let groups = self.scanner.scanProject(at: project.url)
            DispatchQueue.main.async {
                self.toolGroups = groups
                self.isScanning = false
            }
        }
    }

    func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a project folder to scan for agent files"
        if panel.runModal() == .OK, let url = panel.url {
            openProject(url: url)
        }
    }
}

struct ExplorerView: View {
    @StateObject private var vm = ExplorerViewModel()

    var body: some View {
        ZStack {
            if let project = vm.currentProject {
                ProjectExplorerView(vm: vm, project: project)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 20)),
                        removal: .opacity.combined(with: .offset(x: 20))
                    ))
            } else {
                ProjectPickerView(vm: vm)
                    .transition(.opacity)
            }
        }
        .animation(AnimationToken.viewSwitch, value: vm.currentProject?.id)
    }
}

struct ProjectPickerView: View {
    @ObservedObject var vm: ExplorerViewModel

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Button(action: { vm.pickFolder() }) {
                Label("Open Project Folder", systemImage: "folder.badge.plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if !vm.recentProjects.isEmpty {
                Divider().padding(.horizontal, 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent Projects")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    List {
                        ForEach(vm.recentProjects) { project in
                            HoverableRow(onTap: {
                                withAnimation(AnimationToken.viewSwitch) { vm.openRecent(project) }
                            }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(project.name).font(.body)
                                    Text(project.path)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .help(project.path)
                                }
                            }
                            .contextMenu {
                                Button("Remove from Recent", role: .destructive) {
                                    vm.removeRecent(project)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
