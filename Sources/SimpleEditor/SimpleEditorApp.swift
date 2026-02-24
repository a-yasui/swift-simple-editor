import SwiftUI
import AppKit

@main
struct SimpleEditorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    NotificationCenter.default.post(name: .newTab, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Open...") {
                    NotificationCenter.default.post(name: .openFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(replacing: .undoRedo) {
                Button("Close Tab") {
                    NotificationCenter.default.post(name: .closeTab, object: nil)
                }
                .keyboardShortcut("w", modifiers: .command)
            }

            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    NotificationCenter.default.post(name: .saveFile, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Save As...") {
                    NotificationCenter.default.post(name: .saveFileAs, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var keyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let optShift: NSEvent.ModifierFlags = [.option, .shift]

            // Opt+Shift+= (charactersIgnoringModifiers keeps Shift, so "=" becomes "+")
            if flags.contains(optShift) && (event.charactersIgnoringModifiers == "+" || event.charactersIgnoringModifiers == "=") {
                WindowToggleManager.shared.toggle()
                return nil
            }
            return event
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        true
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newTab = Notification.Name("newTab")
    static let openFile = Notification.Name("openFile")
    static let saveFile = Notification.Name("saveFile")
    static let saveFileAs = Notification.Name("saveFileAs")
    static let closeTab = Notification.Name("closeTab")
}
