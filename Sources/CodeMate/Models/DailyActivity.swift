import Foundation
import SwiftData

/// One calendar day's activity, day-keyed as "yyyy-MM-dd" in the user's
/// current time zone. Powers the streak counters and the GitHub-style
/// contribution heatmap on the Progress tab. Deliberately coarse (a count
/// per day, not a full event log) -- enough for "did you show up today",
/// not a detailed history.
@Model
final class DailyActivity {
    @Attribute(.unique) var dayKey: String
    var runCount: Int
    var solveCount: Int

    init(dayKey: String, runCount: Int = 0, solveCount: Int = 0) {
        self.dayKey = dayKey
        self.runCount = runCount
        self.solveCount = solveCount
    }
}

enum ActivityTracker {
    static func dayKey(for date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    static func date(from dayKey: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dayKey)
    }

    /// Call once per code run (any run counts as "showing up", like a
    /// commit -- solved or not); bumps today's row, creating it if needed.
    static func recordRun(solved: Bool, in context: ModelContext) {
        let key = dayKey()
        let descriptor = FetchDescriptor<DailyActivity>(predicate: #Predicate { $0.dayKey == key })
        if let existing = try? context.fetch(descriptor).first {
            existing.runCount += 1
            if solved { existing.solveCount += 1 }
        } else {
            context.insert(DailyActivity(dayKey: key, runCount: 1, solveCount: solved ? 1 : 0))
        }
    }
}
