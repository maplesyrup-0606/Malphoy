import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: WindowController?
    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowController = WindowController()
        hotkeyManager = HotkeyManager {
            self.windowController?.toggle()
        }
    }
}

