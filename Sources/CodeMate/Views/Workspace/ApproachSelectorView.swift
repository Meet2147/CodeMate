import SwiftUI

/// Lets the student compare candidate approaches (brute force -> optimal)
/// before writing code -- the app's answer to "help me pick an approach".
struct ApproachSelectorView: View {
    let problem: Problem
    @Binding var isExpanded: Bool
    @State private var selected: Approach?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.branch").foregroundStyle(CMTheme.accent)
                    Text("Choose an approach").font(.system(size: 12, weight: .bold)).foregroundStyle(IDETheme.textPrimary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down").font(.system(size: 10))
                        .foregroundStyle(IDETheme.textSecondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(problem.approaches) { approach in
                    approachCard(approach)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ideCard()
    }

    private func approachCard(_ approach: Approach) -> some View {
        let isSelected = selected == approach
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(approach.name).font(.system(size: 12, weight: .bold)).foregroundStyle(IDETheme.textPrimary)
                Spacer()
                Text(approach.timeComplexity)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(CMTheme.accent)
                Text(approach.spaceComplexity)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(IDETheme.textSecondary)
            }
            Text(approach.summary).font(.system(size: 11)).foregroundStyle(IDETheme.textSecondary)

            if isSelected {
                VStack(alignment: .leading, spacing: 4) {
                    Text("When to use: \(approach.whenToUse)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(IDETheme.textPrimary)
                    ForEach(Array(approach.steps.enumerated()), id: \.offset) { index, step in
                        Text("\(index + 1). \(step)").font(.system(size: 11)).foregroundStyle(IDETheme.textPrimary)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? CMTheme.accentSoft : Color.clear)
        )
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? CMTheme.accent.opacity(0.4) : .clear, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) { selected = isSelected ? nil : approach }
        }
    }
}

/// Progressive hint ladder: reveals one hint at a time so the student is
/// nudged rather than handed the answer immediately.
struct HintLadderView: View {
    let problem: Problem
    @Binding var hintsRevealed: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb").foregroundStyle(CMTheme.warning)
                Text("Hints").font(.system(size: 12, weight: .bold)).foregroundStyle(IDETheme.textPrimary)
                Spacer()
                Text("\(hintsRevealed)/\(problem.hints.count)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(IDETheme.textSecondary)
            }

            ForEach(Array(problem.hints.prefix(hintsRevealed).enumerated()), id: \.offset) { index, hint in
                Text("\(index + 1). \(hint)")
                    .font(.system(size: 11.5))
                    .foregroundStyle(IDETheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 5).fill(IDETheme.inputBackground))
            }

            if hintsRevealed < problem.hints.count {
                Button {
                    withAnimation { hintsRevealed += 1 }
                } label: {
                    Text(hintsRevealed == 0 ? "Reveal first hint" : "Reveal next hint")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(IDEButtonStyle())
            }
        }
        .ideCard()
    }
}
