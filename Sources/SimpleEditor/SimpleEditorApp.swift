import SwiftUI
import AppKit

@main
struct SimpleEditorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var keyMonitor: Any?
    private(set) var panel: NSPanel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        setupPanel()
        setupMainMenu()

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

        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Panel Setup

    private func setupPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Simple Editor"
        panel.becomesKeyOnlyIfNeeded = false
        panel.contentView = NSHostingView(rootView: ContentView())
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    // MARK: - Menu Setup

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Simple Editor", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Simple Editor", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu

        // File menu
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "New Tab", action: #selector(menuNewTab), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "Open...", action: #selector(menuOpenFile), keyEquivalent: "o")
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Close Tab", action: #selector(menuCloseTab), keyEquivalent: "w")
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Save", action: #selector(menuSaveFile), keyEquivalent: "s")
        let saveAllItem = NSMenuItem(title: "Save All to Directory...", action: #selector(menuSaveAllToDirectory), keyEquivalent: "s")
        saveAllItem.keyEquivalentModifierMask = [.command, .shift]
        fileMenu.addItem(saveAllItem)
        fileMenuItem.submenu = fileMenu

        // Edit menu
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenu.addItem(.separator())
        let prevTabItem = NSMenuItem(title: "Previous Tab", action: #selector(menuPreviousTab), keyEquivalent: "[")
        prevTabItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(prevTabItem)
        let nextTabItem = NSMenuItem(title: "Next Tab", action: #selector(menuNextTab), keyEquivalent: "]")
        nextTabItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(nextTabItem)
        editMenuItem.submenu = editMenu

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Menu Actions

    @objc private func menuNewTab() {
        NotificationCenter.default.post(name: .newTab, object: nil)
    }

    @objc private func menuOpenFile() {
        NotificationCenter.default.post(name: .openFile, object: nil)
    }

    @objc private func menuSaveFile() {
        NotificationCenter.default.post(name: .saveFile, object: nil)
    }

    @objc private func menuSaveAllToDirectory() {
        NotificationCenter.default.post(name: .saveAllToDirectory, object: nil)
    }

    @objc private func menuCloseTab() {
        NotificationCenter.default.post(name: .closeTab, object: nil)
    }

    @objc private func menuPreviousTab() {
        NotificationCenter.default.post(name: .previousTab, object: nil)
    }

    @objc private func menuNextTab() {
        NotificationCenter.default.post(name: .nextTab, object: nil)
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
