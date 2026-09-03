import SwiftUI

struct SystemDesignHomeView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppPreferences.self) private var prefs
    @State private var selectedScope: DesignScope?
    @State private var selectedCompanies: Set<Company> = []
    @State private var selectedId: String?
    @State private var hasSeededFromPreferences = false

    private var filtered: [SystemDesignQuestion] {
        let base = SystemDesignBank.all.filter { q in
            (selectedScope == nil || q.scope == selectedScope) &&
            (selectedCompanies.isEmpty || !selectedCompanies.isDisjoint(with: q.companies))
        }
        guard !selectedCompanies.isEmpty else { return base }
        return base.sorted { a, b in
            let aMatches = selectedCompanies.intersection(a.companies).count
            let bMatches = selectedCompanies.intersection(b.companies).count
            if aMatches != bMatches { return aMatches > bMatches }
            return a.difficulty < b.difficulty
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LLD / HLD")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(CMTheme.textPrimary(scheme))
                    if selectedCompanies.count == 1, let company = selectedCompanies.first {
                        Text("Frequently asked at \(company.rawValue) -- \(filtered.count) questions")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(CMTheme.companyColor(company))
                    } else {
                        Text("\(filtered.count) system design questions")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(CMTheme.textSecondary(scheme))
                    }
                }

                Picker("Scope", selection: $selectedScope) {
                    Text("All").tag(DesignScope?.none)
                    ForEach(DesignScope.allCases) { scope in
                        Text(scope.shortLabel).tag(DesignScope?.some(scope))
                    }
                }
                .pickerStyle(.segmented)

                CompanyFilterBar(selected: $selectedCompanies)

                Divider().padding(.vertical, 4)

                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filtered) { question in
                            DesignQuestionRow(question: question, isSelected: selectedId == question.id)
                                .onTapGesture { selectedId = question.id }
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
                if let id = selectedId, let question = SystemDesignBank.question(id: id) {
                    SystemDesignDetailView(question: question).id(question.id)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "square.on.square.dashed")
                            .font(.system(size: 44))
                            .foregroundStyle(CMTheme.accent)
                        Text("Pick a system design question")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(CMTheme.textPrimary(scheme))
                        Text("Work through requirements, entities, data model, and\ntrade-offs -- the assistant will coach you through each part.")
                            .multilineTextAlignment(.center)
                            .font(.system(size: 12))
                            .foregroundStyle(CMTheme.textSecondary(scheme))
                    }
                    .padding(40)
                    .neumorphicRaised()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            guard !hasSeededFromPreferences else { return }
            hasSeededFromPreferences = true
            selectedCompanies = prefs.targetCompanies
        }
    }
}

private struct DesignQuestionRow: View {
    @Environment(\.colorScheme) private var scheme
    let question: SystemDesignQuestion
    let isSelected: Bool
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Text(question.scope.shortLabel)
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(CMTheme.accentSoft))
                .foregroundStyle(CMTheme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text(question.title).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(CMTheme.textPrimary(scheme))
                HStack(spacing: 4) {
                    ForEach(question.companies) { c in Circle().fill(CMTheme.companyColor(c)).frame(width: 6, height: 6) }
                    Text(question.difficulty.rawValue).font(.system(size: 10, weight: .medium)).foregroundStyle(question.difficulty.color)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: CMTheme.smallCornerRadius, style: .continuous)
                .fill(CMTheme.base(scheme))
                .shadow(color: CMTheme.shadowDark(scheme), radius: isSelected ? 2 : 4, x: isSelected ? 1.5 : 3, y: isSelected ? 1.5 : 3)
                .shadow(color: CMTheme.shadowLight(scheme), radius: isSelected ? 2 : 4, x: isSelected ? -1.5 : -3, y: isSelected ? -1.5 : -3)
                .overlay(
                    RoundedRectangle(cornerRadius: CMTheme.smallCornerRadius, style: .continuous)
                        .strokeBorder(CMTheme.hairline(scheme), lineWidth: 1)
                )
        )
        .overlay(RoundedRectangle(cornerRadius: CMTheme.smallCornerRadius).stroke(isSelected ? CMTheme.accent : .clear, lineWidth: 2))
        .brightness(isHovering && !isSelected ? 0.03 : 0)
        .scaleEffect(isSelected ? 1.0 : (isHovering ? 1.008 : 1.0))
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

private struct SystemDesignDetailView: View {
    @Environment(\.colorScheme) private var scheme
    let question: SystemDesignQuestion
    @State private var showAssistant = true

    var body: some View {
        HSplitView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(question.title).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(CMTheme.textPrimary(scheme))
                        HStack(spacing: 6) {
                            ForEach(question.companies) { c in
                                Text(c.initials).font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(Capsule().fill(CMTheme.companyColor(c).opacity(0.18)))
                                    .foregroundStyle(CMTheme.companyColor(c))
                            }
                            Text(question.difficulty.rawValue).font(.system(size: 10, weight: .bold)).foregroundStyle(question.difficulty.color)
                        }
                        Text(question.prompt).font(.system(size: 13)).foregroundStyle(CMTheme.textPrimary(scheme))
                    }
                    .neumorphicRaised(padding: 14)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ASK THESE FIRST").font(.system(size: 10, weight: .bold)).foregroundStyle(CMTheme.textSecondary(scheme))
                        ForEach(question.clarifyingQuestions, id: \.self) { q in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "questionmark.circle").foregroundStyle(CMTheme.accent).font(.system(size: 11))
                                Text(q).font(.system(size: 12)).foregroundStyle(CMTheme.textPrimary(scheme))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .neumorphicRaised(padding: 14)

                    ForEach(question.sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.heading.uppercased()).font(.system(size: 10, weight: .bold)).foregroundStyle(CMTheme.textSecondary(scheme))
                            ForEach(section.bullets, id: \.self) { bullet in
                                Text("•  \(bullet)").font(.system(size: 12)).foregroundStyle(CMTheme.textPrimary(scheme))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .neumorphicRaised(padding: 14)
                    }
                }
                .padding(16)
            }
            .background(CMTheme.base(scheme))
            .frame(minWidth: 320)

            if showAssistant {
                AssistantPanelView(context: AssistantContext(designQuestion: question))
                    .frame(minWidth: 260, idealWidth: 300, maxWidth: 400)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
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
}
