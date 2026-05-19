import AppKit

final class AppsTab: NSView {
    private var apps: [URL] = []
    private var filtered: [URL] = []
    private var selectedIndex: Int = 0

    var onTabKey: (() -> Void)?

    private let searchField: NSTextField
    private let tableView: NSTableView
    private let scrollView: NSScrollView

    override init(frame: NSRect) {
        searchField = NSTextField(frame: .zero)
        tableView = NSTableView(frame: .zero)
        scrollView = NSScrollView(frame: .zero)

        super.init(frame: frame)
        wantsLayer = true
        setupSearchField()
        setupTableView()
        loadApps()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupSearchField() {
        searchField.placeholderString = "Search apps..."
        searchField.isBezeled = false
        searchField.drawsBackground = false
        searchField.font = NSFont.systemFont(ofSize: 18, weight: .light)
        searchField.textColor = .white
        searchField.focusRingType = .none
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.delegate = self

        addSubview(searchField)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            searchField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            searchField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            searchField.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func setupTableView() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("app"))
        column.isEditable = false
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.rowHeight = 44
        tableView.intercellSpacing = NSSize(width: 0, height: 4)
        tableView.selectionHighlightStyle = .none
        tableView.delegate = self
        tableView.dataSource = self

        scrollView.documentView = tableView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }

    // MARK: - Logic (your territory)

    func loadApps() {
        let fm = FileManager.default
        let dirs: [URL] = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
        ]

        var found: [URL] = []
        for dir in dirs {
            guard let enumerator = fm.enumerator(at: dir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else { continue }
            for case let url as URL in enumerator {
                if url.pathExtension == "app" {
                    found.append(url)
                    enumerator.skipDescendants()
                }
            }
        }

        apps = found
        filtered = found
        tableView.reloadData()
    }

    private func filterApps(query: String) {
        guard !query.isEmpty else {
            filtered = apps
            tableView.reloadData()
            resetSelection()
            return
        }

        filtered = apps
            .compactMap { url -> (URL, Int)? in
                let name = url.deletingPathExtension().lastPathComponent
                let (match, score) = fuzzyMatch(query: query, target: name)
                return match ? (url, score) : nil
            }
            .sorted { $0.1 > $1.1 }
            .prefix(20)
            .map { $0.0 }

        tableView.reloadData()
        resetSelection()
    }

    private func launchSelected() {
        guard !filtered.isEmpty else { return }
        NSWorkspace.shared.openApplication(at: filtered[selectedIndex], configuration: .init(), completionHandler: nil)
    }

    // MARK: - Selection

    private func resetSelection() {
        selectedIndex = 0
        tableView.reloadData()
        tableView.scrollRowToVisible(0)
    }

    private func moveSelection(by delta: Int) {
        guard !filtered.isEmpty else { return }
        selectedIndex = max(0, min(filtered.count - 1, selectedIndex + delta))
        tableView.reloadData()
        tableView.scrollRowToVisible(selectedIndex)
    }

    // MARK: - Focus

    func focusInput() {
        window?.makeFirstResponder(searchField)
    }

    // MARK: - Keyboard

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 125: moveSelection(by: 1)  // down arrow
        case 126: moveSelection(by: -1) // up arrow
        case 36:  launchSelected()      // enter
        default:  super.keyDown(with: event)
        }
    }
}

// MARK: - NSTextFieldDelegate

extension AppsTab: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        filterApps(query: searchField.stringValue)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.insertTab(_:)):
            onTabKey?()
            return true
        case #selector(NSResponder.cancelOperation(_:)):
            window?.orderOut(nil)
            return true
        case #selector(NSResponder.moveDown(_:)):
            moveSelection(by: 1)
            return true
        case #selector(NSResponder.moveUp(_:)):
            moveSelection(by: -1)
            return true
        case #selector(NSResponder.insertNewline(_:)):
            launchSelected()
            return true
        default:
            return false
        }
    }
}

// MARK: - NSTableViewDataSource

extension AppsTab: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        filtered.count
    }
}

// MARK: - NSTableViewDelegate

extension AppsTab: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let app = filtered[row]
        let name = app.deletingPathExtension().lastPathComponent

        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 8

        if row == selectedIndex {
            container.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.1).cgColor
        }

        let icon = NSImageView(frame: NSRect(x: 10, y: 8, width: 28, height: 28))
        icon.image = NSWorkspace.shared.icon(forFile: app.path)
        icon.imageScaling = .scaleProportionallyDown

        let label = NSTextField(frame: NSRect(x: 48, y: 12, width: tableView.frame.width - 60, height: 20))
        label.stringValue = name
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.textColor = .white
        label.font = NSFont.systemFont(ofSize: 14, weight: .regular)

        container.addSubview(icon)
        container.addSubview(label)

        return container
    }
}
