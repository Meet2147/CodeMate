import SwiftUI

enum Company: String, CaseIterable, Identifiable, Codable {
    case amazon = "Amazon"
    case google = "Google"
    case apple = "Apple"
    case microsoft = "Microsoft"

    var id: String { rawValue }

    var initials: String {
        switch self {
        case .amazon: return "AMZ"
        case .google: return "GOOG"
        case .apple: return "AAPL"
        case .microsoft: return "MSFT"
        }
    }
}

enum Difficulty: String, CaseIterable, Identifiable, Codable, Comparable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var id: String { rawValue }
    private var rank: Int {
        switch self {
        case .easy: return 0
        case .medium: return 1
        case .hard: return 2
        }
    }
    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool { lhs.rank < rhs.rank }

    var color: Color {
        switch self {
        case .easy: return CMTheme.success
        case .medium: return CMTheme.warning
        case .hard: return CMTheme.danger
        }
    }
}

enum Topic: String, CaseIterable, Identifiable, Codable {
    case arrays = "Arrays & Hashing"
    case twoPointers = "Two Pointers"
    case slidingWindow = "Sliding Window"
    case stack = "Stack"
    case binarySearch = "Binary Search"
    case linkedList = "Linked List"
    case trees = "Trees"
    case tries = "Tries"
    case heaps = "Heap / Priority Queue"
    case backtracking = "Backtracking"
    case graphs = "Graphs"
    case dynamicProgramming = "Dynamic Programming"
    case greedy = "Greedy"
    case intervals = "Intervals"
    case math = "Math & Bit Manipulation"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .arrays: return "square.grid.3x3.fill"
        case .twoPointers: return "arrow.left.arrow.right"
        case .slidingWindow: return "rectangle.compress.vertical"
        case .stack: return "square.stack.3d.up.fill"
        case .binarySearch: return "magnifyingglass"
        case .linkedList: return "link"
        case .trees: return "tree"
        case .tries: return "textformat.abc"
        case .heaps: return "chart.bar.fill"
        case .backtracking: return "arrow.uturn.backward"
        case .graphs: return "point.3.connected.trianglepath.dotted"
        case .dynamicProgramming: return "square.stack.3d.down.forward.fill"
        case .greedy: return "bolt.fill"
        case .intervals: return "calendar"
        case .math: return "function"
        }
    }
}
