import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var paneStore: PaneStore

    var body: some View {
        VStack(spacing: 16) {
            header
            PaneNodeView(node: paneStore.root)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 16) {
            Label("Cmd+D 左右分屏", systemImage: "rectangle.split.2x1")
            Label("Shift+Cmd+D 上下分屏", systemImage: "rectangle.split.1x2")
            Label("点 pane 后可继续分", systemImage: "cursorarrow.click.2")
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
