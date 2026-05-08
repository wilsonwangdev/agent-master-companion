import SwiftUI

struct FileViewerView: View {
    let file: AgentFile
    let onBack: () -> Void

    @State private var content: String = ""
    @State private var originalContent: String = ""
    @State private var isEditing = false
    @State private var loadError: String?

    private var isDirty: Bool { content != originalContent }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ZStack {
                if let error = loadError {
                    VStack {
                        Spacer()
                        Text(error).foregroundStyle(.secondary).font(.caption)
                        Spacer()
                    }
                } else if isEditing {
                    editingArea
                } else {
                    readingArea
                }
            }
            .animation(AnimationToken.viewSwitch, value: isEditing)

            if isEditing {
                editingFooter
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .animation(AnimationToken.snappy, value: isEditing)
        .onAppear { load() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            HoverIconButton("chevron.left", help: "Back", action: backAction)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(file.name).font(.headline).lineLimit(1)
                    if isEditing {
                        Text("EDITING")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(
                                Capsule().fill(Color.accentColor.opacity(0.18))
                            )
                            .foregroundStyle(Color.accentColor)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                HStack(spacing: 4) {
                    Label(file.tool.rawValue, systemImage: file.tool.icon)
                    Text("·")
                    Text(file.layer.rawValue)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if loadError == nil {
                if isEditing {
                    Button("Cancel") { cancelEditing() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Button(action: { withAnimation(AnimationToken.snappy) { isEditing = true } }) {
                        Label("Edit", systemImage: "pencil")
                            .frame(minHeight: 24)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var readingArea: some View {
        ScrollView {
            Text(content)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .textSelection(.enabled)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .transition(.opacity)
    }

    private var editingArea: some View {
        TextEditor(text: $content)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 2)
            )
            .transition(.opacity)
    }

    private var editingFooter: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 8) {
                Circle()
                    .fill(isDirty ? Color.orange : Color.green)
                    .frame(width: 6, height: 6)
                    .animation(AnimationToken.fade, value: isDirty)
                Text(isDirty ? "Unsaved changes" : "No changes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!isDirty)
                    .keyboardShortcut("s", modifiers: .command)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func backAction() {
        if isEditing && isDirty {
            let alert = NSAlert()
            alert.messageText = "Discard changes?"
            alert.informativeText = "You have unsaved edits to \(file.name)."
            alert.addButton(withTitle: "Keep Editing")
            alert.addButton(withTitle: "Discard")
            if alert.runModal() == .alertSecondButtonReturn {
                onBack()
            }
        } else {
            onBack()
        }
    }

    private func cancelEditing() {
        if isDirty {
            content = originalContent
        }
        withAnimation(AnimationToken.snappy) { isEditing = false }
    }

    private func load() {
        do {
            let text = try String(contentsOf: file.path, encoding: .utf8)
            content = text
            originalContent = text
        } catch {
            loadError = "Could not read file"
        }
    }

    private func save() {
        do {
            try content.write(to: file.path, atomically: true, encoding: .utf8)
            originalContent = content
            withAnimation(AnimationToken.snappy) { isEditing = false }
        } catch {
            loadError = "Could not save file"
        }
    }
}
