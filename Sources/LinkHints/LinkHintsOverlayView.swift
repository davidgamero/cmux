import SwiftUI

struct LinkHintsOverlayView: View {
    let hints: [LinkHintsState.HintedLink]
    let inputBuffer: String
    let surfaceSize: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear

            #if DEBUG
            let cellW = hints.first?.cellWidthPx ?? 0
            let cellH = hints.first?.cellHeightPx ?? 0
            if cellW > 0 && cellH > 0 {
                DebugGridView(
                    cellWidth: cellW,
                    cellHeight: cellH,
                    surfaceSize: surfaceSize
                )
            }
            #endif

            ForEach(Array(hints.enumerated()), id: \.offset) { _, hint in
                #if DEBUG
                LinkHintDebugBoxView(hint: hint)
                #endif
                LinkHintBadgeView(
                    label: hint.label,
                    inputBuffer: inputBuffer,
                    pixelX: hint.pixelX,
                    pixelY: hint.pixelY
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}

#if DEBUG
private struct DebugGridView: View {
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let surfaceSize: CGSize

    var body: some View {
        Canvas { context, size in
            let cols = Int(size.width / cellWidth)
            let rows = Int(size.height / cellHeight)

            for col in 0...cols {
                let x = CGFloat(col) * cellWidth
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.green.opacity(0.25)), lineWidth: 0.5)
            }

            for row in 0...rows {
                let y = CGFloat(row) * cellHeight
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.green.opacity(0.25)), lineWidth: 0.5)
            }

            for row in 0..<min(rows, 5) {
                let label = "row \(row)"
                let text = context.resolve(Text(label)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.green.opacity(0.6)))
                context.draw(text, at: CGPoint(x: 4, y: CGFloat(row) * cellHeight + cellHeight / 2), anchor: .leading)
            }
        }
        .frame(width: surfaceSize.width, height: surfaceSize.height)
    }
}

private struct LinkHintDebugBoxView: View {
    let hint: LinkHintsState.HintedLink

    var body: some View {
        let boxWidth = CGFloat(hint.linkCellWidth) * hint.cellWidthPx
        let boxHeight = hint.cellHeightPx
        let boxX = hint.pixelX - hint.cellWidthPx / 2.0
        let boxY = hint.pixelY - hint.cellHeightPx / 2.0

        ZStack(alignment: .topLeading) {
            Rectangle()
                .stroke(Color.red, lineWidth: 2)
                .frame(width: boxWidth, height: boxHeight)

            Text(hint.link.text)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.red)
                .lineLimit(1)
                .offset(x: boxWidth + 4, y: 0)
        }
        .offset(x: boxX, y: boxY)
    }
}
#endif

private struct LinkHintBadgeView: View {
    let label: String
    let inputBuffer: String
    let pixelX: CGFloat
    let pixelY: CGFloat

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
        .position(x: pixelX, y: pixelY)
    }
}
