import SwiftUI

struct ProblemRowView: View {
    @Environment(\.colorScheme) private var scheme
    let problem: Problem
    let status: SolveStatus
    let isSelected: Bool
    @State private var isHovering = false

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
                .shadow(color: CMTheme.shadowDark(scheme), radius: isSelected ? 2 : 4,
                        x: isSelected ? 1.5 : 3, y: isSelected ? 1.5 : 3)
                .shadow(color: CMTheme.shadowLight(scheme), radius: isSelected ? 2 : 4,
                        x: isSelected ? -1.5 : -3, y: isSelected ? -1.5 : -3)
                .overlay(
                    RoundedRectangle(cornerRadius: CMTheme.smallCornerRadius, style: .continuous)
                        .strokeBorder(CMTheme.hairline(scheme), lineWidth: 1)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CMTheme.smallCornerRadius, style: .continuous)
                .stroke(isSelected ? CMTheme.accent : .clear, lineWidth: 2)
        )
        .brightness(isHovering && !isSelected ? 0.03 : 0)
        .scaleEffect(isSelected ? 1.0 : (isHovering ? 1.008 : 1.0))
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .animation(.easeOut(duration: 0.15), value: isSelected)
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
