import SwiftUI

enum Tab: String, CaseIterable {
    case explorer = "Explorer"
    case scratchPad = "Scratch Pad"

    var icon: String {
        switch self {
        case .explorer: return "folder.badge.gearshape"
        case .scratchPad: return "note.text"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: Tab = .explorer

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Label(tab.rawValue, systemImage: tab.icon)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Divider()

            Group {
                switch selectedTab {
                case .explorer:
                    ExplorerPlaceholderView()
                case .scratchPad:
                    ScratchPadPlaceholderView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ExplorerPlaceholderView: View {
    var body: some View {
        VStack {
            Image(systemName: "folder.badge.gearshape")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Agent File Explorer")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Coming in Phase 2")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ScratchPadPlaceholderView: View {
    var body: some View {
        VStack {
            Image(systemName: "note.text")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Scratch Pad")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Coming in Phase 3")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
