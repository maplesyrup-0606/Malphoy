import Foundation

func fuzzyMatch(query: String, target: String) -> (match: Bool, score: Int) {
    let query = query.lowercased()
    let target = target.lowercased()

    if query.isEmpty { return (true, 0) }

    var score = 0
    var queryIndex = query.startIndex
    var lastMatchPos = -2

    for (i, char) in target.enumerated() {
        guard queryIndex < query.endIndex else { break }
        if char == query[queryIndex] {
            score += 1
            if i == lastMatchPos + 1 { score += 2 }
            lastMatchPos = i
            queryIndex = query.index(after: queryIndex)
        }
    }

    let matched = queryIndex == query.endIndex
    return (matched, matched ? score : 0)
}
