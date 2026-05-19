import AppKit

final class ContentView: NSView {
    private var currentTab: Int = 0

    private let appsTab: AppsTab
    private let filesTab: FilesTab
    private let todoTab: TodoTab
    private let calculatorTab: CalculatorTab
    private var tabs: [NSView] = []

    private var tabLabels: [NSTextField] = []

    override init(frame: NSRect) {
        appsTab = AppsTab(frame: .zero)
        filesTab = FilesTab(frame: .zero)
        todoTab = TodoTab(frame: .zero)
        calculatorTab = CalculatorTab(frame: .zero)

        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        tabs = [appsTab, filesTab, todoTab, calculatorTab]

        let separator = NSView()
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.08).cgColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        let tabBar = buildTabBar()
        addSubview(tabBar)

        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            tabBar.heightAnchor.constraint(equalToConstant: 36),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: tabBar.topAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
        ])

        for tab in tabs {
            tab.translatesAutoresizingMaskIntoConstraints = false
            addSubview(tab)
            NSLayoutConstraint.activate([
                tab.topAnchor.constraint(equalTo: topAnchor),
                tab.leadingAnchor.constraint(equalTo: leadingAnchor),
                tab.trailingAnchor.constraint(equalTo: trailingAnchor),
                tab.bottomAnchor.constraint(equalTo: separator.topAnchor),
            ])
        }

        let nextTab: () -> Void = { [weak self] in
            guard let self else { return }
            self.currentTab = (self.currentTab + 1) % 4
            self.switchTab()
        }
        appsTab.onTabKey = nextTab
        filesTab.onTabKey = nextTab
        todoTab.onTabKey = nextTab
        calculatorTab.onTabKey = nextTab

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

    private func buildTabBar() -> NSStackView {
        let names = ["Apps", "Files", "Todo", "Calculator"]
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false

        for name in names {
            let label = NSTextField(labelWithString: name)
            label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            label.alignment = .center
            tabLabels.append(label)
            stack.addArrangedSubview(label)
        }

        return stack
    }

    private func switchTab() {
        tabs.forEach { $0.isHidden = true }
        tabs[currentTab].isHidden = false
        updateTabBar()
        focusCurrentTabInput()
    }

    private func updateTabBar() {
        for (i, label) in tabLabels.enumerated() {
            label.textColor = i == currentTab
                ? NSColor.white.withAlphaComponent(0.85)
                : NSColor.white.withAlphaComponent(0.25)
        }
    }

    private func focusCurrentTabInput() {
        switch currentTab {
        case 0: appsTab.focusInput()
        case 1: filesTab.focusInput()
        case 2: todoTab.focusInput()
        case 3: calculatorTab.focusInput()
        default: break
        }
    }

    func reset() {
        currentTab = 0
        todoTab.reload()
        switchTab()
    }
}
