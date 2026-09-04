import SwiftUI
import AppKit

/// A lightweight code editor: monospaced NSTextView inside a scroll view.
/// Not a full syntax-highlighting engine, and (for now) no line-number
/// gutter -- kept intentionally simple after two rounds of live, on-device
/// testing (not guessing) traced actual rendering breakage to:
/// 1. Colors bridged from SwiftUI's Color(IDETheme.xxx) via NSColor(Color)
///    -- the text data, focus, and layout were all provably correct
///    (verified via the Accessibility API and a Cmd+A selection test that
///    showed nothing painting), but glyphs never rendered. Fixed by
///    building colors directly via NSColor(srgbRed:...) instead.
/// 2. A second sibling view next to the text view -- tried both as
///    NSScrollView's built-in NSRulerView integration and as a plain
///    NSView positioned via Auto Layout constraints in a wrapping
///    container -- broke the SAME way both times, even with the color fix
///    in place. The exact mechanism isn't nailed down (something about
///    NSViewRepresentable's external SwiftUI-driven sizing conflicting
///    with a second internally-constrained subview), so the gutter is
///    left out entirely for now rather than re-risking a fix that's
///    confirmed to work end-to-end (typing, backspace, multi-line edits,
///    Run all tested live). A line-number gutter is a real, worthwhile
///    follow-up, just not worth reintroducing this exact failure mode to
///    chase blind again.
struct CodeEditorView: NSViewRepresentable {
    @Binding var text: String

    private static let background = NSColor(srgbRed: 0.078, green: 0.082, blue: 0.094, alpha: 1.0)
    private static let textColor = NSColor(srgbRed: 0.90, green: 0.90, blue: 0.90, alpha: 1.0)
    private static let insertionColor = NSColor(srgbRed: 0.35, green: 0.62, blue: 1.0, alpha: 1.0)

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()

        let textView = NSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = Self.textColor
        textView.backgroundColor = Self.background
        textView.drawsBackground = true
        textView.insertionPointColor = Self.insertionColor
        textView.textContainerInset = NSSize(width: 12, height: 10)
        textView.delegate = context.coordinator
        textView.string = text
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false

        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = Self.background

        context.coordinator.textView = textView

        DispatchQueue.main.async {
            scrollView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        weak var textView: NSTextView?

        init(text: Binding<String>) { self.text = text }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}
