import SwiftUI

/// First-launch flow: pick the companies you're interviewing with, so the
/// Practice and LLD/HLD tabs open already filtered to the questions most
/// commonly asked there. Skippable, and changeable later from Settings.
struct OnboardingView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppPreferences.self) private var prefs
    @State private var selected: Set<Company> = []

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(spacing: 10) {
                Image(systemName: "curlybraces.square.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(CMTheme.accent)
                Text("Welcome to CodeMate")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(CMTheme.textPrimary(scheme))
                Text("Which companies are you interviewing with?\nWe'll surface the DSA and system-design questions most frequently asked there first -- you can change this anytime in Settings.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 13))
                    .foregroundStyle(CMTheme.textSecondary(scheme))
                    .frame(maxWidth: 520)
            }
            .padding(.bottom, 28)

            ScrollView {
                CompanyPickerGrid(selected: $selected)
                    .frame(maxWidth: 720)
                    .padding(.horizontal, 4)
            }
            .frame(maxHeight: 420)

            HStack(spacing: 12) {
                Button("Select all") { withAnimation { selected = Set(Company.allCases) } }
                    .buttonStyle(NeumorphicButtonStyle())
                Button("Skip for now") { finish(with: []) }
                    .buttonStyle(NeumorphicButtonStyle())
                Spacer()
                Text(selected.isEmpty ? "Pick at least one to personalize your list" : "\(selected.count) selected")
                    .font(.system(size: 11))
                    .foregroundStyle(CMTheme.textSecondary(scheme))
                Button("Continue") { finish(with: selected) }
                    .buttonStyle(NeumorphicButtonStyle(prominent: true))
                    .disabled(selected.isEmpty)
            }
            .padding(.top, 22)
            .frame(maxWidth: 720)

            Spacer(minLength: 24)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CMTheme.base(scheme).ignoresSafeArea())
    }

    private func finish(with companies: Set<Company>) {
        prefs.targetCompanies = companies
        withAnimation(.easeInOut(duration: 0.25)) {
            prefs.hasOnboarded = true
        }
    }
}

/// Reusable multi-select grid of company cards, shared by onboarding and
/// the "Change target companies" sheet in Settings.
struct CompanyPickerGrid: View {
    @Binding var selected: Set<Company>
    private let columns = [GridItem(.adaptive(minimum: 210, maximum: 260), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Company.allCases) { company in
                CompanyCard(company: company, isSelected: selected.contains(company)) {
                    if selected.contains(company) { selected.remove(company) } else { selected.insert(company) }
                }
            }
        }
    }
}

private struct CompanyCard: View {
    @Environment(\.colorScheme) private var scheme
    let company: Company
    let isSelected: Bool
    let toggle: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(CMTheme.companyColor(company).gradient)
                .frame(width: 34, height: 34)
                .overlay(
                    Text(company.initials.prefix(2))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(company.rawValue)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(CMTheme.textPrimary(scheme))
                    .lineLimit(1)
                Text(company.blurb)
                    .font(.system(size: 10))
                    .foregroundStyle(CMTheme.textSecondary(scheme))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? CMTheme.success : CMTheme.textSecondary(scheme).opacity(0.5))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: CMTheme.smallCornerRadius, style: .continuous)
                .fill(CMTheme.base(scheme))
                .shadow(color: CMTheme.shadowDark(scheme), radius: isSelected ? 2 : 4, x: isSelected ? 1.5 : 3, y: isSelected ? 1.5 : 3)
                .shadow(color: CMTheme.shadowLight(scheme), radius: isSelected ? 2 : 4, x: isSelected ? -1.5 : -3, y: isSelected ? -1.5 : -3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CMTheme.smallCornerRadius, style: .continuous)
                .stroke(isSelected ? CMTheme.accent : CMTheme.hairline(scheme), lineWidth: isSelected ? 2 : 1)
        )
        .brightness(isHovering && !isSelected ? 0.03 : 0)
        .scaleEffect(isHovering && !isSelected ? 1.01 : 1.0)
        .contentShape(RoundedRectangle(cornerRadius: CMTheme.smallCornerRadius))
        .onTapGesture { withAnimation(.easeOut(duration: 0.12)) { toggle() } }
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}
