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
