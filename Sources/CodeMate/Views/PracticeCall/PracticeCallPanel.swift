import SwiftUI

/// The "Practice Together" panel: start/join a SharePlay session, assign
/// each other problems, and jump straight to whichever one your partner
/// picked for you. FaceTime itself carries audio, video (camera on/off is
/// FaceTime's own toggle), and screen sharing -- this panel only handles
/// the CodeMate-specific state layered on top of that call.
struct PracticeCallPanel: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(PracticeCallCoordinator.self) private var call
    @Environment(AppPreferences.self) private var prefs
    @Environment(LicenseManager.self) private var licenseManager

    @Binding var selectedProblemId: String?
    var currentProblem: Problem?

    @State private var showsPaywall = false
    @State private var assignSearch = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()

            switch call.state {
            case .idle:
                idleContent
            case .waitingForFriend:
                waitingContent
            case .connected(let count):
                connectedContent(count: count)
            case .ended:
                endedContent
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(width: 480, height: 580)
        .background(CMTheme.base(scheme))
        .sheet(isPresented: $showsPaywall) { PaywallView() }
        .sheet(item: shareActivityBinding) { wrapped in
            GroupActivitySharingView(activity: wrapped.activity) { _ in
                call.pendingShareActivity = nil
            }
            .frame(width: 420, height: 500)
        }
    }

    /// `pendingShareActivity` needs an `Identifiable` item for `.sheet(item:)`;
    /// PracticeCallActivity has no stable id of its own, so this binding just
    /// wraps it in one at the call site instead of making the model Identifiable
    /// for a single use.
    private var shareActivityBinding: Binding<IdentifiedActivity?> {
        Binding(
            get: { call.pendingShareActivity.map(IdentifiedActivity.init) },
            set: { call.pendingShareActivity = $0?.activity }
        )
    }

    private struct IdentifiedActivity: Identifiable {
        let id = UUID()
        let activity: PracticeCallActivity
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Practice Together")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(CMTheme.textPrimary(scheme))
                Text("One-on-one over FaceTime -- audio, video, and screen share are FaceTime's own controls.")
                    .font(.system(size: 11))
                    .foregroundStyle(CMTheme.textSecondary(scheme))
            }
            Spacer()
            Button("Close") { dismiss() }
                .buttonStyle(NeumorphicButtonStyle())
        }
    }

    // MARK: - Idle

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                bullet("Already on a FaceTime call? Starting attaches the session to it directly.")
                bullet("Not on a call yet? You'll get a share sheet -- send the invite over Messages, and your friend tapping it starts the call and joins in one step.")
                bullet("Once connected, each of you picks a problem for the *other* to solve.")
                bullet("Turn your camera on/off or share your screen anytime from FaceTime's own controls.")
                bullet("CodeMate only syncs which problem you're each solving and your progress -- never your raw code.")
            }

            if let limit = licenseManager.currentTier.practiceCallsPerMonth {
                Text("\(prefs.practiceCallsUsedThisMonth) of \(limit) practice calls used this month on \(licenseManager.currentTier.displayName).")
                    .font(.system(size: 10.5))
                    .foregroundStyle(CMTheme.textSecondary(scheme))
            } else {
                Text("Unlimited practice calls on \(licenseManager.currentTier.displayName).")
                    .font(.system(size: 10.5))
                    .foregroundStyle(CMTheme.textSecondary(scheme))
            }

            Button {
                if prefs.canStartPracticeCall(tier: licenseManager.currentTier) {
                    prefs.recordPracticeCallStarted()
                    call.start()
                } else {
                    showsPaywall = true
                }
            } label: {
                Label("Start Practice Session", systemImage: "video.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NeumorphicButtonStyle(prominent: true))

            if let error = call.lastError {
                Text(error).font(.system(size: 11)).foregroundStyle(CMTheme.danger)
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill").font(.system(size: 4)).padding(.top, 5).foregroundStyle(CMTheme.accent)
            Text(text).font(.system(size: 12)).foregroundStyle(CMTheme.textPrimary(scheme))
        }
    }

    // MARK: - Waiting

    private var waitingContent: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text("Waiting for your friend to join…")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CMTheme.textPrimary(scheme))
            Text("Make sure they're on the FaceTime call and have accepted the SharePlay prompt.")
                .font(.system(size: 11))
                .foregroundStyle(CMTheme.textSecondary(scheme))
                .multilineTextAlignment(.center)
            Button("Leave") { call.leave() }
                .buttonStyle(NeumorphicButtonStyle(tint: CMTheme.danger))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
    }

    // MARK: - Connected

    private func connectedContent(count: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Connected · \(count) participant\(count == 1 ? "" : "s")", systemImage: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CMTheme.success)

            if let assigned = call.problemAssignedToMe {
                VStack(alignment: .leading, spacing: 6) {
                    Text("YOUR PARTNER PICKED FOR YOU").font(.system(size: 9.5, weight: .bold)).foregroundStyle(CMTheme.textSecondary(scheme))
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(assigned.problemTitle).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(CMTheme.textPrimary(scheme))
                            Text(assigned.difficulty).font(.system(size: 10, weight: .semibold)).foregroundStyle(CMTheme.textSecondary(scheme))
                        }
                        Spacer()
                        Button("Open") {
                            selectedProblemId = assigned.problemId
                            dismiss()
                        }
                        .buttonStyle(NeumorphicButtonStyle(prominent: true))
                    }
                }
                .neumorphicInset(padding: 12)
            }

            if let partnerStatus = call.partnerStatus {
                HStack(spacing: 6) {
                    Image(systemName: partnerStatus.status == "solved" ? "checkmark.seal.fill" : "clock.fill")
                        .foregroundStyle(partnerStatus.status == "solved" ? CMTheme.success : CMTheme.warning)
                    Text(partnerStatus.status == "solved" ? "Your partner solved it!" : "Your partner is working on it (\(partnerStatus.attempts) run\(partnerStatus.attempts == 1 ? "" : "s") so far).")
                        .font(.system(size: 11.5))
                        .foregroundStyle(CMTheme.textPrimary(scheme))
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("PICK A PROBLEM FOR YOUR PARTNER").font(.system(size: 9.5, weight: .bold)).foregroundStyle(CMTheme.textSecondary(scheme))

                if let current = currentProblem {
                    Button {
                        call.assignProblem(current)
                    } label: {
                        Label("Assign \"\(current.title)\" (currently open)", systemImage: "arrow.up.forward.square")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(NeumorphicButtonStyle())
                }

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(CMTheme.textSecondary(scheme))
                    TextField("Or search all problems…", text: $assignSearch)
                        .textFieldStyle(.plain)
                }
                .neumorphicInset(padding: 8)

                if !assignSearch.isEmpty {
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(searchResults) { p in
                                HStack {
                                    Text(p.title).font(.system(size: 12)).foregroundStyle(CMTheme.textPrimary(scheme))
                                    Spacer()
                                    Text(p.difficulty.rawValue).font(.system(size: 10, weight: .semibold)).foregroundStyle(p.difficulty.color)
                                }
                                .padding(8)
                                .contentShape(Rectangle())
                                .onTapGesture { call.assignProblem(p); assignSearch = "" }
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                }

                if let assignedToPartner = call.problemAssignedToPartner {
                    Text("You assigned them: \(assignedToPartner.problemTitle)")
                        .font(.system(size: 10.5))
                        .foregroundStyle(CMTheme.textSecondary(scheme))
                }
            }

            Spacer()
            Button("Leave Session") { call.leave() }
                .buttonStyle(NeumorphicButtonStyle(tint: CMTheme.danger))
        }
    }

    private var searchResults: [Problem] {
        guard !assignSearch.isEmpty else { return [] }
        return ProblemBank.all.filter { $0.title.localizedCaseInsensitiveContains(assignSearch) }.prefix(8).map { $0 }
    }

    // MARK: - Ended

    private var endedContent: some View {
        VStack(spacing: 14) {
            Image(systemName: "phone.down.fill").font(.system(size: 30)).foregroundStyle(CMTheme.textSecondary(scheme))
            Text("Session ended.").font(.system(size: 13, weight: .medium)).foregroundStyle(CMTheme.textPrimary(scheme))
            Button("Start a New Session") { call.start() }
                .buttonStyle(NeumorphicButtonStyle(prominent: true))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
    }
}
