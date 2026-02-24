import AppKit

final class WindowToggleManager {
    static let shared = WindowToggleManager()

    private var savedFrame: NSRect?
    private(set) var isOffScreen = false

    private init() {}

    func toggle() {
        guard let window = NSApplication.shared.mainWindow ?? NSApplication.shared.windows.first(where: { $0.isVisible }) else {
            return
        }

        if isOffScreen {
            restore(window: window)
        } else {
            stash(window: window)
        }
    }

    private func stash(window: NSWindow) {
        savedFrame = window.frame
        window.setFrameOrigin(NSPoint(x: -10000, y: -10000))
        isOffScreen = true
    }

    private func restore(window: NSWindow) {
        if let frame = savedFrame {
            window.setFrame(frame, display: true, animate: false)
        }
        isOffScreen = false
    }
}
