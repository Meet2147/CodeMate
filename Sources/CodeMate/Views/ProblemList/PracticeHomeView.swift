import SwiftUI
import SwiftData

struct PracticeHomeView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppPreferences.self) private var prefs
    @Environment(StoreManager.self) private var store
    @Query private var progressRecords: [ProblemProgress]

    @State private var searchText = ""
    @State private var selectedCompanies: Set<Company> = []
    @State private var selectedTopics: Set<Topic> = []
    @State private var selectedDifficulties: Set<Difficulty> = []
    @State private var selectedProblemId: String?
    @State private var hasSeededFromPreferences = false
    @State private var showsPaywall = false

    private var progressByProblem: [String: ProblemProgress] {
        Dictionary(uniqueKeysWithValues: progressRecords.map { ($0.problemId, $0) })
    }

    /// Companies this plan doesn't include. nil maxTargetCompanies means unlimited.
    private var lockedCompanies: Set<Company> {
        guard let maxCount = store.currentTier.maxTargetCompanies else { return [] }
        let allowed = allowedCompanies(maxCount: maxCount)
        return Set(Company.allCases).subtracting(allowed)
    }

    private func allowedCompanies(maxCount: Int) -> Set<Company> {
        let ordered = Company.allCases.filter { prefs.targetCompanies.contains($0) }
        let base = ordered.isEmpty ? Array(Company.allCases.prefix(maxCount)) : ordered
        return Set(base.prefix(maxCount))
    }

    /// What actually gets filtered against -- locked-out companies never
    /// restrict results even if they're still "selected" from onboarding.
    private var effectiveSelectedCompanies: Set<Company> {
        selectedCompanies.subtracting(lockedCompanies)
    }

    private var filtered: [Problem] {
        let base = ProblemBank.all.filter { problem in
            (effectiveSelectedCompanies.isEmpty || !effectiveSelectedCompanies.isDisjoint(with: problem.companies)) &&
            (selectedTopics.isEmpty || !selectedTopics.isDisjoint(with: problem.topics)) &&
            (selectedDifficulties.isEmpty || selectedDifficulties.contains(problem.difficulty)) &&
            (searchText.isEmpty || problem.title.localizedCaseInsensitiveContains(searchText))
        }
        guard !effectiveSelectedCompanies.isEmpty else { return base }
        // Questions overlapping more of the targeted companies are the most
        // "frequently asked" for this student's target set -- surface those first.
        return base.sorted { a, b in
            let aMatches = effectiveSelectedCompanies.intersection(a.companies).count
            let bMatches = effectiveSelectedCompanies.intersection(b.companies).count
            if aMatches != bMatches { return aMatches > bMatches }
            return a.difficulty < b.difficulty
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                header
                searchField
                CompanyFilterBar(selected: $selectedCompanies, lockedCompanies: lockedCompanies) { _ in
                    showsPaywall = true
                }
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
        .onAppear {
            guard !hasSeededFromPreferences else { return }
            hasSeededFromPreferences = true
            selectedCompanies = prefs.targetCompanies
        }
        .sheet(isPresented: $showsPaywall) {
            PaywallView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DSA Practice")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(CMTheme.textPrimary(scheme))
            if effectiveSelectedCompanies.count == 1, let company = effectiveSelectedCompanies.first {
                Text("Frequently asked at \(company.rawValue) -- \(filtered.count) problems")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(CMTheme.companyColor(company))
            } else {
                Text("\(filtered.count) of \(ProblemBank.all.count) problems")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CMTheme.textSecondary(scheme))
            }
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
