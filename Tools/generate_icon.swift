import SwiftUI
import AppKit

// Renders the CodeMate app icon via SwiftUI's ImageRenderer and writes out
// every size macOS's AppIcon.appiconset needs, plus one large marketing PNG.
// Run with: swift Tools/generate_icon.swift

struct LogoMark: View {
    var cornerRadiusFraction: CGFloat = 0.225

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: size * cornerRadiusFraction, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.42, green: 0.50, blue: 1.00), Color(red: 0.29, green: 0.34, blue: 0.92)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: size * cornerRadiusFraction, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: max(1, size * 0.006))

                // Curly braces -- the "code" half of CodeMate.
                Image(systemName: "curlybraces")
                    .font(.system(size: size * 0.48, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(y: -size * 0.01)

                // A small accent spark -- the "mate"/assistant half.
                Circle()
                    .fill(Color(red: 1.0, green: 0.78, blue: 0.35))
                    .frame(width: size * 0.115, height: size * 0.115)
                    .offset(x: size * 0.255, y: size * 0.235)
                    .shadow(color: Color(red: 1.0, green: 0.78, blue: 0.35).opacity(0.6), radius: size * 0.03)
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

@MainActor
func render(size: CGFloat, scale: CGFloat, to url: URL) {
    let renderer = ImageRenderer(content: LogoMark().frame(width: size, height: size))
    renderer.scale = scale
    guard let nsImage = renderer.nsImage,
          let tiff = nsImage.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("FAILED to render \(url.lastPathComponent)")
        return
    }
    try? png.write(to: url)
    print("wrote \(url.lastPathComponent) (\(Int(size * scale))x\(Int(size * scale)))")
}

let outDir = URL(fileURLWithPath: "Marketing/icon")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

// macOS AppIcon.appiconset required sizes (point size, scale).
let iconSpecs: [(CGFloat, CGFloat, String)] = [
    (16, 1, "icon_16x16.png"), (16, 2, "icon_16x16@2x.png"),
    (32, 1, "icon_32x32.png"), (32, 2, "icon_32x32@2x.png"),
    (128, 1, "icon_128x128.png"), (128, 2, "icon_128x128@2x.png"),
    (256, 1, "icon_256x256.png"), (256, 2, "icon_256x256@2x.png"),
    (512, 1, "icon_512x512.png"), (512, 2, "icon_512x512@2x.png"),
]

MainActor.assumeIsolated {
    for (size, scale, name) in iconSpecs {
        render(size: size, scale: scale, to: outDir.appendingPathComponent(name))
    }

    // One large PNG for marketing use (site, screenshots, README).
    render(size: 1024, scale: 1, to: outDir.appendingPathComponent("logo_1024.png"))
}

print("Done.")
