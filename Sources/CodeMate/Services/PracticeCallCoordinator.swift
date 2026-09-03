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

/// Owns the lifecycle of a one-on-one SharePlay practice session for a
/// single problem: starting/joining the GroupActivity, tracking connected
/// participants, and relaying code updates between the two participants.
/// Audio/video themselves are handled entirely by FaceTime once the
/// GroupActivity is active -- CodeMate only needs to sync app state.
///
/// BETA: this is real, compiling SharePlay integration, but exercising it
/// end-to-end needs two Macs on an actual FaceTime call -- it hasn't been
/// run against a live session in this environment.
@Observable
final class PracticeCallCoordinator {
    private(set) var state: PracticeCallState = .idle
    private(set) var incomingCode: PracticeCallCodeUpdate?
    var lastError: String?

    private var groupSession: GroupSession<PracticeCallActivity>?
    private var messenger: GroupSessionMessenger?
    private var sessionTask: Task<Void, Never>?
    private var stateTask: Task<Void, Never>?
    private var participantsTask: Task<Void, Never>?
    private var messageTask: Task<Void, Never>?

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
        messageTask?.cancel()
    }

    /// Starts (or joins, if a friend already started one) a practice call
    /// for this problem. Requires an active FaceTime call to actually share
    /// audio/video -- SharePlay activation surfaces that prompt itself.
    func startOrJoin(problemId: String, problemTitle: String) {
        Task {
            let activity = PracticeCallActivity(problemId: problemId, problemTitle: problemTitle)
            do {
                _ = try await activity.activate()
            } catch {
                await MainActor.run { self.lastError = error.localizedDescription }
            }
        }
    }

    func leave() {
        groupSession?.leave()
        teardown()
    }

    func sendCodeUpdate(code: String, language: String) {
        guard let messenger else { return }
        Task {
            try? await messenger.send(PracticeCallCodeUpdate(code: code, language: language))
        }
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

        messageTask?.cancel()
        messageTask = Task { [weak self] in
            for await (update, _) in messenger.messages(of: PracticeCallCodeUpdate.self) {
                self?.incomingCode = update
            }
        }

        session.join()
    }

    private func teardown() {
        state = .ended
        stateTask?.cancel()
        participantsTask?.cancel()
        messageTask?.cancel()
        groupSession = nil
        messenger = nil
    }
}
