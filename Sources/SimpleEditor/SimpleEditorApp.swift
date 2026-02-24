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

                Divider()

                Button("Previous Tab") {
                    NotificationCenter.default.post(name: .previousTab, object: nil)
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])

                Button("Next Tab") {
                    NotificationCenter.default.post(name: .nextTab, object: nil)
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    NotificationCenter.default.post(name: .saveFile, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Save All to Directory...") {
                    NotificationCenter.default.post(name: .saveAllToDirectory, object: nil)
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
    static let saveAllToDirectory = Notification.Name("saveAllToDirectory")
    static let closeTab = Notification.Name("closeTab")
    static let previousTab = Notification.Name("previousTab")
    static let nextTab = Notification.Name("nextTab")
}
