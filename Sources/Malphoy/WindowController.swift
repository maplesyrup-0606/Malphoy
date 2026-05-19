import AppKit

final class WindowController {
    private var panel: NSPanel!
    private var contentView: ContentView!

    init() {
        let width: CGFloat = 680
        let height: CGFloat = 450

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovable = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.appearance = NSAppearance(named: .vibrantDark)
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 14
        visualEffect.layer?.masksToBounds = true

        contentView = ContentView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        contentView.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
        ])

        panel.contentView = visualEffect
    }

    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        center()
        contentView.reset()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func center() {
        guard let screen = NSScreen.main else { return }
        let x = (screen.frame.width - panel.frame.width) / 2
        let y = (screen.frame.height - panel.frame.height) / 2 + 60
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
