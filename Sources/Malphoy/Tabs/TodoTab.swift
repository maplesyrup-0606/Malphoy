import AppKit

final class TodoTab: NSView {
    var onTabKey: (() -> Void)?

    private var selectedIndex: Int = 0

    private let inputField: NSTextField
    private let tableView: NSTableView
    private let scrollView: NSScrollView
    private let emptyLabel: NSTextField

    override init(frame: NSRect) {
        inputField = NSTextField(frame: .zero)
        tableView = NSTableView(frame: .zero)
        scrollView = NSScrollView(frame: .zero)
        emptyLabel = NSTextField(frame: .zero)

        super.init(frame: frame)
        wantsLayer = true
        setupInputField()
        setupTableView()
        setupEmptyLabel()
        refreshEmptyState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupInputField() {
        inputField.placeholderString = "Add a to-do..."
        inputField.isBezeled = false
        inputField.drawsBackground = false
        inputField.font = NSFont.systemFont(ofSize: 18, weight: .light)
        inputField.textColor = .white
        inputField.focusRingType = .none
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.delegate = self

        addSubview(inputField)

        NSLayoutConstraint.activate([
            inputField.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            inputField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            inputField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            inputField.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func setupTableView() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("todo"))
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
            scrollView.topAnchor.constraint(equalTo: inputField.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }

    private func setupEmptyLabel() {
        emptyLabel.stringValue = "No to-dos yet. Type above and press Enter."
        emptyLabel.isEditable = false
        emptyLabel.isBezeled = false
        emptyLabel.drawsBackground = false
        emptyLabel.textColor = NSColor.white.withAlphaComponent(0.25)
        emptyLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        emptyLabel.alignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 20),
        ])
    }

    private func refreshEmptyState() {
        emptyLabel.isHidden = !TodoStore.shared.items.isEmpty
    }

    // MARK: - Actions

    private func addTodo() {
        let text = inputField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        TodoStore.shared.add(text: text)
        inputField.stringValue = ""
        tableView.reloadData()
        selectedIndex = 0
        refreshEmptyState()
    }

    private func toggleSelected() {
        guard !TodoStore.shared.items.isEmpty else { return }
        TodoStore.shared.toggle(at: selectedIndex)
        tableView.reloadData()
    }

    private func moveSelection(by delta: Int) {
        let count = TodoStore.shared.items.count
        guard count > 0 else { return }
        selectedIndex = max(0, min(count - 1, selectedIndex + delta))
        tableView.reloadData()
        tableView.scrollRowToVisible(selectedIndex)
    }

    // MARK: - Focus

    func focusInput() {
        window?.makeFirstResponder(inputField)
    }

    func reload() {
        TodoStore.shared.reload()
        selectedIndex = 0
        tableView.reloadData()
        refreshEmptyState()
    }

    // MARK: - Keyboard

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 125: moveSelection(by: 1)
        case 126: moveSelection(by: -1)
        case 36:
            if !inputField.stringValue.trimmingCharacters(in: .whitespaces).isEmpty {
                addTodo()
            } else {
                toggleSelected()
            }
        default:
            super.keyDown(with: event)
        }
    }
}

// MARK: - NSTextFieldDelegate

extension TodoTab: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        // input only — no filtering
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
            if !inputField.stringValue.trimmingCharacters(in: .whitespaces).isEmpty {
                addTodo()
            } else {
                toggleSelected()
            }
            return true
        default:
            return false
        }
    }
}

// MARK: - NSTableViewDataSource

extension TodoTab: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        TodoStore.shared.items.count
    }
}

// MARK: - NSTableViewDelegate

extension TodoTab: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = TodoStore.shared.items[row]

        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 8

        if row == selectedIndex {
            container.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.1).cgColor
        }

        let check = NSTextField(frame: NSRect(x: 14, y: 12, width: 20, height: 20))
        check.stringValue = item.isDone ? "✓" : "○"
        check.isEditable = false
        check.isBezeled = false
        check.drawsBackground = false
        check.textColor = item.isDone ? .systemGreen : NSColor.white.withAlphaComponent(0.35)
        check.font = NSFont.systemFont(ofSize: 14)

        let label = NSTextField(frame: NSRect(x: 44, y: 12, width: tableView.frame.width - 56, height: 20))
        label.stringValue = item.text
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.textColor = item.isDone ? NSColor.white.withAlphaComponent(0.35) : .white
        label.font = NSFont.systemFont(ofSize: 14, weight: item.isDone ? .light : .regular)

        container.addSubview(check)
        container.addSubview(label)

        return container
    }
}
