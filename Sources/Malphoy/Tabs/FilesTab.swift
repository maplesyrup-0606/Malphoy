import AppKit

final class FilesTab: NSView {
    private var files: [URL] = []
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
        loadFiles()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupSearchField() {
        searchField.placeholderString = "Search files and folders..."
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
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("file"))
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

    func loadFiles() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let home = FileManager.default.homeDirectoryForCurrentUser
            guard let enumerator = FileManager.default.enumerator(
                at: home,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { return }

            let skipDirs: Set<String> = ["Library", "node_modules", ".Trash", "vendor", "Pods"]
            var found: [URL] = []
            for case let url as URL in enumerator {
                let name = url.lastPathComponent
                if name.hasPrefix(".") {
                    enumerator.skipDescendants()
                    continue
                }
                let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
                if values?.isDirectory == true && skipDirs.contains(name) {
                    enumerator.skipDescendants()
                    continue
                }
                if values?.isRegularFile == true || values?.isDirectory == true {
                    found.append(url)
                }
            }

            DispatchQueue.main.async {
                self.files = found
            }
        }
    }

    private func filterFiles(query: String) {
        guard !query.isEmpty else {
            filtered = []
            tableView.reloadData()
            resetSelection()
            return
        }

        filtered = files
            .compactMap { url -> (URL, Int)? in
                let name = url.lastPathComponent
                let (match, score) = fuzzyMatch(query: query, target: name)
                return match ? (url, score) : nil
            }
            .sorted { $0.1 > $1.1 }
            .prefix(20)
            .map { $0.0 }

        tableView.reloadData()
        resetSelection()
    }

    private func revealSelected() {
        guard !filtered.isEmpty else { return }
        let url = filtered[selectedIndex]
        let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
        if isDir {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
        window?.orderOut(nil)
    }

    // MARK: - Selection

    func resetSelection() {
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
        case 125: moveSelection(by: 1)
        case 126: moveSelection(by: -1)
        case 36:  revealSelected()
        default:  super.keyDown(with: event)
        }
    }
}

// MARK: - NSTextFieldDelegate

extension FilesTab: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        filterFiles(query: searchField.stringValue)
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
            revealSelected()
            return true
        default:
            return false
        }
    }
}

// MARK: - NSTableViewDataSource

extension FilesTab: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        filtered.count
    }
}

// MARK: - NSTableViewDelegate

extension FilesTab: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let file = filtered[row]
        let name = file.lastPathComponent
        let parent = file.deletingLastPathComponent().path
            .replacingOccurrences(of: NSHomeDirectory(), with: "~")

        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 8

        if row == selectedIndex {
            container.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.1).cgColor
        }

        let icon = NSImageView(frame: NSRect(x: 10, y: 8, width: 28, height: 28))
        icon.image = NSWorkspace.shared.icon(forFile: file.path)
        icon.imageScaling = .scaleProportionallyDown

        let nameLabel = NSTextField(frame: NSRect(x: 48, y: 18, width: tableView.frame.width - 60, height: 16))
        nameLabel.stringValue = name
        nameLabel.isEditable = false
        nameLabel.isBezeled = false
        nameLabel.drawsBackground = false
        nameLabel.textColor = .white
        nameLabel.font = NSFont.systemFont(ofSize: 14, weight: .regular)

        let pathLabel = NSTextField(frame: NSRect(x: 48, y: 4, width: tableView.frame.width - 60, height: 12))
        pathLabel.stringValue = parent
        pathLabel.isEditable = false
        pathLabel.isBezeled = false
        pathLabel.drawsBackground = false
        pathLabel.textColor = NSColor.white.withAlphaComponent(0.4)
        pathLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)

        container.addSubview(icon)
        container.addSubview(nameLabel)
        container.addSubview(pathLabel)

        return container
    }
}
