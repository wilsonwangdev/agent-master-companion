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
            HStack(spacing: 6) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Label(tab.rawValue, systemImage: tab.icon)
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                    )
                }
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.08))
            )
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
