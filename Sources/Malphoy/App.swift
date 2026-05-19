import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: WindowController?
    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock and app switcher — this is a background launcher
        NSApp.setActivationPolicy(.accessory)

        windowController = WindowController()
        hotkeyManager = HotkeyManager {
            self.windowController?.toggle()
        }
    }
}

// Entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
