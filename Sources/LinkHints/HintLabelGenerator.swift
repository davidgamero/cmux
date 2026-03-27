import Foundation

/// Generates unique hint labels for link hints overlay.
/// Uses home-row characters for fast typing: "sadfjklewcmpgh" (14 chars).
func generateHintLabels(count: Int) -> [String] {
    guard count > 0 else { return [] }

    let alphabet = Array("SADFJKLEWCMPGH")
    let base = alphabet.count

    if count <= base {
        return alphabet.prefix(count).map(String.init)
    }

    // For count > base, use uniform-length labels (base-14 encoding)
    // to avoid prefix ambiguity
    var length = 1
    var capacity = base
    while capacity < count {
        length += 1
        capacity *= base
    }

    func label(for index: Int) -> String {
        var value = index
        var chars = Array(repeating: alphabet[0], count: length)

        for position in stride(from: length - 1, through: 0, by: -1) {
            chars[position] = alphabet[value % base]
            value /= base
        }

        return String(chars)
    }

    return (0..<count).map(label(for:))
}
