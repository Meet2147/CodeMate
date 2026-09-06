import Foundation
import Combine
import GroupActivities
import Observation

enum PracticeCallState: Equatable {
    case idle
    case waitingForFriend
    case connected(participantCount: Int)
    case ended
}

/// Owns the lifecycle of a one-on-one SharePlay "practice together" session:
/// starting/joining the GroupActivity, tracking connected participants, and
/// relaying problem assignments + progress pings between the two
/// participants. Audio, video (camera on/off), and screen sharing are all
/// handled by FaceTime itself once the GroupActivity is active -- CodeMate
/// only needs to sync its own app state on top of that call.
///
/// BETA: this is real, compiling SharePlay integration against a stable,
/// non-beta framework (GroupActivities has shipped since macOS 12), but
/// exercising it end-to-end needs two Macs on an actual FaceTime call --
/// it hasn't been run against a live session in this environment.
@Observable
final class PracticeCallCoordinator {
    private(set) var state: PracticeCallState = .idle
    /// The problem your partner assigned *you* -- this is what you solve.
    private(set) var problemAssignedToMe: ProblemAssignment?
    /// The problem you assigned your partner, for display ("they're solving X").
    private(set) var problemAssignedToPartner: ProblemAssignment?
    private(set) var partnerStatus: PracticeStatusUpdate?
    var lastError: String?
    /// Set when `start()` finds no FaceTime call already active. The view
    /// watches this and presents `GroupActivitySharingController` for it --
    /// that's the system share sheet (Messages/AirDrop/etc.) that lets you
    /// send an invite to someone with no existing call; accepting it starts
    /// the FaceTime call and joins the session together. This is the actual
    /// "give them a key" mechanism SharePlay supports -- there's no public
    /// API for an arbitrary join code independent of that invite.
    var pendingShareActivity: PracticeCallActivity?

    private var groupSession: GroupSession<PracticeCallActivity>?
    private var messenger: GroupSessionMessenger?
    private var sessionTask: Task<Void, Never>?
    private var stateTask: Task<Void, Never>?
    private var participantsTask: Task<Void, Never>?
    private var assignmentTask: Task<Void, Never>?
    private var statusTask: Task<Void, Never>?

    init() {
        sessionTask = Task { [weak self] in
            for await session in PracticeCallActivity.sessions() {
                self?.configure(session: session)
            }
        }
    }

    deinit {
        sessionTask?.cancel()
        stateTask?.cancel()
        participantsTask?.cancel()
        assignmentTask?.cancel()
        statusTask?.cancel()
    }

    var isActive: Bool {
        switch state {
        case .waitingForFriend, .connected: return true
        case .idle, .ended: return false
        }
    }

    /// Starts (or joins, if a friend already started one) a practice
    /// session.
    ///
    /// `prepareForActivation()` tells you which of two paths applies:
    /// - `.activationPreferred`: you're already on a FaceTime call, so
    ///   `activate()` just attaches the shared activity to it directly.
    /// - `.activationDisabled`: no active call. Setting
    ///   `pendingShareActivity` tells the view to present
    ///   `GroupActivitySharingController`, the system share sheet for
    ///   sending someone an invite (Messages, AirDrop, etc.) with no prior
    ///   call -- accepting it starts the FaceTime call and joins the
    ///   session in one step. That invite *is* the "key" a friend uses to
    ///   join; SharePlay has no separate arbitrary join-code concept.
    func start() {
        Task {
            let activity = PracticeCallActivity()
            switch await activity.prepareForActivation() {
            case .activationPreferred:
                do {
                    _ = try await activity.activate()
                } catch {
                    await MainActor.run { self.lastError = error.localizedDescription }
                }
            case .activationDisabled:
                await MainActor.run { self.pendingShareActivity = activity }
            case .cancelled:
                break
            @unknown default:
                do {
                    _ = try await activity.activate()
                } catch {
                    await MainActor.run { self.lastError = error.localizedDescription }
                }
            }
        }
    }

    func leave() {
        groupSession?.leave()
        teardown()
    }

    /// Tell your partner which problem *they* should solve.
    func assignProblem(_ problem: Problem) {
        let assignment = ProblemAssignment(problemId: problem.id, problemTitle: problem.title, difficulty: problem.difficulty.rawValue)
        problemAssignedToPartner = assignment
        guard let messenger else { return }
        Task { try? await messenger.send(assignment) }
    }

    func sendStatus(_ status: SolveStatus, attempts: Int) {
        guard let messenger else { return }
        let update = PracticeStatusUpdate(status: status.rawValue, attempts: attempts)
        Task { try? await messenger.send(update) }
    }

    private func configure(session: GroupSession<PracticeCallActivity>) {
        groupSession = session
        let messenger = GroupSessionMessenger(session: session, deliveryMode: .reliable)
        self.messenger = messenger

        stateTask?.cancel()
        stateTask = Task { [weak self] in
            for await sessionState in session.$state.values {
                guard let self else { return }
                switch sessionState {
                case .waiting:
                    self.state = .waitingForFriend
                case .joined:
                    self.state = .connected(participantCount: session.activeParticipants.count)
                case .invalidated:
                    self.teardown()
                @unknown default:
                    break
                }
            }
        }

        participantsTask?.cancel()
        participantsTask = Task { [weak self] in
            for await participants in session.$activeParticipants.values {
                guard let self, case .connected = self.state else { continue }
                self.state = .connected(participantCount: participants.count)
            }
        }

        assignmentTask?.cancel()
        assignmentTask = Task { [weak self] in
            for await (assignment, _) in messenger.messages(of: ProblemAssignment.self) {
                self?.problemAssignedToMe = assignment
            }
        }

        statusTask?.cancel()
        statusTask = Task { [weak self] in
            for await (status, _) in messenger.messages(of: PracticeStatusUpdate.self) {
                self?.partnerStatus = status
            }
        }

        session.join()
    }

    private func teardown() {
        state = .ended
        stateTask?.cancel()
        participantsTask?.cancel()
        assignmentTask?.cancel()
        statusTask?.cancel()
        groupSession = nil
        messenger = nil
    }
}
