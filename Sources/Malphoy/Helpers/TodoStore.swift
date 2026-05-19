import Foundation

struct TodoItem: Codable {
    var id: UUID
    var text: String
    var isDone: Bool
}

final class TodoStore {
    static let shared = TodoStore()
    private(set) var items: [TodoItem] = []
    private var todoFileURL: URL?

    private init() {
        load()
    }

    func add(text: String) {
        items.append(TodoItem(id: UUID(), text: text, isDone: false))
        save()
    }

    func toggle(at index: Int) {
        items[index].isDone.toggle()
        save()
    }

    func reload() {
        load()
        save() // removes any externally-toggled [x] items from the file
    }

    private func load() {
        let env = loadEnv()
        guard let path = env["MALPHOY_TODOS_PATH"] else { return }
        todoFileURL = URL(fileURLWithPath: path)
        guard let raw = try? String(contentsOf: todoFileURL!, encoding: .utf8) else { return }

        items = []
        for line in raw.components(separatedBy: .newlines) {
            // Only load undone items — done items are excluded on next open
            if line.hasPrefix("- [ ]") {
                items.append(TodoItem(id: UUID(), text: String(line.dropFirst(6)), isDone: false))
            }
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
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            result[key] = value
        }
        return result
    }

    func save() {
        guard let url = todoFileURL else { return }

        // Treat missing file as empty — allows saving to a new file
        let raw = (try? String(contentsOf: url, encoding: .utf8)) ?? ""

        // Preserve non-task lines (headers, notes, blank lines with content)
        let nonTaskLines = raw.components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("- [ ]") && !$0.hasPrefix("- [x]") }

        // Write current items — done items written as [x] so they exist in
        // the file this session, but load() skips them on next open
        let taskLines = items.map { ($0.isDone ? "- [x] " : "- [ ] ") + $0.text }

        let output = (nonTaskLines + taskLines).joined(separator: "\n")
        try? output.write(to: url, atomically: true, encoding: .utf8)
    }
}
