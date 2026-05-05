import SwiftUI

@main
struct ITermSplitDemoApp: App {
    @StateObject private var paneStore = PaneStore()

    var body: some Scene {
        Window("iTerm Split Demo", id: "main") {
            ContentView()
                .environmentObject(paneStore)
        }
        .defaultSize(width: 1100, height: 760)
        .commands {
            CommandMenu("Pane") {
                Button("Split Left Right") {
                    paneStore.splitFocused(.leftRight)
                }
                .keyboardShortcut("d", modifiers: [.command])

                Button("Split Top Bottom") {
                    paneStore.splitFocused(.topBottom)
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])

                Divider()

                Button("Reset Layout") {
                    paneStore.reset()
                }
                .keyboardShortcut("r", modifiers: [.command, .option])
            }
        }
    }
}
