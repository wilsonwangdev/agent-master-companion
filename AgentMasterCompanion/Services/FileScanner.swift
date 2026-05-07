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

        let home = fm.homeDirectoryForCurrentUser.path
        for linked in AgentFileRegistry.projectLinkedUserDirectories {
            let dirPath = linked.resolvedPath(forProject: root.path, home: home)
            let dirURL = URL(fileURLWithPath: dirPath)
            guard let files = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil) else { continue }
            for url in files where Self.matches(name: url.lastPathComponent, pattern: linked.pattern) {
                found.append(AgentFile(
                    tool: linked.tool,
                    path: url,
                    relativePath: linked.displayPath(forProject: root.path, fileName: url.lastPathComponent),
                    layer: .runtime,
                    description: linked.description
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
        var id: String { expandedPath }
    }

    struct DynamicDirectoryItem: Identifiable {
        let directory: UserDynamicDirectory
        let path: URL
        let displayTitle: String
        let subtitle: String?
        let groupName: String?
        let modifiedAt: Date
        var id: String { path.path }
        var fileName: String { path.lastPathComponent }
    }

    struct DynamicDirectoryGroup: Identifiable {
        let directory: UserDynamicDirectory
        let items: [DynamicDirectoryItem]
        var id: String { directory.id }
    }

    func scanUserDynamicDirectories() -> [DynamicDirectoryGroup] {
        AgentFileRegistry.userDynamicDirectories.compactMap { dir in
            let items = scan(dynamicDirectory: dir)
            return items.isEmpty ? nil : DynamicDirectoryGroup(directory: dir, items: items)
        }
    }

    private func scan(dynamicDirectory dir: UserDynamicDirectory) -> [DynamicDirectoryItem] {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path
        let basePath = dir.basePath.replacingOccurrences(of: "~", with: home)
        let baseURL = URL(fileURLWithPath: basePath)

        switch dir.structure {
        case .flat(let pattern):
            return collectFiles(in: baseURL, pattern: pattern, dir: dir, groupName: nil, fm: fm)
                .sorted { $0.modifiedAt > $1.modifiedAt }

        case .projectGrouped(let subPath, let pattern):
            guard let projectDirs = try? fm.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil) else {
                return []
            }
            var all: [DynamicDirectoryItem] = []
            for projectDir in projectDirs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let targetDir = projectDir.appendingPathComponent(subPath)
                let group = projectDir.lastPathComponent
                all.append(contentsOf: collectFiles(in: targetDir, pattern: pattern, dir: dir, groupName: group, fm: fm))
            }
            return all
        }
    }

    private func collectFiles(
        in directory: URL,
        pattern: String,
        dir: UserDynamicDirectory,
        groupName: String?,
        fm: FileManager
    ) -> [DynamicDirectoryItem] {
        guard let files = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return [] }

        let matched = files.filter { Self.matches(name: $0.lastPathComponent, pattern: pattern) }
        return matched.map { url in
            let mtime = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
                .contentModificationDate ?? .distantPast
            let extracted = dir.extractTitleFromContent ? Self.extractHeadingTitle(from: url) : nil
            let title = extracted ?? url.lastPathComponent
            let subtitle: String? = (extracted != nil) ? url.lastPathComponent : nil
            return DynamicDirectoryItem(
                directory: dir,
                path: url,
                displayTitle: title,
                subtitle: subtitle,
                groupName: groupName,
                modifiedAt: mtime
            )
        }
    }

    private static func matches(name: String, pattern: String) -> Bool {
        // Minimal glob: supports "*.ext" and exact names.
        if pattern == "*" { return true }
        if pattern.hasPrefix("*") {
            return name.hasSuffix(String(pattern.dropFirst()))
        }
        if pattern.hasSuffix("*") {
            return name.hasPrefix(String(pattern.dropLast()))
        }
        return name == pattern
    }

    private static func extractHeadingTitle(from url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        let data = (try? handle.read(upToCount: 4096)) ?? Data()
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            guard trimmed.hasPrefix("# ") else { return nil }
            var title = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            for prefix in ["plan:", "Plan:", "PLAN:"] {
                if title.hasPrefix(prefix) {
                    title = String(title.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                    break
                }
            }
            return title.isEmpty ? nil : title
        }
        return nil
    }

    func scanUserLevel() -> [UserLevelResult] {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path

        return AgentFileRegistry.safeUserLevelPaths.map { entry in
            let expanded = entry.path.replacingOccurrences(of: "~", with: home)
            var isDir: ObjCBool = false
            let exists = fm.fileExists(atPath: expanded, isDirectory: &isDir)
            return UserLevelResult(
                tool: entry.tool,
                path: entry.path,
                expandedPath: expanded,
                exists: exists,
                description: entry.description
            )
        }
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
