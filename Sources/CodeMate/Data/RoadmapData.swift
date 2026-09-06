import Foundation

/// One stage in the guided novice path -- a single topic, in the order a
/// beginner should tackle it. This mirrors the well-established "NeetCode
/// 150"-style curriculum ordering (which happens to already match the
/// declaration order of `Topic` in Company.swift) rather than reinventing
/// one, but it's spelled out explicitly here so the roadmap's order can
/// never silently drift if `Topic`'s case order ever changes for an
/// unrelated reason.
struct RoadmapStage: Identifiable {
    var id: Topic { topic }
    var order: Int
    var topic: Topic
    /// One sentence: what the pattern is and why it comes at this point.
    var blurb: String
}

enum RoadmapData {
    static let stages: [RoadmapStage] = [
        RoadmapStage(order: 1, topic: .arrays, blurb: "The foundation -- most other patterns build on manipulating arrays and using hash maps for O(1) lookups."),
        RoadmapStage(order: 2, topic: .twoPointers, blurb: "Two moving indices instead of nested loops -- the first real technique that turns O(n\u{00B2}) into O(n)."),
        RoadmapStage(order: 3, topic: .slidingWindow, blurb: "An extension of two pointers for subarrays and substrings -- track a shrinking or growing window instead of recomputing from scratch."),
        RoadmapStage(order: 4, topic: .stack, blurb: "Last-in-first-out order shows up everywhere -- matching brackets, undo history, evaluating expressions."),
        RoadmapStage(order: 5, topic: .binarySearch, blurb: "Not just for sorted arrays -- learn to recognize when a problem's answer space itself can be searched."),
        RoadmapStage(order: 6, topic: .linkedList, blurb: "Pointer manipulation without array indices -- reversing, detecting cycles, and merging lists."),
        RoadmapStage(order: 7, topic: .trees, blurb: "Recursion's home turf -- traversals, depth, and balance become second nature here."),
        RoadmapStage(order: 8, topic: .tries, blurb: "A specialized tree for prefix-based lookups -- autocomplete and word-search problems live here."),
        RoadmapStage(order: 9, topic: .heaps, blurb: "Always grab the min or max in O(log n) -- essential for \"top K\" and scheduling problems."),
        RoadmapStage(order: 10, topic: .backtracking, blurb: "Systematic trial-and-error with undo -- permutations, combinations, and puzzle-solving."),
        RoadmapStage(order: 11, topic: .graphs, blurb: "Trees, generalized -- BFS/DFS over arbitrary connections, the backbone of most real-world modeling problems."),
        RoadmapStage(order: 12, topic: .dynamicProgramming, blurb: "The pattern most candidates fear -- break a problem into overlapping subproblems and cache the answers."),
        RoadmapStage(order: 13, topic: .greedy, blurb: "Make the locally best choice at each step -- learn when that's actually provably optimal."),
        RoadmapStage(order: 14, topic: .intervals, blurb: "Merging, scheduling, and overlap problems -- mostly about sorting the right way first."),
        RoadmapStage(order: 15, topic: .math, blurb: "The long tail -- number theory tricks and bitwise operations that show up just often enough to matter."),
    ]
}
