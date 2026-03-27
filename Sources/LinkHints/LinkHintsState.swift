import Foundation
import CoreGraphics

/// Represents the current state of the link hints mode.
struct LinkHintsState {
    /// A link with its assigned hint label and pixel position for overlay rendering.
    struct HintedLink {
        let link: ExtractedLink
        let label: String
        let pixelX: CGFloat   // Pixel X position for overlay
        let pixelY: CGFloat   // Pixel Y position for overlay
    }

    private(set) var allHints: [HintedLink]
    private(set) var inputBuffer: String = ""

    init(hints: [HintedLink]) {
        self.allHints = hints
    }

    /// Returns hints whose labels start with the current input buffer (case-insensitive).
    var filteredHints: [HintedLink] {
        if inputBuffer.isEmpty { return allHints }
        let upper = inputBuffer.uppercased()
        return allHints.filter { $0.label.hasPrefix(upper) }
    }

    /// Returns the uniquely matched hint if input buffer exactly matches one label.
    var selectedHint: HintedLink? {
        let upper = inputBuffer.uppercased()
        let matches = allHints.filter { $0.label == upper }
        return matches.count == 1 ? matches.first : nil
    }

    mutating func appendCharacter(_ char: Character) {
        inputBuffer.append(char)
    }

    mutating func deleteLastCharacter() {
        guard !inputBuffer.isEmpty else { return }
        inputBuffer.removeLast()
    }

    mutating func reset() {
        inputBuffer = ""
    }
}
