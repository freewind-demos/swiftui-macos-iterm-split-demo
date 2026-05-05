import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var paneStore: PaneStore
    @State private var hoveredRootPosition: PaneInsertPosition?

    var body: some View {
        VStack(spacing: 16) {
            header
            PaneNodeView(node: paneStore.root)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    PaneInsertHandlesView(
                        hoveredPosition: $hoveredRootPosition,
                        onInsert: { position in
                            paneStore.insertAtRoot(position)
                        }
                    )
                }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            KeyboardMonitorView()
                .environmentObject(paneStore)
                .frame(width: 0, height: 0)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Label("Cmd+D 左右分屏", systemImage: "rectangle.split.2x1")
            Label("Shift+Cmd+D 上下分屏", systemImage: "rectangle.split.1x2")
            Label("Cmd+W 关闭当前 pane", systemImage: "xmark")
            Label("点 pane 聚焦", systemImage: "cursorarrow.click.2")
            Label("整窗四边可扩一行/列", systemImage: "inset.filled.rectangle.badge.plus")
            Spacer()
            Button("重置布局") {
                paneStore.reset()
            }
        }
        .font(.headline)
    }
}

struct PaneNodeView: View {
    let node: PaneNode

    @EnvironmentObject private var paneStore: PaneStore

    var body: some View {
        switch node {
        case .leaf(let leaf):
            PaneLeafView(leaf: leaf)
        case .split(let split):
            splitView(split)
        }
    }

    @ViewBuilder
    private func splitView(_ split: PaneSplit) -> some View {
        switch split.axis {
        case .leftRight:
            HSplitView {
                PaneNodeView(node: split.first)
                PaneNodeView(node: split.second)
            }
        case .topBottom:
            VSplitView {
                PaneNodeView(node: split.first)
                PaneNodeView(node: split.second)
            }
        }
    }
}

struct PaneLeafView: View {
    let leaf: PaneLeaf

    @EnvironmentObject private var paneStore: PaneStore

    var body: some View {
        let isFocused = paneStore.focusedLeafID == leaf.id

        VStack(alignment: .leading, spacing: 12) {
            Text(leaf.title)
                .font(.title2.weight(.semibold))

            Text("点击聚焦，再按快捷键继续分屏")
                .foregroundStyle(.secondary)

            Spacer()

            Label(isFocused ? "当前 pane" : "可点击聚焦", systemImage: isFocused ? "scope" : "cursorarrow.click")
                .font(.headline)
                .foregroundStyle(isFocused ? .primary : .secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(backgroundColor.opacity(0.35))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(isFocused ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isFocused ? 3 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .contentShape(Rectangle())
        .onTapGesture {
            paneStore.focus(leaf.id)
        }
    }

    private var backgroundColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .pink, .mint, .cyan]
        return colors[(leaf.index - 1) % colors.count]
    }
}

struct PaneInsertHandlesView: View {
    @Binding var hoveredPosition: PaneInsertPosition?

    let onInsert: (PaneInsertPosition) -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                edgeHandle(.top)
                Spacer(minLength: 0)
                edgeHandle(.bottom)
            }

            HStack(spacing: 0) {
                edgeHandle(.left)
                Spacer(minLength: 0)
                edgeHandle(.right)
            }
        }
        .padding(6)
    }

    @ViewBuilder
    private func edgeHandle(_ position: PaneInsertPosition) -> some View {
        Button {
            onInsert(position)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 999)
                    .fill(fillColor(position))

                if hoveredPosition == position {
                    Image(systemName: symbolName(position))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .help(helpText(position))
        .frame(
            width: position == .left || position == .right ? 10 : 54,
            height: position == .top || position == .bottom ? 10 : 54,
        )
        .frame(
            maxWidth: position == .top || position == .bottom ? .infinity : nil,
            maxHeight: position == .left || position == .right ? .infinity : nil,
            alignment: alignment(position),
        )
        .onHover { isHovered in
            hoveredPosition = isHovered ? position : (hoveredPosition == position ? nil : hoveredPosition)
        }
    }

    private func alignment(_ position: PaneInsertPosition) -> Alignment {
        switch position {
        case .left:
            .leading
        case .right:
            .trailing
        case .top:
            .top
        case .bottom:
            .bottom
        }
    }

    private func fillColor(_ position: PaneInsertPosition) -> Color {
        hoveredPosition == position ? .accentColor : .black.opacity(0.16)
    }

    private func symbolName(_ position: PaneInsertPosition) -> String {
        switch position {
        case .left, .right:
            "rectangle.split.2x1"
        case .top, .bottom:
            "rectangle.split.1x2"
        }
    }

    private func helpText(_ position: PaneInsertPosition) -> String {
        switch position {
        case .left:
            "在左侧加一列"
        case .right:
            "在右侧加一列"
        case .top:
            "在上方加一行"
        case .bottom:
            "在下方加一行"
        }
    }
}
