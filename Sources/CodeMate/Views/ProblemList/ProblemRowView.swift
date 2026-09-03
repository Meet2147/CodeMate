import SwiftUI

struct ProblemRowView: View {
    @Environment(\.colorScheme) private var scheme
    let problem: Problem
    let status: SolveStatus
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            statusIcon
            VStack(alignment: .leading, spacing: 5) {
                Text(problem.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(CMTheme.textPrimary(scheme))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(problem.difficulty.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(problem.difficulty.color)
                    Text("·")
                        .foregroundStyle(CMTheme.textSecondary(scheme))
                    Text(problem.topics.first?.rawValue ?? "")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(CMTheme.textSecondary(scheme))
                        .lineLimit(1)
                }
                HStack(spacing: 4) {
                    ForEach(problem.companies) { company in
                        Circle()
                            .fill(CMTheme.companyColor(company))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: CMTheme.smallCornerRadius, style: .continuous)
                .fill(CMTheme.base(scheme))
                .shadow(color: CMTheme.shadowDark(scheme), radius: isSelected ? 3 : 6,
                        x: isSelected ? 2 : 5, y: isSelected ? 2 : 5)
                .shadow(color: CMTheme.shadowLight(scheme), radius: isSelected ? 3 : 6,
                        x: isSelected ? -2 : -5, y: isSelected ? -2 : -5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CMTheme.smallCornerRadius, style: .continuous)
                .stroke(isSelected ? CMTheme.accent : .clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder private var statusIcon: some View {
        switch status {
        case .solved:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(CMTheme.success)
        case .inProgress:
            Image(systemName: "circle.lefthalf.filled").foregroundStyle(CMTheme.warning)
        case .notStarted:
            Image(systemName: "circle").foregroundStyle(CMTheme.textSecondary(scheme))
        }
    }
}
