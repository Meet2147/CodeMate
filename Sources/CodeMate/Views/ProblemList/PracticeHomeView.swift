import SwiftUI
import SwiftData

struct PracticeHomeView: View {
    @Environment(AppPreferences.self) private var prefs
    @Environment(LicenseManager.self) private var licenseManager
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
        guard let maxCount = licenseManager.currentTier.maxTargetCompanies else { return [] }
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
            VStack(alignment: .leading, spacing: 14) {
                header
                searchField
                CompanyFilterMenu(selected: $selectedCompanies, lockedCompanies: lockedCompanies) { _ in
                    showsPaywall = true
                }
                TopicFilterMenu(selected: $selectedTopics)
                DifficultyFilterBar(selected: $selectedDifficulties)

                HStack {
                    Text("EXPLORER").font(.system(size: 9.5, weight: .bold)).foregroundStyle(IDETheme.textTertiary).kerning(0.6)
                    Spacer()
                    Text("\(filtered.count)").font(.system(size: 9.5, weight: .semibold)).foregroundStyle(IDETheme.textTertiary)
                }
                .padding(.top, 2)

                ScrollView {
                    LazyVStack(spacing: 1) {
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
                                .font(.system(size: 11.5))
                                .foregroundStyle(IDETheme.textSecondary)
                                .padding(.top, 40)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .padding(14)
            .frame(width: 300)
            .background(IDETheme.sidebarBackground)

            Rectangle().fill(IDETheme.border).frame(width: 1)

            Group {
                if let id = selectedProblemId, let problem = ProblemBank.problem(id: id) {
                    ProblemWorkspaceView(problem: problem, onClose: { selectedProblemId = nil })
                        .id(problem.id)
                } else {
                    EmptyWorkspacePlaceholder()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environment(\.colorScheme, .dark)
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
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(IDETheme.textPrimary)
            if effectiveSelectedCompanies.count == 1, let company = effectiveSelectedCompanies.first {
                Text("Frequently asked at \(company.rawValue)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CMTheme.companyColor(company))
            } else {
                Text("\(filtered.count) of \(ProblemBank.all.count) problems")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(IDETheme.textSecondary)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 11)).foregroundStyle(IDETheme.textSecondary)
            TextField("Search problems", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 5).fill(IDETheme.inputBackground))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(IDETheme.border, lineWidth: 1))
    }
}

private struct EmptyWorkspacePlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "curlybraces.square")
                .font(.system(size: 44))
                .foregroundStyle(IDETheme.accent)
            Text("Pick a problem to get started")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(IDETheme.textPrimary)
            Text("Filter by company or topic on the left, then open a problem.\nThe assistant will help you pick an approach and write it up.")
                .multilineTextAlignment(.center)
                .font(.system(size: 12))
                .foregroundStyle(IDETheme.textSecondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(IDETheme.background)
    }
}
