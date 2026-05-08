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
            header

            Divider()

            ZStack {
                if vm.isComposing {
                    PromptComposerView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 8)),
                            removal: .opacity.combined(with: .offset(y: 8))
                        ))
                } else if let note = vm.selectedNote {
                    NoteEditorView(vm: vm, note: note)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(x: 20)),
                            removal: .opacity.combined(with: .offset(x: 20))
                        ))
                } else {
                    NoteListView(vm: vm)
                        .transition(.opacity)
                }
            }
            .animation(AnimationToken.viewSwitch, value: vm.isComposing)
            .animation(AnimationToken.viewSwitch, value: vm.selectedNote?.id)
        }
    }

    private var header: some View {
        HStack(spacing: 4) {
            Text("Scratch Pad").font(.headline)
            Spacer()
            HoverIconButton(
                vm.isComposing ? "doc.on.doc.fill" : "doc.on.doc",
                help: "Prompt Composer"
            ) {
                withAnimation(AnimationToken.viewSwitch) { vm.isComposing.toggle() }
            }

            HoverIconButton("plus", help: "New Note") {
                withAnimation(AnimationToken.viewSwitch) { vm.createNote() }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
                Section {
                    ForEach(vm.notes) { note in
                        noteRow(note: note)
                    }
                } header: {
                    HStack(spacing: 4) {
                        Text("Notes")
                        Text("(\(vm.notes.count))").foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }

    private func noteRow(note: Note) -> some View {
        AgentListRow(
            icon: "note.text",
            title: note.title,
            onTap: {
                withAnimation(AnimationToken.viewSwitch) { vm.selectedNote = note }
            }
        ) {
            RelativeTimeText(date: note.updatedAt)
        }
        .contextMenu {
            Button("Delete", role: .destructive) { vm.deleteNote(note) }
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
            HStack(spacing: 8) {
                HoverIconButton("chevron.left", help: "Back to notes") {
                    vm.save()
                    withAnimation(AnimationToken.viewSwitch) { vm.selectedNote = nil }
                }

                TextField("Title", text: $title)
                    .textFieldStyle(.plain)
                    .font(.headline)
                    .onChange(of: title) { _, newValue in
                        DispatchQueue.main.async { vm.updateTitle(newValue) }
                    }

                Spacer()

                HoverIconButton("trash", help: "Delete Note", role: .destructive) {
                    withAnimation(AnimationToken.viewSwitch) { vm.deleteNote(note) }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            TextEditor(text: $content)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(nsColor: .textBackgroundColor))
                .onChange(of: content) { _, newValue in
                    DispatchQueue.main.async { vm.updateContent(newValue) }
                }
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
                VStack(spacing: 8) {
                    Image(systemName: "doc.on.doc")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No notes to compose")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                List {
                    Section {
                        ForEach(vm.notes) { note in
                            composerRow(note: note)
                        }
                    } header: {
                        HStack(spacing: 4) {
                            Text("Select notes to combine")
                                .textCase(nil)
                            Spacer()
                            if !vm.composerSelection.isEmpty {
                                LinkButton(title: "Clear") {
                                    withAnimation(AnimationToken.snappy) {
                                        vm.composerSelection.removeAll()
                                    }
                                }
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            }
                        }
                        .animation(AnimationToken.fade, value: vm.composerSelection.isEmpty)
                    }
                }
                .listStyle(.sidebar)

                Divider()

                HStack(spacing: 8) {
                    Circle()
                        .fill(vm.composerSelection.isEmpty ? Color.secondary.opacity(0.4) : Color.accentColor)
                        .frame(width: 6, height: 6)
                        .animation(AnimationToken.fade, value: vm.composerSelection.isEmpty)
                    Text("\(vm.composerSelection.count) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                        .animation(AnimationToken.snappy, value: vm.composerSelection.count)
                    Spacer()
                    copyButton
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))
            }
        }
    }

    private var copyButton: some View {
        Button(action: performCopy) {
            HStack(spacing: 4) {
                Image(systemName: copied ? "checkmark" : "doc.on.clipboard")
                    .contentTransition(.symbolEffect(.replace))
                Text(copied ? "Copied" : "Copy to Clipboard")
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .tint(copied ? Color.green : Color.accentColor)
        .disabled(vm.composerSelection.isEmpty)
        .animation(AnimationToken.snappy, value: copied)
    }

    private func performCopy() {
        vm.copyComposed()
        withAnimation(AnimationToken.snappy) { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(AnimationToken.snappy) { copied = false }
        }
    }

    private func composerRow(note: Note) -> some View {
        let selected = vm.composerSelection.contains(note.id)
        return HoverableRow(onTap: {
            withAnimation(AnimationToken.snappy) { toggle(note) }
        }) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.accentColor : .secondary)
                    .frame(width: 16)
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 1) {
                    Text(note.title)
                        .font(.body)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(previewText(note.content))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
    }

    private func toggle(_ note: Note) {
        if vm.composerSelection.contains(note.id) {
            vm.composerSelection.remove(note.id)
        } else {
            vm.composerSelection.insert(note.id)
        }
    }

    private func previewText(_ content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Empty note" }
        let firstLine = trimmed.prefix(while: { $0 != "\n" })
        return String(firstLine.prefix(80))
    }
}
