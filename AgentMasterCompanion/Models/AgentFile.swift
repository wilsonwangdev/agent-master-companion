import Foundation

struct AgentFile: Identifiable, Hashable {
    let id = UUID()
    let tool: AgentTool
    let path: URL
    let relativePath: String
    let layer: FileLayer
    let description: String
    let modifiedAt: Date?

    var name: String { path.lastPathComponent }
    var isDirectory: Bool {
        (try? path.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: AgentFile, rhs: AgentFile) -> Bool { lhs.id == rhs.id }
}

struct AgentToolGroup: Identifiable {
    let tool: AgentTool
    let files: [AgentFile]
    var id: String { tool.id }
}
