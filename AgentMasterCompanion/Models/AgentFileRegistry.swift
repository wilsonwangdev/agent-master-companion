import Foundation

struct AgentFileRegistry {
    static let patterns: [AgentFilePattern] = [
        // Claude Code — project
        AgentFilePattern(tool: .claudeCode, glob: "CLAUDE.md", layer: .project, description: "Project instructions", isSensitive: false),
        AgentFilePattern(tool: .claudeCode, glob: ".claude/memory/*.md", layer: .runtime, description: "Auto-accumulated context", isSensitive: false),
        AgentFilePattern(tool: .claudeCode, glob: ".claude/plans/*.md", layer: .runtime, description: "Session plans", isSensitive: false),
        AgentFilePattern(tool: .claudeCode, glob: ".claude/settings.json", layer: .project, description: "Project config (credentials)", isSensitive: true),
        AgentFilePattern(tool: .claudeCode, glob: ".claude/settings.local.json", layer: .project, description: "Local override config", isSensitive: true),

        // Codex / Augment
        AgentFilePattern(tool: .codex, glob: "AGENTS.md", layer: .project, description: "Agent instructions", isSensitive: false),
        AgentFilePattern(tool: .codex, glob: "codex.md", layer: .project, description: "Alternative instructions", isSensitive: false),

        // Cursor
        AgentFilePattern(tool: .cursor, glob: ".cursorrules", layer: .project, description: "AI behavior rules", isSensitive: false),
        AgentFilePattern(tool: .cursor, glob: ".cursor/rules/*.md", layer: .project, description: "Modular rules", isSensitive: false),
        AgentFilePattern(tool: .cursor, glob: ".cursor/rules/*.mdc", layer: .project, description: "Modular rules", isSensitive: false),

        // Windsurf
        AgentFilePattern(tool: .windsurf, glob: ".windsurfrules", layer: .project, description: "Cascade AI config", isSensitive: false),

        // GitHub Copilot
        AgentFilePattern(tool: .copilot, glob: ".github/copilot-instructions.md", layer: .project, description: "Instructions (legacy)", isSensitive: false),
        AgentFilePattern(tool: .copilot, glob: ".github/instructions/*.instructions.md", layer: .project, description: "Named instructions", isSensitive: false),

        // Cline
        AgentFilePattern(tool: .cline, glob: ".clinerules", layer: .project, description: "Instructions (legacy)", isSensitive: false),
        AgentFilePattern(tool: .cline, glob: ".clinerules/*.md", layer: .project, description: "Modular instructions", isSensitive: false),

        // Roo Code
        AgentFilePattern(tool: .rooCode, glob: ".roomodes", layer: .project, description: "Custom modes config", isSensitive: false),
        AgentFilePattern(tool: .rooCode, glob: ".roo/rules/*.md", layer: .project, description: "Project rules", isSensitive: false),

        // Aider
        AgentFilePattern(tool: .aider, glob: ".aiderignore", layer: .project, description: "Ignore rules", isSensitive: false),
        AgentFilePattern(tool: .aider, glob: ".aider.conf.yaml", layer: .project, description: "Project config (credentials)", isSensitive: true),

        // Continue.dev
        AgentFilePattern(tool: .continueDev, glob: ".continue/config.*", layer: .project, description: "Project config (credentials)", isSensitive: true),

        // Amazon Q
        AgentFilePattern(tool: .amazonQ, glob: ".amazonq/rules/*.md", layer: .project, description: "Rule files", isSensitive: false),

        // Augment
        AgentFilePattern(tool: .augment, glob: ".augment-guidelines", layer: .project, description: "Guidelines", isSensitive: false),

        // Devin
        AgentFilePattern(tool: .devin, glob: ".devin/rules.md", layer: .project, description: "Project rules", isSensitive: false),
        AgentFilePattern(tool: .devin, glob: ".devin/config.json", layer: .project, description: "Project config (credentials)", isSensitive: true),
    ]

    static var safePatterns: [AgentFilePattern] {
        patterns.filter { !$0.isSensitive }
    }

    static func patterns(for tool: AgentTool) -> [AgentFilePattern] {
        safePatterns.filter { $0.tool == tool }
    }

    static var userLevelPaths: [(tool: AgentTool, path: String, description: String, isSensitive: Bool)] {
        [
            (.claudeCode, "~/.claude/settings.json", "Global settings", true),
            (.claudeCode, "~/.claude/keybindings.json", "Keybindings", true),
            (.claudeCode, "~/.claude/projects/", "Per-project memory", false),
            (.codex, "~/.config/codex/config.toml", "Global config", true),
            (.aider, "~/.aider.conf.yaml", "Global config", true),
            (.aider, "~/.aiderignore", "Global ignore", false),
            (.continueDev, "~/.continue/config.ts", "Global config", true),
            (.devin, "~/.config/devin/config.json", "Global config", true),
        ]
    }

    static var safeUserLevelPaths: [(tool: AgentTool, path: String, description: String, isSensitive: Bool)] {
        userLevelPaths.filter { !$0.isSensitive }
    }
}
