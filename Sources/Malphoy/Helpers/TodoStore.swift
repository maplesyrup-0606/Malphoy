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

    private func load() {
        let env = loadEnv()
        guard let path  = env["MALPHOY_TODOS_PATH"] else { return }
        todoFileURL = URL(fileURLWithPath: path)
        guard let raw = try? String(contentsOf: todoFileURL!, encoding: .utf8) else { return }

        items = []
        for line in raw.components(separatedBy: .newlines) {
                if line.hasPrefix("- [ ]") {
                        items.append(TodoItem(id: UUID(), text: String(line.dropFirst(6)), isDone: false))
                    }
                else if line.hasPrefix("- [x]") {
                        items.append(TodoItem(id: UUID(), text: String(line.dropFirst(6)), isDone: true))
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
                    result[String(parts[0])] = String(parts[1])
                }

            return result
        }

    func save() {
        guard let url = todoFileURL,
            let raw = try? String(contentsOf: url, encoding: .utf8) else { return }

        var taskIndex = 0
        var outputLines: [String] = []

        for line in raw.components(separatedBy: .newlines) {
                if line.hasPrefix("- [ ]") || line.hasPrefix("- [x]") {
                        guard taskIndex < items.count else { continue }
                        let item = items[taskIndex]
                        outputLines.append((item.isDone ? "- [x] " : "- [ ] ") + item.text)
                        taskIndex += 1
                    }
                else {
                        outputLines.append(line)
                    }
            }

        while taskIndex < items.count {
                let item = items[taskIndex]
                outputLines.append((item.isDone ? "- [x] " : "- [ ] ") + item.text)
                taskIndex += 1
            }

        let output = outputLines.joined(separator: "\n")
        try? output.write(to: url, atomically: true, encoding: .utf8)
    }
}
