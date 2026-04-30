import Foundation

class FileScanner {
    private static let skipDirs: Set<String> = [
        "node_modules", ".git", "dist", "build", "target",
        ".build", "Pods", "DerivedData", ".next", "vendor"
    ]

    func scanProject(at root: URL) -> [AgentToolGroup] {
        let fm = FileManager.default
        var found: [AgentFile] = []

        for pattern in AgentFileRegistry.safePatterns where pattern.layer != .user {
            let matches = resolveGlob(pattern.glob, root: root, fm: fm)
            for url in matches {
                found.append(AgentFile(
                    tool: pattern.tool,
                    path: url,
                    relativePath: url.path.replacingOccurrences(of: root.path + "/", with: ""),
                    layer: pattern.layer,
                    description: pattern.description
                ))
            }
        }

        // Claude Code stores memory in ~/.claude/projects/{encoded-path}/memory/
        let encodedPath = "-" + root.path.dropFirst().replacingOccurrences(of: "/", with: "-")
        let userMemoryDir = fm.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")
            .appendingPathComponent(encodedPath)
            .appendingPathComponent("memory")
        if let memoryFiles = try? fm.contentsOfDirectory(at: userMemoryDir, includingPropertiesForKeys: nil) {
            for url in memoryFiles where url.pathExtension == "md" {
                found.append(AgentFile(
                    tool: .claudeCode,
                    path: url,
                    relativePath: "~/.claude/projects/\(encodedPath)/memory/\(url.lastPathComponent)",
                    layer: .runtime,
                    description: "Auto-accumulated context"
                ))
            }
        }

        let grouped = Dictionary(grouping: found) { $0.tool }
        return AgentTool.allCases.compactMap { tool in
            guard let files = grouped[tool], !files.isEmpty else { return nil }
            return AgentToolGroup(tool: tool, files: files.sorted { $0.relativePath < $1.relativePath })
        }
    }

    struct UserLevelResult: Identifiable {
        let tool: AgentTool
        let path: String
        let expandedPath: String
        let exists: Bool
        let description: String
        let groupName: String?
        var id: String { expandedPath }
    }

    func scanUserLevel() -> [UserLevelResult] {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path

        var results = AgentFileRegistry.safeUserLevelPaths.map { entry -> UserLevelResult in
            let expanded = entry.path.replacingOccurrences(of: "~", with: home)
            var isDir: ObjCBool = false
            let exists = fm.fileExists(atPath: expanded, isDirectory: &isDir)
            return UserLevelResult(
                tool: entry.tool,
                path: entry.path,
                expandedPath: expanded,
                exists: exists,
                description: entry.description,
                groupName: nil
            )
        }

        // Expand ~/.claude/projects/*/memory/*.md
        let projectsDir = fm.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")
        if let projectDirs = try? fm.contentsOfDirectory(at: projectsDir, includingPropertiesForKeys: nil) {
            for dir in projectDirs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let memoryDir = dir.appendingPathComponent("memory")
                guard let files = try? fm.contentsOfDirectory(at: memoryDir, includingPropertiesForKeys: nil) else { continue }
                let mdFiles = files.filter { $0.pathExtension == "md" }
                if mdFiles.isEmpty { continue }
                let projectName = dir.lastPathComponent
                for file in mdFiles.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                    results.append(UserLevelResult(
                        tool: .claudeCode,
                        path: "~/.claude/projects/\(projectName)/memory/\(file.lastPathComponent)",
                        expandedPath: file.path,
                        exists: true,
                        description: "Memory file",
                        groupName: projectName
                    ))
                }
            }
        }

        return results
    }

    // MARK: - Glob resolution

    private func resolveGlob(_ glob: String, root: URL, fm: FileManager) -> [URL] {
        let parts = glob.split(separator: "/").map(String.init)

        if parts.contains("*") || parts.contains(where: { $0.contains("*") }) {
            return resolveWildcard(parts: parts, base: root, fm: fm)
        }

        let target = root.appendingPathComponent(glob)
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: target.path, isDirectory: &isDir) {
            if isDir.boolValue {
                return contentsOf(directory: target, fm: fm)
            }
            return [target]
        }
        return []
    }

    private func resolveWildcard(parts: [String], base: URL, fm: FileManager) -> [URL] {
        var current = [base]

        for part in parts {
            var next: [URL] = []
            for dir in current {
                if part == "*" {
                    if let items = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                        next.append(contentsOf: items)
                    }
                } else if part.contains("*") {
                    let prefix = String(part.prefix(while: { $0 != "*" }))
                    let suffix = String(part.drop(while: { $0 != "*" }).dropFirst())
                    if let items = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                        for item in items {
                            let name = item.lastPathComponent
                            if name.hasPrefix(prefix) && name.hasSuffix(suffix) {
                                next.append(item)
                            }
                        }
                    }
                } else {
                    let child = dir.appendingPathComponent(part)
                    var isDir: ObjCBool = false
                    if fm.fileExists(atPath: child.path, isDirectory: &isDir) {
                        next.append(child)
                    }
                }
            }
            current = next
        }
        return current
    }

    private func contentsOf(directory: URL, fm: FileManager) -> [URL] {
        (try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
    }
}
