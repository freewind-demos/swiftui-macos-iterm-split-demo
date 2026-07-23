import Foundation

enum PaneSplitAxis {
    case leftRight
    case topBottom
}

enum PaneInsertPosition {
    case left
    case right
    case top
    case bottom

    var axis: PaneSplitAxis {
        switch self {
        case .left, .right:
            .leftRight
        case .top, .bottom:
            .topBottom
        }
    }

    var putsNewLeafFirst: Bool {
        switch self {
        case .left, .top:
            true
        case .right, .bottom:
            false
        }
    }
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

    var firstLeafID: UUID {
        switch self {
        case .leaf(let leaf):
            leaf.id
        case .split(let split):
            split.first.firstLeafID
        }
    }

    mutating func insertLeaf(targetID: UUID, position: PaneInsertPosition, newLeaf: PaneLeaf) -> Bool {
        switch self {
        case .leaf(let leaf):
            guard leaf.id == targetID else {
                return false
            }

            let firstNode: PaneNode = position.putsNewLeafFirst ? .leaf(newLeaf) : .leaf(leaf)
            let secondNode: PaneNode = position.putsNewLeafFirst ? .leaf(leaf) : .leaf(newLeaf)
            self = .split(
                PaneSplit(
                    id: UUID(),
                    axis: position.axis,
                    first: firstNode,
                    second: secondNode
                )
            )
            return true

        case .split(var split):
            if split.first.insertLeaf(targetID: targetID, position: position, newLeaf: newLeaf) {
                self = .split(split)
                return true
            }

            if split.second.insertLeaf(targetID: targetID, position: position, newLeaf: newLeaf) {
                self = .split(split)
                return true
            }

            return false
        }
    }

    mutating func removeLeaf(targetID: UUID) -> UUID? {
        switch self {
        case .leaf:
            return nil

        case .split(var split):
            switch split.first {
            case .leaf(let leaf) where leaf.id == targetID:
                self = split.second
                return self.firstLeafID
            default:
                break
            }

            switch split.second {
            case .leaf(let leaf) where leaf.id == targetID:
                self = split.first
                return self.firstLeafID
            default:
                break
            }

            if let nextFocusedLeafID = split.first.removeLeaf(targetID: targetID) {
                self = .split(split)
                return nextFocusedLeafID
            }

            if let nextFocusedLeafID = split.second.removeLeaf(targetID: targetID) {
                self = .split(split)
                return nextFocusedLeafID
            }

            return nil
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
        switch axis {
        case .leftRight:
            insertFocused(at: .right)
        case .topBottom:
            insertFocused(at: .bottom)
        }
    }

    func insertFocused(at position: PaneInsertPosition) {
        guard let focusedLeafID else {
            return
        }

        let newLeaf = PaneLeaf(id: UUID(), index: nextLeafIndex)
        if root.insertLeaf(targetID: focusedLeafID, position: position, newLeaf: newLeaf) {
            self.focusedLeafID = newLeaf.id
            nextLeafIndex += 1
        }
    }

    func insertAtRoot(_ position: PaneInsertPosition) {
        let newLeaf = PaneLeaf(id: UUID(), index: nextLeafIndex)
        let currentRoot = root
        let firstNode: PaneNode = position.putsNewLeafFirst ? .leaf(newLeaf) : currentRoot
        let secondNode: PaneNode = position.putsNewLeafFirst ? currentRoot : .leaf(newLeaf)

        root = .split(
            PaneSplit(
                id: UUID(),
                axis: position.axis,
                first: firstNode,
                second: secondNode
            )
        )
        focusedLeafID = newLeaf.id
        nextLeafIndex += 1
    }

    func closeFocused() {
        guard let focusedLeafID else {
            return
        }

        guard !isRootLeaf(focusedLeafID) else {
            return
        }

        if let nextFocusedLeafID = root.removeLeaf(targetID: focusedLeafID) {
            self.focusedLeafID = nextFocusedLeafID
        }
    }

    private func isRootLeaf(_ leafID: UUID) -> Bool {
        switch root {
        case .leaf(let leaf):
            leaf.id == leafID
        case .split:
            false
        }
    }
}
