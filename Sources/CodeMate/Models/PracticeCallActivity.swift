import Foundation
import GroupActivities

/// A SharePlay activity for a one-on-one "practice together" session.
/// GroupActivities piggybacks on an existing (or newly started) FaceTime
/// call for audio, video, and screen sharing -- CodeMate never runs its own
/// calling backend or builds its own camera/mic UI, which is what makes
/// this buildable without a server. FaceTime's own controls handle "camera
/// on or off" and screen sharing; CodeMate only needs to sync app state
/// (which problem each side is solving, and how it's going).
struct PracticeCallActivity: GroupActivity {
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.type = .learnTogether
        metadata.title = "CodeMate Practice Session"
        metadata.subtitle = "Pick a problem for each other, then solve live"
        metadata.supportsContinuationOnTV = false
        return metadata
    }
}

/// Sent by each participant to assign the *other* person a problem --
/// "you solve mine, I solve yours" rather than both staring at the same
/// one. Whichever assignment you receive becomes the problem you open.
struct ProblemAssignment: Codable, Equatable {
    var problemId: String
    var problemTitle: String
    var difficulty: String
}

/// A lightweight progress ping so each side can see how their partner is
/// doing without exposing raw code -- this is a friendly challenge (each
/// person solving their own assigned problem), not shared pair-programming
/// on one problem, so code itself is deliberately never synced.
struct PracticeStatusUpdate: Codable, Equatable {
    var status: String // matches SolveStatus.rawValue
    var attempts: Int
}
