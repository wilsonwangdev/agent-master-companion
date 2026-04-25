import SwiftUI

class ScratchPadViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var selectedNote: Note?
    @Published var isComposing = false
    @Published var composerSelection: Set<UUID> = []

    private let storage = StorageService.shared
    private var autoSaveTimer: Timer?

    init() {
        notes = storage.loadNotes()
    }

    func createNote() {
        let note = Note()
        notes.insert(note, at: 0)
        selectedNote = note
        save()
    }

    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        if selectedNote?.id == note.id { selectedNote = nil }
        composerSelection.remove(note.id)
        save()
    }

    func updateContent(_ content: String) {
        guard let idx = notes.firstIndex(where: { $0.id == selectedNote?.id }) else { return }
        notes[idx].content = content
        notes[idx].updatedAt = Date()
        if notes[idx].title == "Untitled" && !content.isEmpty {
            let firstLine = content.prefix(while: { $0 != "\n" })
            if !firstLine.isEmpty {
                notes[idx].title = String(firstLine.prefix(40))
            }
        }
        selectedNote = notes[idx]
        scheduleAutoSave()
    }

    func updateTitle(_ title: String) {
        guard let idx = notes.firstIndex(where: { $0.id == selectedNote?.id }) else { return }
        notes[idx].title = title
        notes[idx].updatedAt = Date()
        selectedNote = notes[idx]
        scheduleAutoSave()
    }

    func composedText() -> String {
        notes.filter { composerSelection.contains($0.id) }
            .map { $0.content }
            .joined(separator: "\n\n---\n\n")
    }

    func copyComposed() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(composedText(), forType: .string)
    }

    func save() {
        storage.saveNotes(notes)
    }

    private func scheduleAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.save()
        }
    }
}

struct ScratchPadView: View {
    @StateObject private var vm = ScratchPadViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Scratch Pad").font(.headline)
                Spacer()
                Button(action: { vm.isComposing.toggle() }) {
                    Image(systemName: vm.isComposing ? "doc.on.doc.fill" : "doc.on.doc")
                }
                .buttonStyle(.plain)
                .help("Prompt Composer")

                Button(action: { vm.createNote() }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if vm.isComposing {
                PromptComposerView(vm: vm)
            } else if let note = vm.selectedNote {
                NoteEditorView(vm: vm, note: note)
            } else {
                NoteListView(vm: vm)
            }
        }
    }
}

struct NoteListView: View {
    @ObservedObject var vm: ScratchPadViewModel

    var body: some View {
        if vm.notes.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "note.text")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("No notes yet")
                    .foregroundStyle(.secondary)
                Button("Create Note") { vm.createNote() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            List {
                ForEach(vm.notes) { note in
                    Button(action: { vm.selectedNote = note }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.title).font(.body).lineLimit(1)
                            Text(note.updatedAt, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Delete", role: .destructive) { vm.deleteNote(note) }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

struct NoteEditorView: View {
    @ObservedObject var vm: ScratchPadViewModel
    let note: Note
    @State private var content: String = ""
    @State private var title: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { vm.save(); vm.selectedNote = nil }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                TextField("Title", text: $title)
                    .textFieldStyle(.plain)
                    .font(.headline)
                    .onChange(of: title) { vm.updateTitle($0) }

                Spacer()

                Button(role: .destructive, action: { vm.deleteNote(note) }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Divider()

            TextEditor(text: $content)
                .font(.system(.body, design: .monospaced))
                .onChange(of: content) { vm.updateContent($0) }
        }
        .onAppear {
            content = note.content
            title = note.title
        }
    }
}

struct PromptComposerView: View {
    @ObservedObject var vm: ScratchPadViewModel
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            if vm.notes.isEmpty {
                Spacer()
                Text("No notes to compose").foregroundStyle(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(vm.notes) { note in
                        HStack {
                            Image(systemName: vm.composerSelection.contains(note.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(vm.composerSelection.contains(note.id) ? .blue : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(note.title).font(.body).lineLimit(1)
                                Text(note.content.prefix(60))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if vm.composerSelection.contains(note.id) {
                                vm.composerSelection.remove(note.id)
                            } else {
                                vm.composerSelection.insert(note.id)
                            }
                        }
                    }
                }
                .listStyle(.plain)

                Divider()

                HStack {
                    Text("\(vm.composerSelection.count) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(copied ? "Copied!" : "Copy to Clipboard") {
                        vm.copyComposed()
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(vm.composerSelection.isEmpty)
                }
                .padding(8)
            }
        }
    }
}
