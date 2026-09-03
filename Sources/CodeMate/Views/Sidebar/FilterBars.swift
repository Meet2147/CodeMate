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

/// Compact, single-row company filter for the narrow IDE sidebar -- a
/// dropdown menu (like TopicFilterMenu) plus small chips for only the
/// *selected* companies, instead of always showing all 10 as a 4-row grid.
struct CompanyFilterMenu: View {
    @Binding var selected: Set<Company>
    var lockedCompanies: Set<Company> = []
    var onLockedTap: (Company) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TARGET COMPANY")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(IDETheme.textSecondary)
                .kerning(0.5)

            Menu {
                ForEach(Company.allCases) { company in
                    let isLocked = lockedCompanies.contains(company)
                    Button {
                        if isLocked {
                            onLockedTap(company)
                        } else if selected.contains(company) {
                            selected.remove(company)
                        } else {
                            selected.insert(company)
                        }
                    } label: {
                        Label(isLocked ? "\(company.rawValue) (Pro)" : company.rawValue,
                              systemImage: isLocked ? "lock.fill" : (selected.contains(company) ? "checkmark.circle.fill" : "circle"))
                    }
                }
                if !selected.isEmpty {
                    Divider()
                    Button("Clear companies") { selected.removeAll() }
                }
            } label: {
                HStack {
                    Image(systemName: "building.2").font(.system(size: 11))
                    Text(selected.isEmpty ? "All companies" : "\(selected.count) selected")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 9))
                }
                .foregroundStyle(IDETheme.textPrimary)
            }
            .menuStyle(.borderlessButton)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 5).fill(IDETheme.inputBackground))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(IDETheme.border, lineWidth: 1))

            if !selected.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(selected).sorted(by: { $0.rawValue < $1.rawValue })) { company in
                            HStack(spacing: 4) {
                                Circle().fill(CMTheme.companyColor(company)).frame(width: 6, height: 6)
                                Text(company.initials).font(.system(size: 10, weight: .semibold, design: .rounded))
                                Image(systemName: "xmark").font(.system(size: 7, weight: .bold))
                            }
                            .foregroundStyle(IDETheme.textPrimary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                            .contentShape(Capsule())
                            .onTapGesture { selected.remove(company) }
                        }
                    }
                }
            }
        }
    }
}

struct DifficultyFilterBar: View {
    @Binding var selected: Set<Difficulty>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DIFFICULTY")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(IDETheme.textSecondary)
                .kerning(0.5)
            HStack(spacing: 6) {
                ForEach(Difficulty.allCases) { difficulty in
                    let isOn = selected.contains(difficulty)
                    Text(difficulty.rawValue)
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .foregroundStyle(isOn ? .white : IDETheme.textPrimary)
                        .background(
                            Capsule().fill(isOn ? AnyShapeStyle(difficulty.color) : AnyShapeStyle(IDETheme.inputBackground))
                        )
                        .overlay(Capsule().stroke(isOn ? .clear : IDETheme.border, lineWidth: 1))
                        .onTapGesture {
                            if selected.contains(difficulty) { selected.remove(difficulty) } else { selected.insert(difficulty) }
                        }
                }
            }
        }
    }
}

struct TopicFilterMenu: View {
    @Binding var selected: Set<Topic>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TOPIC")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(IDETheme.textSecondary)
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
                    Image(systemName: "line.3.horizontal.decrease.circle").font(.system(size: 11))
                    Text(selected.isEmpty ? "All topics" : "\(selected.count) topic\(selected.count == 1 ? "" : "s") selected")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 9))
                }
                .foregroundStyle(IDETheme.textPrimary)
            }
            .menuStyle(.borderlessButton)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 5).fill(IDETheme.inputBackground))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(IDETheme.border, lineWidth: 1))
        }
    }
}
