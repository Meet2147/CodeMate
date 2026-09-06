import SwiftUI
import AppKit
import GroupActivities
import _GroupActivities_AppKit

/// Wraps AppKit's `GroupActivitySharingController` -- the system share
/// sheet for sending a SharePlay invite (Messages, AirDrop, etc.) when
/// there's no FaceTime call active yet. There's no SwiftUI-native API for
/// this on macOS, so it has to go through NSViewControllerRepresentable.
/// Accepting the invite on the other end starts the FaceTime call and
/// joins the shared session together.
struct GroupActivitySharingView: NSViewControllerRepresentable {
    let activity: PracticeCallActivity
    var onFinish: (GroupActivitySharingResult) -> Void

    func makeNSViewController(context: Context) -> GroupActivitySharingController {
        // The non-throwing preparationHandler initializer, rather than
        // `init(_:) throws`, so a bad activity can't crash the app --
        // PracticeCallActivity's init never actually throws.
        let controller = GroupActivitySharingController(preparationHandler: { activity })
        Task {
            let result = await controller.result
            await MainActor.run { onFinish(result) }
        }
        return controller
    }

    func updateNSViewController(_ nsViewController: GroupActivitySharingController, context: Context) {}
}
