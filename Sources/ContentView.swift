import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var paneStore: PaneStore
    @State private var hoveredRootPosition: PaneInsertPosition?

    var body: some View {
        VStack(spacing: 16) {
            header
            PaneRootCanvasView(
                node: paneStore.root,
                hoveredPosition: $hoveredRootPosition,
                onInsert: { position in
                    paneStore.insertAtRoot(position)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            Rectangle()
                .stroke(isFocused ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isFocused ? 3 : 1)
        }
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

struct PaneRootCanvasView: View {
    let node: PaneNode

    @Binding var hoveredPosition: PaneInsertPosition?

    let onInsert: (PaneInsertPosition) -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Color.clear
                    .frame(width: 10, height: 10)

                edgeHandle(.top)
                    .frame(maxWidth: .infinity)

                Color.clear
                    .frame(width: 10, height: 10)
            }

            HStack(spacing: 6) {
                edgeHandle(.left)
                    .frame(maxHeight: .infinity)

                PaneNodeView(node: node)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                edgeHandle(.right)
                    .frame(maxHeight: .infinity)
            }

            HStack(spacing: 6) {
                Color.clear
                    .frame(width: 10, height: 10)

                edgeHandle(.bottom)
                    .frame(maxWidth: .infinity)

                Color.clear
                    .frame(width: 10, height: 10)
            }
        }
    }

    @ViewBuilder
    private func edgeHandle(_ position: PaneInsertPosition) -> some View {
        Button {
            onInsert(position)
        } label: {
            ZStack {
                Rectangle()
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
            height: position == .top || position == .bottom ? 10 : 54
        )
        .onHover { isHovered in
            hoveredPosition = isHovered ? position : (hoveredPosition == position ? nil : hoveredPosition)
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
