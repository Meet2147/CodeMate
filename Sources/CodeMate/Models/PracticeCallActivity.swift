import Foundation
import GroupActivities

/// A SharePlay activity for practicing one DSA problem together over
/// FaceTime, one-on-one. GroupActivities piggybacks on an existing FaceTime
/// call for signaling + audio/video -- CodeMate never runs its own calling
/// backend, which is what makes this buildable without a server.
struct PracticeCallActivity: GroupActivity {
    var problemId: String
    var problemTitle: String

    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.type = .learnTogether
        metadata.title = "Practice: \(problemTitle)"
        metadata.subtitle = "Solve it together on CodeMate"
        metadata.supportsContinuationOnTV = false
        return metadata
    }
}

/// A minimal message synced between the two participants so both sides see
/// the same code as it's typed. Deliberately simple (last-write-wins, no
/// operational-transform/CRDT merge) -- fine for two people talking over
/// FaceTime and taking turns, not intended for true concurrent editing.
struct PracticeCallCodeUpdate: Codable {
    var code: String
    var language: String
}
