import SwiftUI
import SwiftData

/// A guided, ordered path through the 15 core DSA topics -- for a total
/// novice who'd otherwise open "DSA Practice" and freeze on 102
/// unordered problems with no sense of what to do first. This isn't a
/// separate problem set: it's the same `ProblemBank` data, just grouped
/// into stages with a recommended order and "you are here" surfaced
/// explicitly, so studying feels like following a path instead of
/// picking randomly.
struct RoadmapHomeView: View {
    @Query private var progressRecords: [ProblemProgress]
    @State private var expandedTopic: Topic?
    @State private var selectedProblemId: String?
    @State private var hasSeededExpansion = false

    private var progressByProblem: [String: ProblemProgress] {
        Dictionary(uniqueKeysWithValues: progressRecords.map { ($0.problemId, $0) })
    }

    private var solvedIds: Set<String> {
        Set(progressRecords.filter { $0.status == .solved }.map(\.problemId))
    }

    private func problems(for topic: Topic) -> [Problem] {
        ProblemBank.all
            .filter { $0.topics.contains(topic) }
            .sorted { $0.difficulty < $1.difficulty }
    }

    private func solvedCount(for topic: Topic) -> (solved: Int, total: Int) {
        let all = problems(for: topic)
        return (all.filter { solvedIds.contains($0.id) }.count, all.count)
    }

    /// The first stage that isn't fully solved yet -- "where a novice
    /// should pick up right now." Falls back to the last stage once
    /// everything's clear.
    private var currentStage: RoadmapStage? {
        RoadmapData.stages.first { stage in
            let (solved, total) = solvedCount(for: stage.topic)
            return total > 0 && solved < total
        } ?? RoadmapData.stages.last
    }

    private func nextProblem(in topic: Topic) -> Problem? {
        problems(for: topic).first { !solvedIds.contains($0.id) }
    }

    private var overallCounts: (solved: Int, total: Int) {
        RoadmapData.stages.reduce((0, 0)) { acc, stage in
            let c = solvedCount(for: stage.topic)
            return (acc.0 + c.solved, acc.1 + c.total)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Rectangle().fill(IDETheme.border).frame(width: 1)
            Group {
                if let id = selectedProblemId, let problem = ProblemBank.problem(id: id) {
                    ProblemWorkspaceView(problem: problem, onClose: { selectedProblemId = nil })
                        .id(problem.id)
                } else {
                    overviewPlaceholder
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environment(\.colorScheme, .dark)
        .onAppear {
            guard !hasSeededExpansion else { return }
            hasSeededExpansion = true
            expandedTopic = currentStage?.topic
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(RoadmapData.stages) { stage in
                        stageCard(stage)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .padding(14)
        .frame(width: 320)
        .background(IDETheme.sidebarBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Roadmap")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(IDETheme.textPrimary)
            let counts = overallCounts
            Text("\(counts.solved) of \(counts.total) roadmap problems solved")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(IDETheme.textSecondary)
        }
    }

    private func stageCard(_ stage: RoadmapStage) -> some View {
        let counts = solvedCount(for: stage.topic)
        let isExpanded = expandedTopic == stage.topic
        let isComplete = counts.total > 0 && counts.solved == counts.total
        let isCurrent = stage.topic == currentStage?.topic && !isComplete

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeOut(duration: 0.15)) {
                    expandedTopic = isExpanded ? nil : stage.topic
                }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    stageBadge(stage.order, isComplete: isComplete, isCurrent: isCurrent)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(stage.topic.rawValue)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(IDETheme.textPrimary)
                            Spacer()
                            Text("\(counts.solved)/\(counts.total)")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundStyle(IDETheme.textSecondary)
                        }
                        Text(stage.blurb)
                            .font(.system(size: 10.5))
                            .foregroundStyle(IDETheme.textSecondary)
                            .lineLimit(isExpanded ? nil : 2)
                            .fixedSize(horizontal: false, vertical: true)
                        stageProgressBar(solved: counts.solved, total: counts.total)
                    }
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 1) {
                    ForEach(problems(for: stage.topic)) { problem in
                        ProblemRowView(
                            problem: problem,
                            status: progressByProblem[problem.id]?.status ?? .notStarted,
                            isSelected: selectedProblemId == problem.id
                        )
                        .onTapGesture { selectedProblemId = problem.id }
                    }
                }
                .padding(.leading, 34)
                .padding(.top, 2)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isCurrent ? IDETheme.accent.opacity(0.10) : IDETheme.elevatedBackground.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isCurrent ? IDETheme.accent.opacity(0.5) : IDETheme.border, lineWidth: 1)
        )
    }

    private func stageBadge(_ order: Int, isComplete: Bool, isCurrent: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isComplete ? CMTheme.success : (isCurrent ? IDETheme.accent : IDETheme.elevatedBackground))
            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text("\(order)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(isCurrent ? .white : IDETheme.textSecondary)
            }
        }
        .frame(width: 22, height: 22)
        .overlay(Circle().stroke(IDETheme.border, lineWidth: isComplete || isCurrent ? 0 : 1))
    }

    private func stageProgressBar(solved: Int, total: Int) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08)).frame(height: 4)
                Capsule().fill(CMTheme.success.gradient)
                    .frame(width: total == 0 ? 0 : geo.size.width * CGFloat(solved) / CGFloat(total), height: 4)
            }
        }
        .frame(height: 4)
        .padding(.top, 2)
    }

    // MARK: - Overview / "continue here"

    private var overviewPlaceholder: some View {
        VStack(spacing: 18) {
            Image(systemName: "map.fill")
                .font(.system(size: 40))
                .foregroundStyle(IDETheme.accent)

            if let stage = currentStage, let next = nextProblem(in: stage.topic) {
                VStack(spacing: 6) {
                    Text("Stage \(stage.order) of \(RoadmapData.stages.count) \u{00B7} \(stage.topic.rawValue)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(IDETheme.textSecondary)
                    Text("Pick up here")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(IDETheme.textPrimary)
                    Text(stage.blurb)
                        .font(.system(size: 12.5))
                        .foregroundStyle(IDETheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                }

                Button {
                    expandedTopic = stage.topic
                    selectedProblemId = next.id
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Continue with \"\(next.title)\"")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(IDEButtonStyle(tint: IDETheme.accent, prominent: true))
            } else {
                Text("Roadmap complete")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(IDETheme.textPrimary)
                Text("You've solved every problem in every stage. Head to DSA Practice to keep going at random, or revisit a company's specific set.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(IDETheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }

            Text("Or pick any stage on the left \u{2014} solving out of order is fine, this is just a suggested path, not a gate.")
                .font(.system(size: 10.5))
                .foregroundStyle(IDETheme.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(IDETheme.background)
    }
}
