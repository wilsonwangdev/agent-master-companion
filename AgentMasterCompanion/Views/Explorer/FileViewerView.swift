import SwiftUI

struct FileViewerView: View {
    let file: AgentFile
    let onBack: () -> Void

    @State private var content: String = ""
    @State private var isEditing = false
    @State private var loadError: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 1) {
                    Text(file.name).font(.headline).lineLimit(1)
                    HStack(spacing: 4) {
                        Label(file.tool.rawValue, systemImage: file.tool.icon)
                        Text("·")
                        Text(file.layer.rawValue)
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }

                Spacer()

                if loadError == nil {
                    Toggle(isOn: $isEditing) {
                        Image(systemName: isEditing ? "pencil.circle.fill" : "pencil.circle")
                    }
                    .toggleStyle(.button)
                    .buttonStyle(.plain)
                    .help(isEditing ? "Switch to read-only" : "Enable editing")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if let error = loadError {
                Spacer()
                Text(error).foregroundStyle(.secondary).font(.caption)
                Spacer()
            } else {
                Group {
                    if isEditing {
                        TextEditor(text: $content)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        ScrollView {
                            Text(content)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            if isEditing {
                Divider()
                HStack {
                    Spacer()
                    Button("Save") { save() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
                .padding(8)
            }
        }
        .onAppear { load() }
    }

    private func load() {
        do {
            content = try String(contentsOf: file.path, encoding: .utf8)
        } catch {
            loadError = "Could not read file"
        }
    }

    private func save() {
        do {
            try content.write(to: file.path, atomically: true, encoding: .utf8)
            isEditing = false
        } catch {
            loadError = "Could not save file"
        }
    }
}
