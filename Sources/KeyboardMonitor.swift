import AppKit
import SwiftUI

struct KeyboardMonitorView: NSViewRepresentable {
    @EnvironmentObject private var paneStore: PaneStore

    func makeNSView(context: Context) -> KeyboardMonitorNSView {
        let view = KeyboardMonitorNSView()
        view.handler = handle
        return view
    }

    func updateNSView(_ nsView: KeyboardMonitorNSView, context: Context) {
        nsView.handler = handle
    }

    private func handle(_ event: NSEvent) -> Bool {
        if event.matches(key: "d", modifiers: [.command]) {
            paneStore.splitFocused(.leftRight)
            return true
        }

        if event.matches(key: "d", modifiers: [.command, .shift]) {
            paneStore.splitFocused(.topBottom)
            return true
        }

        if event.matches(key: "r", modifiers: [.command, .option]) {
            paneStore.reset()
            return true
        }

        if event.matches(key: "w", modifiers: [.command]) {
            paneStore.closeFocused()
            return true
        }

        return false
    }
}

final class KeyboardMonitorNSView: NSView {
    var handler: ((NSEvent) -> Bool)?

    private var monitor: Any?

    deinit {
        removeMonitor()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window == nil {
            removeMonitor()
            return
        }

        installMonitorIfNeeded()
    }

    private func installMonitorIfNeeded() {
        guard monitor == nil else {
            return
        }

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let handler = self.handler else {
                return event
            }

            return handler(event) ? nil : event
        }
    }

    private func removeMonitor() {
        guard let monitor else {
            return
        }

        NSEvent.removeMonitor(monitor)
        self.monitor = nil
    }
}

private extension NSEvent {
    func matches(key: String, modifiers: ModifierFlags) -> Bool {
        let normalizedFlags = modifierFlags.intersection(.deviceIndependentFlagsMask)
        return normalizedFlags == modifiers && charactersIgnoringModifiers?.lowercased() == key
    }
}
