import SwiftUI

/// A dense "file explorer" row -- deliberately not a card. Reads as a
/// list of source files, the way a real IDE's project navigator does.
struct ProblemRowView: View {
    let problem: Problem
    let status: SolveStatus
    let isSelected: Bool
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "curlybraces")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(problem.difficulty.color)
                .frame(width: 14)

            Text(fileName)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(isSelected ? .white : IDETheme.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 6)

            HStack(spacing: 3) {
                ForEach(problem.companies.prefix(3)) { company in
                    Circle().fill(CMTheme.companyColor(company)).frame(width: 5, height: 5)
                }
            }

            statusIcon
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.1), value: isHovering)
    }

    private var fileName: String {
        problem.id.replacingOccurrences(of: "-", with: "_") + ".swift"
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(isSelected ? IDETheme.accent : (isHovering ? Color.white.opacity(0.06) : Color.clear))
    }

    @ViewBuilder private var statusIcon: some View {
        switch status {
        case .solved:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(isSelected ? .white : CMTheme.success)
        case .inProgress:
            Image(systemName: "circle.lefthalf.filled")
                .font(.system(size: 10))
                .foregroundStyle(isSelected ? .white.opacity(0.85) : CMTheme.warning)
        case .notStarted:
            EmptyView()
        }
    }
}
