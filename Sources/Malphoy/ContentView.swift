import AppKit

final class ContentView: NSView {
    private var currentTab: Int = 0

    private let appsTab: AppsTab
    private let filesTab: FilesTab
    private let todoTab: TodoTab
    private let calculatorTab: CalculatorTab
    private var tabs: [NSView] = []

    override init(frame: NSRect) {
        appsTab = AppsTab(frame: .zero)
        filesTab = FilesTab(frame: .zero)
        todoTab = TodoTab(frame: .zero)
        calculatorTab = CalculatorTab(frame: .zero)

        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        tabs = [appsTab, filesTab, todoTab, calculatorTab]

        for tab in tabs {
            tab.translatesAutoresizingMaskIntoConstraints = false
            addSubview(tab)
            NSLayoutConstraint.activate([
                tab.topAnchor.constraint(equalTo: topAnchor),
                tab.leadingAnchor.constraint(equalTo: leadingAnchor),
                tab.trailingAnchor.constraint(equalTo: trailingAnchor),
                tab.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        switchTab()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 48: // tab
            currentTab = (currentTab + 1) % 4
            switchTab()
        case 53: // escape
            window?.orderOut(nil)
        default:
            super.keyDown(with: event)
        }
    }

    private func switchTab() {
        tabs.forEach { $0.isHidden = true }
        tabs[currentTab].isHidden = false
        window?.makeFirstResponder(tabs[currentTab])
    }

    func reset() {
        currentTab = 0
        switchTab()
    }
}
