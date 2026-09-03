import SwiftUI
import AppKit

/// A lightweight code editor: monospaced NSTextView with a synced line-number
/// gutter (NSRulerView) inside a scroll view. Not a full syntax-highlighting
/// engine -- kept intentionally simple and dependency-free for the MVP.
struct CodeEditorView: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let contentSize = scrollView.contentSize

        let textView = NSTextView(frame: NSRect(origin: .zero, size: contentSize))
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.delegate = context.coordinator
        textView.string = text
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false

        // Standard boilerplate for a scrollable, growable NSTextView --
        // without this the text view keeps its tiny default frame and
        // never properly tracks the scroll view, which makes clicks land
        // outside its real (degenerate) bounds and breaks typing entirely.
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude)

        // The editor is always-dark IDE chrome regardless of system
        // appearance, so force dark aqua + explicit fixed colors rather
        // than the dynamic NSColor.textColor/.secondaryLabelColor, which
        // track the real system setting and would otherwise mismatch the
        // forced-dark SwiftUI environment around it.
        textView.appearance = NSAppearance(named: .darkAqua)
        textView.drawsBackground = true
        textView.backgroundColor = NSColor(IDETheme.inputBackground)
        textView.textColor = NSColor(IDETheme.textPrimary)
        textView.insertionPointColor = NSColor(IDETheme.accent)

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.appearance = NSAppearance(named: .darkAqua)
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(IDETheme.inputBackground)

        let ruler = LineNumberRulerView(textView: textView)
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

        context.coordinator.textView = textView

        // Focus the editor as soon as it appears so typing works immediately.
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
        (nsView.verticalRulerView as? LineNumberRulerView)?.needsDisplay = true
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

/// Minimal line-number gutter.
final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?

    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 36
        NotificationCenter.default.addObserver(self, selector: #selector(contentDidChange),
                                                 name: NSText.didChangeNotification, object: textView)
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func contentDidChange() { needsDisplay = true }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        NSColor(IDETheme.inputBackground).setFill()
        rect.fill()

        guard let textView = textView, let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        let content = textView.string as NSString
        let visibleRect = textView.enclosingScrollView?.contentView.bounds ?? .zero
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        var lineNumber = content.substring(to: charRange.location).components(separatedBy: "\n").count
        var index = charRange.location

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10.5, weight: .regular),
            .foregroundColor: NSColor(IDETheme.textTertiary)
        ]

        while index < NSMaxRange(charRange) {
            let lineRange = content.lineRange(for: NSRange(location: index, length: 0))
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: lineRange.location)
            var lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
            lineRect.origin.y += textView.textContainerInset.height

            let numberString = "\(lineNumber)" as NSString
            let size = numberString.size(withAttributes: attrs)
            let drawRect = NSRect(x: ruleThickness - size.width - 8,
                                   y: lineRect.minY - visibleRect.minY,
                                   width: size.width, height: size.height)
            numberString.draw(in: drawRect, withAttributes: attrs)

            lineNumber += 1
            index = NSMaxRange(lineRange)
            if lineRange.length == 0 { break }
        }
    }
}
