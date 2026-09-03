import SwiftUI

struct CompanyFilterBar: View {
    @Environment(\.colorScheme) private var scheme
    @Binding var selected: Set<Company>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TARGET COMPANY")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(CMTheme.textSecondary(scheme))
                .kerning(0.5)
            HStack(spacing: 8) {
                ForEach(Company.allCases) { company in
                    let isOn = selected.contains(company)
                    Text(company.initials)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(isOn ? .white : CMTheme.textPrimary(scheme))
                        .background(
                            Capsule().fill(isOn ? AnyShapeStyle(CMTheme.companyColor(company).gradient) : AnyShapeStyle(CMTheme.base(scheme)))
                                .shadow(color: CMTheme.shadowDark(scheme), radius: 4, x: 3, y: 3)
                                .shadow(color: CMTheme.shadowLight(scheme), radius: 4, x: -3, y: -3)
                        )
                        .onTapGesture { toggle(company) }
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
