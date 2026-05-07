import Foundation

enum FileLayer: String, Codable {
    case project
    case user
    case runtime
}

struct AgentFilePattern: Identifiable {
    let id = UUID()
    let tool: AgentTool
    let glob: String
    let layer: FileLayer
    let description: String
    let isSensitive: Bool
}

enum AgentTool: String, CaseIterable, Identifiable, Codable {
    case claudeCode = "Claude Code"
    case codex = "Codex"
    case cursor = "Cursor"
    case windsurf = "Windsurf"
    case copilot = "GitHub Copilot"
    case cline = "Cline"
    case rooCode = "Roo Code"
    case aider = "Aider"
    case continueDev = "Continue.dev"
    case amazonQ = "Amazon Q"
    case augment = "Augment"
    case devin = "Devin"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .claudeCode: return "brain.head.profile"
        case .codex: return "terminal"
        case .cursor: return "cursorarrow.rays"
        case .windsurf: return "wind"
        case .copilot: return "airplane"
        case .cline: return "chevron.left.forwardslash.chevron.right"
        case .rooCode: return "hare"
        case .aider: return "wrench.and.screwdriver"
        case .continueDev: return "arrow.right.circle"
        case .amazonQ: return "questionmark.diamond"
        case .augment: return "plus.magnifyingglass"
        case .devin: return "person.crop.rectangle"
        }
    }
}

enum UserDirectoryStructure {
    case flat(pattern: String)
    case projectGrouped(subPath: String, pattern: String)
}

struct UserDynamicDirectory: Identifiable {
    let tool: AgentTool
    let basePath: String
    let structure: UserDirectoryStructure
    let sectionTitle: String
    let itemDescription: String
    let icon: String
    let extractTitleFromContent: Bool

    var id: String { "\(tool.rawValue):\(basePath)" }
}

enum ProjectPathEncoding {
    case dashSeparated
}

struct ProjectLinkedUserDirectory: Identifiable {
    let tool: AgentTool
    let basePathTemplate: String
    let encoding: ProjectPathEncoding
    let pattern: String
    let description: String

    var id: String { "\(tool.rawValue):\(basePathTemplate)" }

    func resolvedPath(forProject projectPath: String, home: String) -> String {
        let encoded: String
        switch encoding {
        case .dashSeparated:
            encoded = "-" + projectPath.dropFirst().replacingOccurrences(of: "/", with: "-")
        }
        return basePathTemplate
            .replacingOccurrences(of: "~", with: home)
            .replacingOccurrences(of: "{project}", with: encoded)
    }

    func displayPath(forProject projectPath: String, fileName: String) -> String {
        let encoded: String
        switch encoding {
        case .dashSeparated:
            encoded = "-" + projectPath.dropFirst().replacingOccurrences(of: "/", with: "-")
        }
        let base = basePathTemplate.replacingOccurrences(of: "{project}", with: encoded)
        return "\(base)/\(fileName)"
    }
}
