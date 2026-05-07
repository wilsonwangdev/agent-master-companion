import SwiftUI

enum AnimationToken {
    static let tabSwitch = Animation.spring(response: 0.32, dampingFraction: 0.82)
    static let viewSwitch = Animation.spring(response: 0.38, dampingFraction: 0.88)
    static let fade = Animation.easeInOut(duration: 0.18)
    static let snappy = Animation.spring(response: 0.28, dampingFraction: 0.75)
    static let refresh = Animation.easeInOut(duration: 0.55)
}

struct RefreshButton: View {
    let action: () -> Void
    @State private var rotation: Double = 0
    @State private var isHovered = false

    var body: some View {
        Button(action: trigger) {
            Image(systemName: "arrow.clockwise")
                .rotationEffect(.degrees(rotation))
                .frame(minWidth: 28, minHeight: 28)
                .contentShape(Rectangle())
                .foregroundStyle(isHovered ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            withAnimation(AnimationToken.fade) { isHovered = hovered }
        }
        .help("Refresh")
    }

    private func trigger() {
        withAnimation(AnimationToken.refresh) { rotation += 360 }
        action()
    }
}

struct HoverIconButton: View {
    let systemName: String
    let help: String
    let role: ButtonRole?
    let action: () -> Void

    @State private var isHovered = false

    init(_ systemName: String, help: String = "", role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.systemName = systemName
        self.help = help
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            Image(systemName: systemName)
                .frame(minWidth: 28, minHeight: 28)
                .contentShape(Rectangle())
                .foregroundStyle(foregroundColor)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            withAnimation(AnimationToken.fade) { isHovered = hovered }
        }
        .help(help)
    }

    private var foregroundColor: Color {
        if role == .destructive {
            return isHovered ? .red : .primary
        }
        return isHovered ? Color.accentColor : Color.primary
    }
}

struct LinkButton: View {
    let title: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.accentColor.opacity(isHovered ? 1.0 : 0.8))
                .underline(isHovered, color: Color.accentColor)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            withAnimation(AnimationToken.fade) { isHovered = hovered }
        }
    }
}

struct HoverableRow<Content: View>: View {
    let onTap: () -> Void
    @ViewBuilder let content: () -> Content
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isHovered ? Color.primary.opacity(0.06) : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            withAnimation(AnimationToken.fade) { isHovered = hovered }
        }
    }
}

struct RelativeTimeText: View {
    let date: Date

    private static let formatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            Text(Self.formatter.localizedString(for: date, relativeTo: context.date))
        }
    }
}

struct ExpandableFolderRow: View {
    let dir: String
    let sharedDesc: String?
    @Binding var expanded: Bool

    @State private var isHovered = false

    var body: some View {
        Button(action: {
            withAnimation(AnimationToken.snappy) { expanded.toggle() }
        }) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 10, alignment: .center)
                    .rotationEffect(.degrees(expanded ? 90 : 0))
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                    .frame(width: 16, alignment: .center)
                VStack(alignment: .leading, spacing: 1) {
                    Text(dir)
                        .font(.body)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(dir)
                    if let sharedDesc {
                        Text(sharedDesc)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovered ? Color.primary.opacity(0.06) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            withAnimation(AnimationToken.fade) { isHovered = hovered }
        }
    }
}

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

struct TabBarButton: View {
    let tab: Tab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Label(tab.rawValue, systemImage: tab.icon)
                .frame(maxWidth: .infinity, minHeight: 32)
                .padding(.horizontal, 8)
                .foregroundStyle(foreground)
                .background(background)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            withAnimation(AnimationToken.fade) { isHovered = hovered }
        }
    }

    private var foreground: Color {
        if isSelected { return Color.accentColor }
        return isHovered ? Color.primary : Color.secondary
    }

    @ViewBuilder
    private var background: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.15))
                .matchedGeometryEffect(id: "tabHighlight", in: namespace)
        } else if isHovered {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.06))
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: Tab = .explorer
    @Namespace private var tabNamespace

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    TabBarButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        namespace: tabNamespace
                    ) {
                        withAnimation(AnimationToken.tabSwitch) { selectedTab = tab }
                    }
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

            ZStack {
                switch selectedTab {
                case .explorer:
                    ExplorerView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(x: 12)),
                            removal: .opacity.combined(with: .offset(x: -12))
                        ))
                case .userLevel:
                    UserLevelView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(x: 12)),
                            removal: .opacity.combined(with: .offset(x: -12))
                        ))
                case .scratchPad:
                    ScratchPadView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(x: 12)),
                            removal: .opacity.combined(with: .offset(x: -12))
                        ))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 400, height: 500)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
