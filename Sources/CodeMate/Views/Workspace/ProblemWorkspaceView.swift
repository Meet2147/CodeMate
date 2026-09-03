import SwiftUI
import SwiftData

struct ProblemWorkspaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allProgress: [ProblemProgress]

    let problem: Problem
    var onClose: (() -> Void)?

    @State private var code: String = ""
    @State private var language: ProgrammingLanguage = .swift
    @State private var showApproaches = false
    @State private var hintsRevealed = 0
    @State private var showAssistant = true
    @State private var runResult: RunResult?
    @State private var runError: String?
    @State private var isRunning = false

    private let runner = CodeRunnerService()

    private var progress: ProblemProgress? {
        allProgress.first { $0.problemId == problem.id }
    }

    private var fileName: String {
        problem.id.replacingOccurrences(of: "-", with: "_") + "." + language.fileExtension
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            HSplitView {
                statementColumn
                    .frame(minWidth: 260, idealWidth: 300, maxWidth: 420)

                editorColumn
                    .frame(minWidth: 320, idealWidth: 380)

                if showAssistant {
                    AssistantPanelView(
                        context: AssistantContext(problem: problem, language: language, currentCode: code,
                                                   hintsRevealedSoFar: hintsRevealed, lastRunOutput: runResult?.output)
                    )
                    .frame(minWidth: 260, idealWidth: 300, maxWidth: 400)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            statusBar
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
        .onAppear(perform: loadOrCreateProgress)
        .onChange(of: code) { _, newValue in persist { $0.savedCode = newValue; $0.status = newValue.isEmpty ? .notStarted : .inProgress } }
        .onChange(of: language) { _, newValue in persist { $0.language = newValue } }
    }

    // MARK: - Tab bar (one open "file" -- the problem being worked on)

    private var tabBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(problem.difficulty.color)
                Text(fileName)
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundStyle(IDETheme.textPrimary)
                if let onClose {
                    Button { onClose() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
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

    // MARK: - Status bar

    private var statusBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Circle().fill(problem.difficulty.color).frame(width: 6, height: 6)
                Text(problem.difficulty.rawValue)
            }
            Text(language.rawValue)
            if let topic = problem.topics.first {
                Text(topic.rawValue)
            }
            Spacer()
            if isRunning {
                HStack(spacing: 4) { ProgressView().controlSize(.mini); Text("Running…") }
            } else if let result = runResult {
                Text(result.exitCode == 0 ? "Exit 0 · \(result.durationMs)ms" : "Exit \(result.exitCode) · \(result.durationMs)ms")
            }
        }
        .font(.system(size: 10.5, weight: .medium))
        .foregroundStyle(IDETheme.statusBarText)
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(IDETheme.statusBarBackground)
    }

    // MARK: - Left column: problem statement

    private var statementColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(problem.title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(IDETheme.textPrimary)
                        Spacer()
                        Text(problem.difficulty.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(problem.difficulty.color)
                    }
                    HStack(spacing: 6) {
                        ForEach(problem.companies) { company in
                            Text(company.initials)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(Capsule().fill(CMTheme.companyColor(company).opacity(0.22)))
                                .foregroundStyle(CMTheme.companyColor(company))
                        }
                        Text("~\(problem.estimatedMinutes) min")
                            .font(.system(size: 10))
                            .foregroundStyle(IDETheme.textSecondary)
                    }
                }
                .ideCard()

                VStack(alignment: .leading, spacing: 10) {
                    Text("PROBLEM").font(.system(size: 10, weight: .bold)).foregroundStyle(IDETheme.textSecondary)
                    Text(problem.prompt).font(.system(size: 12.5)).foregroundStyle(IDETheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .ideCard()

                if !problem.examples.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("EXAMPLES").font(.system(size: 10, weight: .bold)).foregroundStyle(IDETheme.textSecondary)
                        ForEach(problem.examples) { example in
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Input: \(example.input)").font(.system(size: 11.5, design: .monospaced)).foregroundStyle(IDETheme.textPrimary)
                                Text("Output: \(example.output)").font(.system(size: 11.5, design: .monospaced)).foregroundStyle(CMTheme.success)
                                if let explanation = example.explanation {
                                    Text(explanation).font(.system(size: 11)).foregroundStyle(IDETheme.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(9)
                            .background(RoundedRectangle(cornerRadius: 5).fill(IDETheme.inputBackground))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .ideCard()
                }

                if !problem.constraints.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CONSTRAINTS").font(.system(size: 10, weight: .bold)).foregroundStyle(IDETheme.textSecondary)
                        ForEach(problem.constraints, id: \.self) { constraint in
                            Text("•  \(constraint)").font(.system(size: 11.5, design: .monospaced)).foregroundStyle(IDETheme.textPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .ideCard()
                }

                ApproachSelectorView(problem: problem, isExpanded: $showApproaches)

                HintLadderView(problem: problem, hintsRevealed: $hintsRevealed)

                if let followUp = problem.followUp {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.turn.down.right").foregroundStyle(IDETheme.accent)
                        Text(followUp).font(.system(size: 12, weight: .medium)).foregroundStyle(IDETheme.textPrimary)
                    }
                    .ideCard(padding: 12)
                }
            }
            .padding(16)
        }
        .background(IDETheme.sidebarBackground)
    }

    // MARK: - Middle column: editor + run

    private var editorColumn: some View {
        VStack(spacing: 10) {
            HStack {
                Picker("Language", selection: $language) {
                    ForEach(ProgrammingLanguage.allCases) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)

                Spacer()

                Button {
                    hintsRevealed = 0
                    code = problem.starterCode[language] ?? Self.genericStarter(for: language)
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(IDEButtonStyle())

                Button {
                    runCode()
                } label: {
                    if isRunning {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Run", systemImage: "play.fill")
                    }
                }
                .buttonStyle(IDEButtonStyle(tint: CMTheme.success, prominent: true))
                .disabled(isRunning || !language.isLocallyRunnable)
            }
            .padding([.horizontal, .top], 14)

            CodeEditorView(text: $code)
                .background(RoundedRectangle(cornerRadius: IDETheme.cornerRadius).fill(IDETheme.inputBackground))
                .overlay(RoundedRectangle(cornerRadius: IDETheme.cornerRadius).stroke(IDETheme.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: IDETheme.cornerRadius))
                .padding(.horizontal, 14)

            outputPane
                .padding([.horizontal, .bottom], 14)
                .frame(height: 150)
        }
        .background(IDETheme.background)
    }

    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("OUTPUT").font(.system(size: 10, weight: .bold)).foregroundStyle(IDETheme.textSecondary)
                Spacer()
                if let result = runResult {
                    Text(result.exitCode == 0 ? "Exit 0 · \(result.durationMs)ms" : "Exit \(result.exitCode) · \(result.durationMs)ms")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(result.exitCode == 0 ? CMTheme.success : CMTheme.danger)
                }
            }
            ScrollView {
                Text(runError ?? runResult?.output ?? (language.isLocallyRunnable ? "Run your code to see output here." : "\(language.rawValue) runs via an external judge -- local execution isn't wired up for it yet."))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(runError != nil ? CMTheme.danger : IDETheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: IDETheme.cornerRadius).fill(IDETheme.inputBackground))
        .overlay(RoundedRectangle(cornerRadius: IDETheme.cornerRadius).stroke(IDETheme.border, lineWidth: 1))
    }

    private func runCode() {
        isRunning = true
        runError = nil
        Task {
            do {
                let result = try await runner.run(code: code, language: language)
                await MainActor.run {
                    runResult = result
                    isRunning = false
                    if result.exitCode == 0 { persist { $0.status = .solved; $0.attempts += 1 } }
                    else { persist { $0.attempts += 1 } }
                }
            } catch {
                await MainActor.run {
                    runError = error.localizedDescription
                    isRunning = false
                }
            }
        }
    }

    // MARK: - Persistence

    private func loadOrCreateProgress() {
        if let existing = progress {
            code = existing.savedCode.isEmpty ? (problem.starterCode[existing.language] ?? Self.genericStarter(for: existing.language)) : existing.savedCode
            language = existing.language
            hintsRevealed = existing.hintsRevealed
        } else {
            let newProgress = ProblemProgress(problemId: problem.id)
            modelContext.insert(newProgress)
            code = problem.starterCode[.swift] ?? Self.genericStarter(for: .swift)
        }
    }

    private func persist(_ mutate: (ProblemProgress) -> Void) {
        guard let existing = progress else { return }
        mutate(existing)
        existing.lastOpened = .now
        existing.hintsRevealed = hintsRevealed
    }

    static func genericStarter(for language: ProgrammingLanguage) -> String {
        "// Write your \(language.rawValue) solution here\n"
    }
}
