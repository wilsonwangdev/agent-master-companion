import Foundation

class StorageService {
    static let shared = StorageService()

    private let fm = FileManager.default
    private let appDir: URL

    private init() {
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        appDir = support.appendingPathComponent("AgentMasterCompanion")
        try? fm.createDirectory(at: appDir, withIntermediateDirectories: true)
    }

    // MARK: - Recent Projects

    private var projectsFile: URL { appDir.appendingPathComponent("recent-projects.json") }

    func loadProjects() -> [Project] {
        guard let data = try? Data(contentsOf: projectsFile) else { return [] }
        return (try? JSONDecoder().decode([Project].self, from: data)) ?? []
    }

    func saveProjects(_ projects: [Project]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(projects) else { return }
        try? data.write(to: projectsFile)
    }

    func addProject(_ project: Project) {
        var projects = loadProjects()
        projects.removeAll { $0.path == project.path }
        var updated = project
        updated.lastOpened = Date()
        projects.insert(updated, at: 0)
        if projects.count > 10 { projects = Array(projects.prefix(10)) }
        saveProjects(projects)
    }

    func removeProject(_ project: Project) {
        var projects = loadProjects()
        projects.removeAll { $0.id == project.id }
        saveProjects(projects)
    }

    // MARK: - Notes

    private var notesFile: URL { appDir.appendingPathComponent("notes.json") }

    func loadNotes() -> [Note] {
        guard let data = try? Data(contentsOf: notesFile) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Note].self, from: data)) ?? []
    }

    func saveNotes(_ notes: [Note]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(notes) else { return }
        try? data.write(to: notesFile)
    }
}
