import SwiftUI

enum Tab: String, CaseIterable {
    case explorer = "Project"
    case userLevel = "User"
    case scratchPad = "Scratch Pad"

    var icon: String {
        switch self {
        case .explorer: return "folder.badge.gearshape"
        case .userLevel: return "person.crop.circle"
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
                    ExplorerView()
                case .userLevel:
                    UserLevelView()
                case .scratchPad:
                    ScratchPadView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
