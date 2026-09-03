import Foundation

enum DesignScope: String, CaseIterable, Identifiable, Codable {
    case lld = "Low-Level Design"
    case hld = "High-Level Design"

    var id: String { rawValue }
    var shortLabel: String { self == .lld ? "LLD" : "HLD" }
}

struct DesignSection: Identifiable, Codable, Hashable {
    var id = UUID()
    var heading: String
    var bullets: [String]
}

struct SystemDesignQuestion: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var scope: DesignScope
    var companies: [Company]
    var difficulty: Difficulty
    var prompt: String
    var clarifyingQuestions: [String]
    var sections: [DesignSection]     // requirements, entities/APIs, data model, scaling, trade-offs...
}
