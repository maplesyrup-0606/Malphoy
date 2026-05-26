import Foundation

struct TodoItem: Codable {
    var id: UUID
    var text: String
    var isDone: Bool
    var children: [TodoItem]

    init(id: UUID = UUID(), text: String, isDone: Bool = false, children: [TodoItem] = []) {
        self.id = id
        self.text = text
        self.isDone = isDone
        self.children = children
    }
}

struct FlatRow {
    enum Kind {
        case parent(Int)
        case child(parentIndex: Int, childIndex: Int)
    }
    let kind: Kind
    let item: TodoItem

    var isChild: Bool {
        if case .child = kind { return true }
        return false
    }
}

final class TodoStore {
    static let shared = TodoStore()
    private(set) var items: [TodoItem] = []
    private var todoFileURL: URL?

    private init() {
        load()
    }

    var flatRows: [FlatRow] {
        var rows: [FlatRow] = []
        for (pi, parent) in items.enumerated() {
            rows.append(FlatRow(kind: .parent(pi), item: parent))
            for (ci, child) in parent.children.enumerated() {
                rows.append(FlatRow(kind: .child(parentIndex: pi, childIndex: ci), item: child))
            }
        }
        return rows
    }

    func add(text: String) {
        items.append(TodoItem(text: text))
        save()
    }

    func addChild(text: String, toParentAt parentIndex: Int) {
        guard parentIndex < items.count else { return }
        items[parentIndex].children.append(TodoItem(text: text))
        save()
    }

    func toggle(at flatIndex: Int) {
        let rows = flatRows
        guard flatIndex < rows.count else { return }
        switch rows[flatIndex].kind {
        case .parent(let pi):
            let newDone = !items[pi].isDone
            items[pi].isDone = newDone
            // Rule 1: parent cleared → all children follow
            for ci in items[pi].children.indices {
                items[pi].children[ci].isDone = newDone
            }
        case .child(let pi, let ci):
            items[pi].children[ci].isDone.toggle()
            // Rule 2: all children done → parent auto-done; any child undone → parent undone
            let allDone = !items[pi].children.isEmpty && items[pi].children.allSatisfy { $0.isDone }
            items[pi].isDone = allDone
        }
        save()
    }

    func reload() {
        load()
        save() // removes done items so they're cleared on next open
    }

    private func load() {
        let env = loadEnv()
        guard let path = env["MALPHOY_TODOS_PATH"] else { return }
        todoFileURL = URL(fileURLWithPath: path)
        guard let raw = try? String(contentsOf: todoFileURL!, encoding: .utf8) else { return }

        items = []
        var inDoneParent = false
        for line in raw.components(separatedBy: .newlines) {
            if line.hasPrefix("- [ ]") {
                items.append(TodoItem(text: String(line.dropFirst(6)), isDone: false))
                inDoneParent = false
            } else if line.hasPrefix("- [x]") {
                // Done parents are excluded on next open (rule 4)
                inDoneParent = true
            } else if line.hasPrefix("  - [ ]") && !inDoneParent && !items.isEmpty {
                items[items.count - 1].children.append(
                    TodoItem(text: String(line.dropFirst(7)), isDone: false)
                )
            }
            // Done children (  - [x]) are excluded on next open (rule 4)
        }
    }

    private func loadEnv() -> [String: String] {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/malphoy/.env")
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return [:] }
        var result: [String: String] = [:]
        for line in raw.components(separatedBy: .newlines) {
            let parts = line.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            result[String(parts[0]).trimmingCharacters(in: .whitespaces)] =
                String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return result
    }

    func save() {
        guard let url = todoFileURL else { return }
        let raw = (try? String(contentsOf: url, encoding: .utf8)) ?? ""

        let nonTaskLines = raw.components(separatedBy: .newlines).filter {
            !$0.hasPrefix("- [ ]") && !$0.hasPrefix("- [x]") &&
            !$0.hasPrefix("  - [ ]") && !$0.hasPrefix("  - [x]")
        }

        var taskLines: [String] = []
        for item in items {
            taskLines.append((item.isDone ? "- [x] " : "- [ ] ") + item.text)
            for child in item.children {
                taskLines.append((child.isDone ? "  - [x] " : "  - [ ] ") + child.text)
            }
        }

        let output = (nonTaskLines + taskLines).joined(separator: "\n")
        try? output.write(to: url, atomically: true, encoding: .utf8)
    }
}
