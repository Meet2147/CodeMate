import SwiftUI

struct SystemDesignHomeView: View {
    @Environment(AppPreferences.self) private var prefs
    @Environment(StoreManager.self) private var store
    @State private var selectedScope: DesignScope?
    @State private var selectedCompanies: Set<Company> = []
    @State private var selectedId: String?
    @State private var hasSeededFromPreferences = false
    @State private var showsPaywall = false

    private var lockedCompanies: Set<Company> {
        guard let maxCount = store.currentTier.maxTargetCompanies else { return [] }
        let ordered = Company.allCases.filter { prefs.targetCompanies.contains($0) }
        let base = ordered.isEmpty ? Array(Company.allCases.prefix(maxCount)) : ordered
        return Set(Company.allCases).subtracting(Set(base.prefix(maxCount)))
    }

    private var effectiveSelectedCompanies: Set<Company> {
        selectedCompanies.subtracting(lockedCompanies)
    }

    private var filtered: [SystemDesignQuestion] {
        let base = SystemDesignBank.all.filter { q in
            (selectedScope == nil || q.scope == selectedScope) &&
            (effectiveSelectedCompanies.isEmpty || !effectiveSelectedCompanies.isDisjoint(with: q.companies))
        }
        guard !effectiveSelectedCompanies.isEmpty else { return base }
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("LLD / HLD")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(IDETheme.textPrimary)
                    if effectiveSelectedCompanies.count == 1, let company = effectiveSelectedCompanies.first {
                        Text("Frequently asked at \(company.rawValue)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(CMTheme.companyColor(company))
                    } else {
                        Text("\(filtered.count) system design questions")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(IDETheme.textSecondary)
                    }
                }

                Picker("Scope", selection: $selectedScope) {
                    Text("All").tag(DesignScope?.none)
                    ForEach(DesignScope.allCases) { scope in
                        Text(scope.shortLabel).tag(DesignScope?.some(scope))
                    }
                }
                .pickerStyle(.segmented)

                CompanyFilterBar(selected: $selectedCompanies, lockedCompanies: lockedCompanies) { _ in
                    showsPaywall = true
                }

                HStack {
                    Text("EXPLORER").font(.system(size: 9.5, weight: .bold)).foregroundStyle(IDETheme.textTertiary).kerning(0.6)
                    Spacer()
                    Text("\(filtered.count)").font(.system(size: 9.5, weight: .semibold)).foregroundStyle(IDETheme.textTertiary)
                }
                .padding(.top, 2)

                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filtered) { question in
                            DesignQuestionRow(question: question, isSelected: selectedId == question.id)
                                .onTapGesture { selectedId = question.id }
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
                if let id = selectedId, let question = SystemDesignBank.question(id: id) {
                    SystemDesignDetailView(question: question, onClose: { selectedId = nil }).id(question.id)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "square.on.square.dashed")
                            .font(.system(size: 44))
                            .foregroundStyle(IDETheme.accent)
                        Text("Pick a system design question")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(IDETheme.textPrimary)
                        Text("Work through requirements, entities, data model, and\ntrade-offs -- the assistant will coach you through each part.")
                            .multilineTextAlignment(.center)
                            .font(.system(size: 12))
                            .foregroundStyle(IDETheme.textSecondary)
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(IDETheme.background)
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
}

private struct DesignQuestionRow: View {
    let question: SystemDesignQuestion
    let isSelected: Bool
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: question.scope == .lld ? "puzzlepiece" : "server.rack")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(question.difficulty.color)
                .frame(width: 14)

            Text(question.title)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(isSelected ? .white : IDETheme.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 6)

            HStack(spacing: 3) {
                ForEach(question.companies.prefix(3)) { c in
                    Circle().fill(CMTheme.companyColor(c)).frame(width: 5, height: 5)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(isSelected ? IDETheme.accent : (isHovering ? Color.white.opacity(0.06) : Color.clear))
        )
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.1), value: isHovering)
    }
}

private struct SystemDesignDetailView: View {
    let question: SystemDesignQuestion
    var onClose: (() -> Void)?
    @State private var showAssistant = true

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            HSplitView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(question.title).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(IDETheme.textPrimary)
                            HStack(spacing: 6) {
                                ForEach(question.companies) { c in
                                    Text(c.initials).font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 7).padding(.vertical, 3)
                                        .background(Capsule().fill(CMTheme.companyColor(c).opacity(0.22)))
                                        .foregroundStyle(CMTheme.companyColor(c))
                                }
                                Text(question.difficulty.rawValue).font(.system(size: 10, weight: .bold)).foregroundStyle(question.difficulty.color)
                            }
                            Text(question.prompt).font(.system(size: 12.5)).foregroundStyle(IDETheme.textPrimary)
                        }
                        .ideCard()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("ASK THESE FIRST").font(.system(size: 10, weight: .bold)).foregroundStyle(IDETheme.textSecondary)
                            ForEach(question.clarifyingQuestions, id: \.self) { q in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "questionmark.circle").foregroundStyle(IDETheme.accent).font(.system(size: 11))
                                    Text(q).font(.system(size: 12)).foregroundStyle(IDETheme.textPrimary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .ideCard()

                        ForEach(question.sections) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(section.heading.uppercased()).font(.system(size: 10, weight: .bold)).foregroundStyle(IDETheme.textSecondary)
                                ForEach(section.bullets, id: \.self) { bullet in
                                    Text("•  \(bullet)").font(.system(size: 12)).foregroundStyle(IDETheme.textPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .ideCard()
                        }
                    }
                    .padding(16)
                }
                .background(IDETheme.sidebarBackground)
                .frame(minWidth: 320)

                if showAssistant {
                    AssistantPanelView(context: AssistantContext(designQuestion: question))
                        .frame(minWidth: 260, idealWidth: 300, maxWidth: 400)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .background(IDETheme.background)
        .animation(.easeInOut(duration: 0.2), value: showAssistant)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showAssistant.toggle() }
                } label: {
                    Label("Assistant", systemImage: showAssistant ? "sparkles.rectangle.stack.fill" : "sparkles.rectangle.stack")
                }
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: question.scope == .lld ? "puzzlepiece" : "server.rack")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(question.difficulty.color)
                Text(question.id.replacingOccurrences(of: "-", with: "_") + ".md")
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundStyle(IDETheme.textPrimary)
                if let onClose {
                    Button { onClose() } label: {
                        Image(systemName: "xmark").font(.system(size: 8, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(IDETheme.textTertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(IDETheme.background)
            .overlay(Rectangle().fill(IDETheme.accent).frame(height: 2), alignment: .top)

            Spacer()
        }
        .background(IDETheme.elevatedBackground)
        .overlay(Rectangle().fill(IDETheme.border).frame(height: 1), alignment: .bottom)
    }
}
