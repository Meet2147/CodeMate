import Foundation
import SwiftData

enum SolveStatus: String, Codable {
    case notStarted, inProgress, solved
}

/// Persisted per-problem progress: solve status, saved draft code, notes,
/// and how many hints the learner has revealed so far (used to keep the
/// assistant's hint ladder in sync between launches).
@Model
final class ProblemProgress {
    @Attribute(.unique) var problemId: String
    var statusRaw: String
    var savedCode: String
    var languageRaw: String
    var notes: String
    var hintsRevealed: Int
    var lastOpened: Date
    var attempts: Int

    init(problemId: String,
         status: SolveStatus = .notStarted,
         savedCode: String = "",
         language: ProgrammingLanguage = .swift,
         notes: String = "",
         hintsRevealed: Int = 0,
         lastOpened: Date = .now,
         attempts: Int = 0) {
        self.problemId = problemId
        self.statusRaw = status.rawValue
        self.savedCode = savedCode
        self.languageRaw = language.rawValue
        self.notes = notes
        self.hintsRevealed = hintsRevealed
        self.lastOpened = lastOpened
        self.attempts = attempts
    }

    var status: SolveStatus {
        get { SolveStatus(rawValue: statusRaw) ?? .notStarted }
        set { statusRaw = newValue.rawValue }
    }

    var language: ProgrammingLanguage {
        get { ProgrammingLanguage(rawValue: languageRaw) ?? .swift }
        set { languageRaw = newValue.rawValue }
    }
}
