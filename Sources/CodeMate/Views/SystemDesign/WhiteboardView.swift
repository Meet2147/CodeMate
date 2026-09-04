import SwiftUI
import SwiftData
import AppKit

/// A lightweight, Excalidraw-style sketch surface for working through a
/// system design live: freehand pen, boxes, arrows, and text labels.
/// Not a general vector-graphics editor -- just enough to sketch
/// components and draw connections between them while talking it through
/// with the assistant. Persisted per question via SwiftData.
struct WhiteboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var documents: [WhiteboardDocument]
    let questionId: String

    @State private var elements: [WhiteboardElement] = []
    @State private var tool: WhiteboardTool = .pen
    @State private var color: Color = .white
    @State private var lineWidth: CGFloat = 2.5
    @State private var draftPoints: [CGPoint] = []
    @State private var draftStart: CGPoint?
    @State private var draftCurrent: CGPoint?
    @State private var pendingTextLocation: CGPoint?
    @State private var textDraft: String = ""
    @State private var hasLoaded = false

    private let palette: [Color] = [.white, .red, .orange, .yellow, .green, .cyan, .blue, .purple]

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            canvas
        }
        .background(IDETheme.background)
        .onAppear(perform: load)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            ForEach(WhiteboardTool.allCases) { t in
                Button {
                    tool = t
                    pendingTextLocation = nil
                } label: {
                    Image(systemName: t.symbol)
                        .frame(width: 26, height: 22)
                }
                .buttonStyle(IDEButtonStyle(tint: IDETheme.accent, prominent: tool == t))
            }

            Divider().frame(height: 18)

            HStack(spacing: 5) {
                ForEach(palette, id: \.self) { c in
                    Circle()
                        .fill(c)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Color.white, lineWidth: color == c ? 2 : 0))
                        .onTapGesture { color = c }
                }
            }

            Divider().frame(height: 18)

            Slider(value: $lineWidth, in: 1...8, step: 0.5).frame(width: 90)
            Text("\(Int(lineWidth))pt").font(.system(size: 10)).foregroundStyle(IDETheme.textSecondary).frame(width: 24)

            Spacer()

            Button {
                if !elements.isEmpty { elements.removeLast() }
                save()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(IDEButtonStyle())
            .disabled(elements.isEmpty)

            Button {
                elements.removeAll()
                save()
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .buttonStyle(IDEButtonStyle(tint: CMTheme.danger))
            .disabled(elements.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(IDETheme.elevatedBackground)
        .overlay(Rectangle().fill(IDETheme.border).frame(height: 1), alignment: .bottom)
    }

    private var canvas: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    for element in elements { draw(element, in: &context) }
                    if let draft = currentDraftElement { draw(draft, in: &context) }
                }
                .background(IDETheme.inputBackground)
                .contentShape(Rectangle())
                .gesture(drawGesture(in: geo.size))

                if let location = pendingTextLocation {
                    textEntryBox(at: location, canvasSize: geo.size)
                }
            }
        }
    }

    private var currentDraftElement: WhiteboardElement? {
        switch tool {
        case .pen:
            guard !draftPoints.isEmpty else { return nil }
            return WhiteboardElement(kind: tool.rawValue, points: draftPoints, colorHex: color.hexString, lineWidth: lineWidth)
        case .rectangle, .arrow:
            guard let start = draftStart, let current = draftCurrent else { return nil }
            return WhiteboardElement(kind: tool.rawValue, points: [start, current], colorHex: color.hexString, lineWidth: lineWidth)
        case .text, .eraser:
            return nil
        }
    }

    private func drawGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                switch tool {
                case .pen:
                    draftPoints.append(value.location)
                case .rectangle, .arrow:
                    if draftStart == nil { draftStart = value.location }
                    draftCurrent = value.location
                case .eraser:
                    erase(near: value.location)
                case .text:
                    break
                }
            }
            .onEnded { value in
                switch tool {
                case .pen:
                    if draftPoints.count > 1 {
                        elements.append(WhiteboardElement(kind: tool.rawValue, points: draftPoints, colorHex: color.hexString, lineWidth: lineWidth))
                    }
                    draftPoints = []
                    save()
                case .rectangle, .arrow:
                    if let start = draftStart {
                        elements.append(WhiteboardElement(kind: tool.rawValue, points: [start, value.location], colorHex: color.hexString, lineWidth: lineWidth))
                    }
                    draftStart = nil
                    draftCurrent = nil
                    save()
                case .eraser:
                    save()
                case .text:
                    pendingTextLocation = value.location
                    textDraft = ""
                }
            }
    }

    private func erase(near point: CGPoint) {
        let threshold: CGFloat = 14
        elements.removeAll { element in
            element.points.contains { $0.distance(to: point) < threshold }
        }
    }

    /// A proper multi-line text box (not just a single-line inline field) --
    /// type a short label or a longer design note, Cmd+Return or the Done
    /// button commits it to the canvas as a text element.
    @ViewBuilder
    private func textEntryBox(at location: CGPoint, canvasSize: CGSize) -> some View {
        let boxWidth: CGFloat = 220
        let clampedX = min(max(location.x, boxWidth / 2 + 8), canvasSize.width - boxWidth / 2 - 8)
        let clampedY = min(max(location.y, 70), canvasSize.height - 70)

        VStack(alignment: .trailing, spacing: 6) {
            TextEditor(text: $textDraft)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color)
                .scrollContentBackground(.hidden)
                .frame(width: boxWidth, height: 70)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.55)))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.6), lineWidth: 1.5))
                .onExitCommand { cancelText() }

            HStack(spacing: 6) {
                Button("Cancel") { cancelText() }
                    .buttonStyle(IDEButtonStyle())
                Button("Done ⌘⏎") { commitText(at: location) }
                    .buttonStyle(IDEButtonStyle(tint: IDETheme.accent, prominent: true))
                    .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .frame(width: boxWidth)
        .position(x: clampedX, y: clampedY)
    }

    private func commitText(at location: CGPoint) {
        let trimmed = textDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            elements.append(WhiteboardElement(kind: WhiteboardTool.text.rawValue, points: [location], text: trimmed, colorHex: color.hexString, lineWidth: lineWidth))
        }
        pendingTextLocation = nil
        textDraft = ""
        save()
    }

    private func cancelText() {
        pendingTextLocation = nil
        textDraft = ""
    }

    private func draw(_ element: WhiteboardElement, in context: inout GraphicsContext) {
        let drawColor = Color(hex: element.colorHex)
        switch element.kind {
        case WhiteboardTool.pen.rawValue:
            guard element.points.count > 1 else { return }
            var path = Path()
            path.move(to: element.points[0])
            for point in element.points.dropFirst() { path.addLine(to: point) }
            context.stroke(path, with: .color(drawColor), style: StrokeStyle(lineWidth: element.lineWidth, lineCap: .round, lineJoin: .round))

        case WhiteboardTool.rectangle.rawValue:
            guard element.points.count == 2 else { return }
            let rect = CGRect(origin: element.points[0], size: .zero).union(CGRect(origin: element.points[1], size: .zero))
            context.stroke(Path(rect), with: .color(drawColor), style: StrokeStyle(lineWidth: element.lineWidth))

        case WhiteboardTool.arrow.rawValue:
            guard element.points.count == 2 else { return }
            let start = element.points[0], end = element.points[1]
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            context.stroke(path, with: .color(drawColor), style: StrokeStyle(lineWidth: element.lineWidth, lineCap: .round))
            let angle = atan2(end.y - start.y, end.x - start.x)
            let arrowLength: CGFloat = 10 + element.lineWidth
            let wingAngle = CGFloat.pi / 7
            var head = Path()
            head.move(to: end)
            head.addLine(to: CGPoint(x: end.x - arrowLength * cos(angle - wingAngle), y: end.y - arrowLength * sin(angle - wingAngle)))
            head.move(to: end)
            head.addLine(to: CGPoint(x: end.x - arrowLength * cos(angle + wingAngle), y: end.y - arrowLength * sin(angle + wingAngle)))
            context.stroke(head, with: .color(drawColor), style: StrokeStyle(lineWidth: element.lineWidth, lineCap: .round))

        case WhiteboardTool.text.rawValue:
            guard let point = element.points.first, let text = element.text else { return }
            context.draw(Text(text).font(.system(size: 13, weight: .semibold)).foregroundStyle(drawColor), at: point, anchor: .leading)

        default:
            break
        }
    }

    private func load() {
        guard !hasLoaded else { return }
        hasLoaded = true
        if let existing = documents.first(where: { $0.questionId == questionId }) {
            elements = existing.elements
        } else {
            let doc = WhiteboardDocument(questionId: questionId)
            modelContext.insert(doc)
            elements = []
        }
    }

    private func save() {
        guard let existing = documents.first(where: { $0.questionId == questionId }) else { return }
        existing.elements = elements
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        sqrt(pow(x - other.x, 2) + pow(y - other.y, 2))
    }
}

private extension Color {
    var hexString: String {
        guard let components = NSColor(self).usingColorSpace(.deviceRGB) else { return "#FFFFFF" }
        let r = Int(components.redComponent * 255), g = Int(components.greenComponent * 255), b = Int(components.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}
