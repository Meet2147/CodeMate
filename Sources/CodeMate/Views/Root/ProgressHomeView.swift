import SwiftUI
import SwiftData

struct ProgressHomeView: View {
    @Environment(\.colorScheme) private var scheme
    @Query private var progressRecords: [ProblemProgress]
    @Query(sort: \DailyActivity.dayKey) private var activity: [DailyActivity]

    private var solvedIds: Set<String> { Set(progressRecords.filter { $0.status == .solved }.map(\.problemId)) }
    private var inProgressIds: Set<String> { Set(progressRecords.filter { $0.status == .inProgress }.map(\.problemId)) }

    private var solvedCount: Int { solvedIds.count }
    private var inProgressCount: Int { inProgressIds.count }
    private var totalCount: Int { ProblemBank.all.count }

    private var byDifficulty: [(Difficulty, Int, Int)] {
        Difficulty.allCases.map { diff in
            let inDiff = ProblemBank.all.filter { $0.difficulty == diff }
            let solved = inDiff.filter { solvedIds.contains($0.id) }.count
            return (diff, solved, inDiff.count)
        }
    }

    private var byTopic: [(Topic, Int, Int)] {
        Topic.allCases.map { topic in
            let inTopic = ProblemBank.all.filter { $0.topics.contains(topic) }
            let solved = inTopic.filter { solvedIds.contains($0.id) }.count
            return (topic, solved, inTopic.count)
        }.filter { $0.2 > 0 }
    }

    private var byCompany: [(Company, Int, Int)] {
        Company.allCases.map { company in
            let inCompany = ProblemBank.all.filter { $0.companies.contains(company) }
            let solved = inCompany.filter { solvedIds.contains($0.id) }.count
            return (company, solved, inCompany.count)
        }
    }

    private var activityByDay: [String: DailyActivity] {
        Dictionary(uniqueKeysWithValues: activity.map { ($0.dayKey, $0) })
    }

    private var currentStreak: Int {
        let active = Set(activity.filter { $0.runCount > 0 }.map(\.dayKey))
        guard !active.isEmpty else { return 0 }
        var streak = 0
        var cursor = Calendar.current.startOfDay(for: .now)
        if !active.contains(ActivityTracker.dayKey(for: cursor)) {
            cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        while active.contains(ActivityTracker.dayKey(for: cursor)) {
            streak += 1
            guard let prior = Calendar.current.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prior
        }
        return streak
    }

    private var longestStreak: Int {
        let days = activity.filter { $0.runCount > 0 }.compactMap { ActivityTracker.date(from: $0.dayKey) }.sorted()
        guard !days.isEmpty else { return 0 }
        var longest = 1, current = 1
        for i in 1..<days.count {
            let gap = Calendar.current.dateComponents([.day], from: days[i - 1], to: days[i]).day ?? 0
            if gap == 1 { current += 1 } else if gap > 1 { current = 1 }
            longest = max(longest, current)
        }
        return longest
    }

    private var totalRuns: Int { activity.reduce(0) { $0 + $1.runCount } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("My Progress")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(CMTheme.textPrimary(scheme))

                HStack(spacing: 14) {
                    statTile(title: "Solved", value: "\(solvedCount)", caption: "of \(totalCount) problems", color: CMTheme.success)
                    statTile(title: "Current Streak", value: "\(currentStreak)", caption: currentStreak == 1 ? "day" : "days", color: .orange, emoji: currentStreak > 0 ? "🔥" : nil)
                    statTile(title: "Longest Streak", value: "\(longestStreak)", caption: longestStreak == 1 ? "day" : "days", color: CMTheme.accent)
                    statTile(title: "Total Runs", value: "\(totalRuns)", caption: "code executions", color: CMTheme.warning)
                }

                contributionGraph

                HStack(alignment: .top, spacing: 14) {
                    difficultyBreakdown
                        .frame(maxWidth: .infinity)
                    companyBreakdown
                        .frame(maxWidth: .infinity)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("BY TOPIC").font(.system(size: 10, weight: .bold)).foregroundStyle(CMTheme.textSecondary(scheme))
                    ForEach(byTopic, id: \.0) { topic, solved, total in
                        progressRow(label: topic.rawValue, solved: solved, total: total, color: CMTheme.accent)
                    }
                }
                .neumorphicRaised(padding: 16)
            }
            .padding(24)
        }
        .background(CMTheme.base(scheme))
    }

    // MARK: - Stat tiles

    private func statTile(title: String, value: String, caption: String, color: Color, emoji: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased()).font(.system(size: 10, weight: .bold)).foregroundStyle(CMTheme.textSecondary(scheme))
            HStack(spacing: 4) {
                Text(value).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(color)
                if let emoji { Text(emoji).font(.system(size: 20)) }
            }
            Text(caption).font(.system(size: 10)).foregroundStyle(CMTheme.textSecondary(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neumorphicRaised(padding: 16)
    }

    // MARK: - Contribution heatmap

    private var contributionGraph: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ACTIVITY").font(.system(size: 10, weight: .bold)).foregroundStyle(CMTheme.textSecondary(scheme))
                Spacer()
                HStack(spacing: 4) {
                    Text("Less").font(.system(size: 9)).foregroundStyle(CMTheme.textSecondary(scheme))
                    ForEach(0..<5) { level in
                        RoundedRectangle(cornerRadius: 2).fill(heatColor(level)).frame(width: 10, height: 10)
                    }
                    Text("More").font(.system(size: 9)).foregroundStyle(CMTheme.textSecondary(scheme))
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                heatmapGrid
            }
        }
        .neumorphicRaised(padding: 16)
    }

    private var weekColumns: [[Date]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let totalDays = 53 * 7
        let startWeekday = calendar.component(.weekday, from: today) // 1 = Sunday
        let start = calendar.date(byAdding: .day, value: -(totalDays - 1) - (startWeekday - 1), to: today) ?? today
        var days: [Date] = []
        var cursor = start
        while days.count < totalDays + startWeekday {
            days.append(cursor)
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor
        }
        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0 + 7, days.count)]) }
    }

    private var heatmapGrid: some View {
        let byDay = activityByDay
        return HStack(alignment: .top, spacing: 3) {
            ForEach(Array(weekColumns.enumerated()), id: \.offset) { _, week in
                VStack(spacing: 3) {
                    ForEach(week, id: \.self) { day in
                        let key = ActivityTracker.dayKey(for: day)
                        let count = byDay[key]?.runCount ?? 0
                        let isFuture = day > .now
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isFuture ? Color.clear : heatColor(level(for: count)))
                            .frame(width: 10, height: 10)
                            .help(isFuture ? "" : "\(count) run\(count == 1 ? "" : "s") on \(day.formatted(date: .abbreviated, time: .omitted))")
                    }
                }
            }
        }
    }

    private func level(for count: Int) -> Int {
        switch count {
        case 0: return 0
        case 1: return 1
        case 2...3: return 2
        case 4...6: return 3
        default: return 4
        }
    }

    private func heatColor(_ level: Int) -> Color {
        if level == 0 { return CMTheme.shadowDark(scheme).opacity(0.25) }
        return CMTheme.success.opacity(0.25 + 0.19 * Double(level))
    }

    // MARK: - Difficulty / company breakdowns

    private var difficultyBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BY DIFFICULTY").font(.system(size: 10, weight: .bold)).foregroundStyle(CMTheme.textSecondary(scheme))
            ForEach(byDifficulty, id: \.0) { difficulty, solved, total in
                progressRow(label: difficulty.rawValue, solved: solved, total: total, color: difficulty.color)
            }
        }
        .neumorphicRaised(padding: 16)
    }

    private var companyBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BY TARGET COMPANY").font(.system(size: 10, weight: .bold)).foregroundStyle(CMTheme.textSecondary(scheme))
            ForEach(byCompany.filter { $0.2 > 0 }.prefix(6), id: \.0) { company, solved, total in
                progressRow(label: company.rawValue, solved: solved, total: total, color: CMTheme.companyColor(company))
            }
        }
        .neumorphicRaised(padding: 16)
    }

    private func progressRow(label: String, solved: Int, total: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(CMTheme.textPrimary(scheme))
                Spacer()
                Text("\(solved)/\(total)").font(.system(size: 11, weight: .semibold)).foregroundStyle(CMTheme.textSecondary(scheme))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(CMTheme.shadowDark(scheme).opacity(0.3)).frame(height: 6)
                    Capsule().fill(color.gradient)
                        .frame(width: total == 0 ? 0 : geo.size.width * CGFloat(solved) / CGFloat(total), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
