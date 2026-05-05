import Foundation

enum PaneSplitAxis {
    case leftRight
    case topBottom
}

struct PaneLeaf: Identifiable {
    let id: UUID
    let index: Int

    var title: String {
        "Pane \(index)"
    }
}

struct PaneSplit: Identifiable {
    let id: UUID
    let axis: PaneSplitAxis
    var first: PaneNode
    var second: PaneNode
}

indirect enum PaneNode: Identifiable {
    case leaf(PaneLeaf)
    case split(PaneSplit)

    var id: UUID {
        switch self {
        case .leaf(let leaf):
            leaf.id
        case .split(let split):
            split.id
        }
    }

    mutating func splitLeaf(targetID: UUID, axis: PaneSplitAxis, newLeaf: PaneLeaf) -> Bool {
        switch self {
        case .leaf(let leaf):
            guard leaf.id == targetID else {
                return false
            }

            self = .split(
                PaneSplit(
                    id: UUID(),
                    axis: axis,
                    first: .leaf(leaf),
                    second: .leaf(newLeaf),
                )
            )
            return true

        case .split(var split):
            if split.first.splitLeaf(targetID: targetID, axis: axis, newLeaf: newLeaf) {
                self = .split(split)
                return true
            }

            if split.second.splitLeaf(targetID: targetID, axis: axis, newLeaf: newLeaf) {
                self = .split(split)
                return true
            }

            return false
        }
    }
}

@MainActor
final class PaneStore: ObservableObject {
    @Published private(set) var root: PaneNode
    @Published private(set) var focusedLeafID: UUID?

    private var nextLeafIndex: Int

    init() {
        let leaf = PaneLeaf(id: UUID(), index: 1)
        root = .leaf(leaf)
        focusedLeafID = leaf.id
        nextLeafIndex = 2
    }

    func focus(_ leafID: UUID) {
        focusedLeafID = leafID
    }

    func reset() {
        let leaf = PaneLeaf(id: UUID(), index: 1)
        root = .leaf(leaf)
        focusedLeafID = leaf.id
        nextLeafIndex = 2
    }

    func splitFocused(_ axis: PaneSplitAxis) {
        guard let focusedLeafID else {
            return
        }

        let newLeaf = PaneLeaf(id: UUID(), index: nextLeafIndex)
        if root.splitLeaf(targetID: focusedLeafID, axis: axis, newLeaf: newLeaf) {
            self.focusedLeafID = newLeaf.id
            nextLeafIndex += 1
        }
    }
}
