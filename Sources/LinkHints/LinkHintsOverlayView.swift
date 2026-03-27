import SwiftUI

struct LinkHintsOverlayView: View {
    let hints: [LinkHintsState.HintedLink]
    let inputBuffer: String
    let surfaceSize: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            ForEach(Array(hints.enumerated()), id: \.offset) { _, hint in
                LinkHintBadgeView(
                    label: hint.label,
                    inputBuffer: inputBuffer,
                    pixelX: hint.pixelX,
                    pixelY: hint.pixelY,
                    surfaceSize: surfaceSize
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}

private struct LinkHintBadgeView: View {
    let label: String
    let inputBuffer: String
    let pixelX: CGFloat
    let pixelY: CGFloat
    let surfaceSize: CGSize

    private var matchedPrefix: String {
        let upper = inputBuffer.uppercased()
        guard label.hasPrefix(upper), !upper.isEmpty else { return "" }
        return upper
    }

    private var remainingSuffix: String {
        let upper = inputBuffer.uppercased()
        guard label.hasPrefix(upper) else { return label }
        return String(label.dropFirst(upper.count))
    }

    var body: some View {
        HStack(spacing: 0) {
            if !matchedPrefix.isEmpty {
                Text(matchedPrefix)
                    .foregroundColor(.yellow)
                    .fontWeight(.bold)
            }
            Text(remainingSuffix.isEmpty && matchedPrefix.isEmpty ? label : remainingSuffix)
                .foregroundColor(.white)
                .fontWeight(.bold)
        }
        .font(.system(size: 12, weight: .bold, design: .monospaced))
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.12, green: 0.18, blue: 0.55).opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
        )
        .position(
            x: pixelX,
            // surfaceSize.height - pixelY converts from top-origin (Ghostty) to bottom-origin (AppKit),
            // but SwiftUI ZStack uses top-left origin — subtract from surfaceSize.height.
            y: surfaceSize.height - pixelY
        )
    }
}
