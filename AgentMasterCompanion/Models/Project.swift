import Foundation

struct Project: Identifiable, Codable, Hashable {
    let id: UUID
    let path: String
    let name: String
    var lastOpened: Date

    init(url: URL) {
        self.id = UUID()
        self.path = url.path
        self.name = url.lastPathComponent
        self.lastOpened = Date()
    }

    var url: URL { URL(fileURLWithPath: path) }
}
