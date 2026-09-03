import SwiftUI
import SwiftData

struct PracticeHomeView: View {
    @Environment(\.colorScheme) private var scheme
    @Query private var progressRecords: [ProblemProgress]

    @State private var searchText = ""
    @State private var selectedCompanies: Set<Company> = []
    @State private var selectedTopics: Set<Topic> = []
    @State private var selectedDifficulties: Set<Difficulty> = []
    @State private var selectedProblemId: String?

    private var progressByProblem: [String: ProblemProgress] {
        Dictionary(uniqueKeysWithValues: progressRecords.map { ($0.problemId, $0) })
    }

    private var filtered: [Problem] {
        ProblemBank.all.filter { problem in
            (selectedCompanies.isEmpty || !selectedCompanies.isDisjoint(with: problem.companies)) &&
            (selectedTopics.isEmpty || !selectedTopics.isDisjoint(with: problem.topics)) &&
            (selectedDifficulties.isEmpty || selectedDifficulties.contains(problem.difficulty)) &&
            (searchText.isEmpty || problem.title.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                header
                searchField
                CompanyFilterBar(selected: $selectedCompanies)
                TopicFilterMenu(selected: $selectedTopics)
                DifficultyFilterBar(selected: $selectedDifficulties)
                Divider().padding(.vertical, 4)
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filtered) { problem in
                            ProblemRowView(
                                problem: problem,
                                status: progressByProblem[problem.id]?.status ?? .notStarted,
                                isSelected: selectedProblemId == problem.id
                            )
                            .onTapGesture { selectedProblemId = problem.id }
                        }
                        if filtered.isEmpty {
                            Text("No problems match these filters yet.")
                                .foregroundStyle(CMTheme.textSecondary(scheme))
                                .padding(.top, 40)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .padding(16)
            .frame(width: 320)
            .background(CMTheme.base(scheme))

            Divider()

            Group {
                if let id = selectedProblemId, let problem = ProblemBank.problem(id: id) {
                    ProblemWorkspaceView(problem: problem)
                        .id(problem.id)
                } else {
                    EmptyWorkspacePlaceholder()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DSA Practice")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(CMTheme.textPrimary(scheme))
            Text("\(filtered.count) of \(ProblemBank.all.count) problems")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CMTheme.textSecondary(scheme))
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(CMTheme.textSecondary(scheme))
            TextField("Search problems", text: $searchText)
                .textFieldStyle(.plain)
        }
        .neumorphicInset(radius: CMTheme.smallCornerRadius, padding: 10)
    }
}

private struct EmptyWorkspacePlaceholder: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "curlybraces.square")
                .font(.system(size: 44))
                .foregroundStyle(CMTheme.accent)
            Text("Pick a problem to get started")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(CMTheme.textPrimary(scheme))
            Text("Filter by company or topic on the left, then open a problem.\nThe assistant will help you pick an approach and write it up.")
                .multilineTextAlignment(.center)
                .font(.system(size: 12))
                .foregroundStyle(CMTheme.textSecondary(scheme))
        }
        .padding(40)
        .neumorphicRaised()
    }
}
