import Foundation
import SwiftData
import SwiftUI

enum WhiteboardTool: String, CaseIterable, Identifiable {
    case pen, rectangle, arrow, text, eraser
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .pen: return "pencil"
        case .rectangle: return "rectangle"
        case .arrow: return "arrow.up.right"
        case .text: return "textformat"
        case .eraser: return "eraser"
        }
    }
}

/// One drawn element on the whiteboard. `points` holds the freehand path
/// for `.pen`, or the two opposite corners for `.rectangle`/`.arrow`; `text`
/// and its anchor point are used for `.text`.
struct WhiteboardElement: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var kind: WhiteboardTool.RawValue
    var points: [CGPoint] = []
    var text: String?
    var colorHex: String
    var lineWidth: CGFloat
}

/// Per-question whiteboard, persisted alongside the rest of CodeMate's
/// SwiftData store. Elements are stored as encoded JSON rather than a
/// relationship graph -- simplest thing that works for a lightweight
/// sketch surface, and avoids a second model type per element.
@Model
final class WhiteboardDocument {
    @Attribute(.unique) var questionId: String
    var elementsData: Data
    var updatedAt: Date

    init(questionId: String) {
        self.questionId = questionId
        self.elementsData = (try? JSONEncoder().encode([WhiteboardElement]())) ?? Data()
        self.updatedAt = .now
    }

    var elements: [WhiteboardElement] {
        get { (try? JSONDecoder().decode([WhiteboardElement].self, from: elementsData)) ?? [] }
        set {
            elementsData = (try? JSONEncoder().encode(newValue)) ?? elementsData
            updatedAt = .now
        }
    }
}
