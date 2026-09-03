import SwiftUI

struct CompanyFilterBar: View {
    @Environment(\.colorScheme) private var scheme
    @Binding var selected: Set<Company>
    /// Companies the current plan doesn't include. Locked chips show a lock
    /// glyph and trigger `onLockedTap` instead of toggling. Empty by default
    /// (used as-is by onboarding/Settings, where every company is browsable).
    var lockedCompanies: Set<Company> = []
    var onLockedTap: (Company) -> Void = { _ in }

    private let columns = [GridItem(.adaptive(minimum: 64, maximum: 90), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("TARGET COMPANY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(CMTheme.textSecondary(scheme))
                    .kerning(0.5)
                Spacer()
                if !selected.isEmpty {
                    Button("Clear") { withAnimation(.easeOut(duration: 0.12)) { selected.removeAll() } }
                        .buttonStyle(.plain)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(CMTheme.accent)
                }
            }
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(Company.allCases) { company in
                    let isOn = selected.contains(company)
                    let isLocked = lockedCompanies.contains(company)
                    HStack(spacing: 3) {
                        if isLocked {
                            Image(systemName: "lock.fill").font(.system(size: 8))
                        }
                        Text(company.initials)
                    }
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(isLocked ? CMTheme.textSecondary(scheme) : (isOn ? .white : CMTheme.textPrimary(scheme)))
                        .background(
                            Capsule().fill(isOn && !isLocked ? AnyShapeStyle(CMTheme.companyColor(company).gradient) : AnyShapeStyle(CMTheme.base(scheme)))
                                .shadow(color: CMTheme.shadowDark(scheme), radius: 3, x: 2, y: 2)
                                .shadow(color: CMTheme.shadowLight(scheme), radius: 3, x: -2, y: -2)
                        )
                        .opacity(isLocked ? 0.6 : 1.0)
                        .contentShape(Capsule())
                        .onTapGesture {
                            if isLocked {
                                onLockedTap(company)
                            } else {
                                withAnimation(.easeOut(duration: 0.12)) { toggle(company) }
                            }
                        }
                }
            }
        }
    }

    private func toggle(_ company: Company) {
        if selected.contains(company) { selected.remove(company) } else { selected.insert(company) }
    }
}

struct DifficultyFilterBar: View {
    @Environment(\.colorScheme) private var scheme
    @Binding var selected: Set<Difficulty>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DIFFICULTY")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(CMTheme.textSecondary(scheme))
                .kerning(0.5)
            HStack(spacing: 8) {
                ForEach(Difficulty.allCases) { difficulty in
                    let isOn = selected.contains(difficulty)
                    Text(difficulty.rawValue)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(isOn ? .white : CMTheme.textPrimary(scheme))
                        .background(
                            Capsule().fill(isOn ? AnyShapeStyle(difficulty.color.gradient) : AnyShapeStyle(CMTheme.base(scheme)))
                                .shadow(color: CMTheme.shadowDark(scheme), radius: 4, x: 3, y: 3)
                                .shadow(color: CMTheme.shadowLight(scheme), radius: 4, x: -3, y: -3)
                        )
                        .onTapGesture {
                            if selected.contains(difficulty) { selected.remove(difficulty) } else { selected.insert(difficulty) }
                        }
                }
            }
        }
    }
}

struct TopicFilterMenu: View {
    @Environment(\.colorScheme) private var scheme
    @Binding var selected: Set<Topic>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TOPIC")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(CMTheme.textSecondary(scheme))
                .kerning(0.5)
            Menu {
                ForEach(Topic.allCases) { topic in
                    Button {
                        if selected.contains(topic) { selected.remove(topic) } else { selected.insert(topic) }
                    } label: {
                        Label(topic.rawValue, systemImage: selected.contains(topic) ? "checkmark.circle.fill" : "circle")
                    }
                }
                if !selected.isEmpty {
                    Divider()
                    Button("Clear topics") { selected.removeAll() }
                }
            } label: {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(selected.isEmpty ? "All topics" : "\(selected.count) topic\(selected.count == 1 ? "" : "s") selected")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 9))
                }
                .foregroundStyle(CMTheme.textPrimary(scheme))
            }
            .menuStyle(.borderlessButton)
            .neumorphicInset(radius: CMTheme.smallCornerRadius, padding: 10)
        }
    }
}
