import Foundation

// MARK: - URL Extraction

// Balanced-parens URL pattern:
// - Matches http/https/ftp schemes
// - Allows nested parens like /wiki/Foo_(bar)
// - Trailing punctuation (.,:;!?) trimmed after matching
private let urlPattern = #"(?:https?|ftp)://[^\s<>"'`\[\]{}\\]+"#

// MARK: - File Path Extraction

// File path pattern covering:
//   /absolute/path, ./relative, ~/home
// with optional :line and :line:col suffix
// Requires a word boundary before the path to avoid matching mid-word
private let filePathPattern =
    #"(?<![.\w])(?:/|~/|\./)[\w.~/\-+@%](?:[\w./\-+@%]|/[\w.\-+@%])*(?::\d+(?::\d+)?)?"#

// MARK: - Public API

func extractLinks(from text: String) -> [ExtractedLink] {
    guard let textUTF8 = text.data(using: .utf8) else { return [] }
    let nsText = text as NSString

    var results: [ExtractedLink] = []

    // --- URL matches ---
    if let urlRegex = try? NSRegularExpression(pattern: urlPattern) {
        let fullRange = NSRange(location: 0, length: nsText.length)
        let matches = urlRegex.matches(in: text, range: fullRange)
        for match in matches {
            let nsRange = match.range
            guard let swiftRange = Range(nsRange, in: text) else { continue }
            var matched = String(text[swiftRange])

            // Balance parentheses: if there's an unbalanced ), trim it
            matched = trimUnbalancedTrailingParens(matched)

            // Trim trailing sentence punctuation
            matched = trimTrailingPunctuation(matched)

            guard !matched.isEmpty else { continue }

            // Recompute the final range after trimming
            let trimmedCount = String(text[swiftRange]).count - matched.count
            let finalSwiftEnd = text.index(swiftRange.upperBound, offsetBy: -trimmedCount, limitedBy: text.startIndex) ?? swiftRange.upperBound
            let finalRange = swiftRange.lowerBound..<finalSwiftEnd

            guard let byteRange = utf8ByteRange(of: finalRange, in: text, utf8Data: textUTF8) else { continue }

            results.append(ExtractedLink(
                text: matched,
                type: .url,
                byteRange: byteRange,
                lineNumber: nil,
                column: nil
            ))
        }
    }

    // --- File path matches ---
    if let pathRegex = try? NSRegularExpression(pattern: filePathPattern) {
        let fullRange = NSRange(location: 0, length: nsText.length)
        let matches = pathRegex.matches(in: text, range: fullRange)
        for match in matches {
            let nsRange = match.range
            guard let swiftRange = Range(nsRange, in: text) else { continue }
            let matched = String(text[swiftRange])

            // Parse optional :line and :line:col suffix
            let (pathText, lineNum, col) = parsePathSuffix(matched)

            guard !pathText.isEmpty else { continue }

            // Recompute range to only cover the path portion (without suffix)
            let pathEnd = text.index(swiftRange.lowerBound, offsetBy: pathText.count, limitedBy: text.endIndex) ?? swiftRange.upperBound
            let pathRange = swiftRange.lowerBound..<pathEnd

            guard let byteRange = utf8ByteRange(of: pathRange, in: text, utf8Data: textUTF8) else { continue }

            // Check for overlap with already-found URLs; prefer URL
            let overlaps = results.contains { existing in
                existing.byteRange.overlaps(byteRange)
            }
            if overlaps { continue }

            results.append(ExtractedLink(
                text: matched,
                type: .filePath,
                byteRange: byteRange,
                lineNumber: lineNum,
                column: col
            ))
        }
    }

    // Sort by byte offset
    results.sort { $0.byteRange.lowerBound < $1.byteRange.lowerBound }
    return results
}

// MARK: - Helpers

/// Remove a single unmatched trailing `)` if parens are unbalanced.
private func trimUnbalancedTrailingParens(_ s: String) -> String {
    var open = 0
    for ch in s {
        if ch == "(" { open += 1 }
        else if ch == ")" { open -= 1 }
    }
    // open < 0 means more ) than ( — trim the trailing one(s)
    var result = s
    var excess = -open
    while excess > 0, result.last == ")" {
        result.removeLast()
        excess -= 1
    }
    return result
}

/// Trim trailing sentence-ending punctuation that is likely not part of the URL.
private func trimTrailingPunctuation(_ s: String) -> String {
    let sentencePunct: Set<Character> = [".", ",", ";", ":", "!", "?"]
    var result = s
    while let last = result.last, sentencePunct.contains(last) {
        result.removeLast()
    }
    return result
}

/// Parse optional `:line` or `:line:col` suffix from a file path string.
/// Returns (pathWithoutSuffix, lineNumber, column).
private func parsePathSuffix(_ s: String) -> (String, Int?, Int?) {
    // Match :digits or :digits:digits at end
    let suffixPattern = #"(:\d+(?::\d+)?)$"#
    guard let regex = try? NSRegularExpression(pattern: suffixPattern) else {
        return (s, nil, nil)
    }
    let nsS = s as NSString
    guard let match = regex.firstMatch(in: s, range: NSRange(location: 0, length: nsS.length)) else {
        return (s, nil, nil)
    }
    let suffix = nsS.substring(with: match.range)  // e.g. ":42:10" or ":42"
    let pathPart = String(s.dropLast(suffix.count))
    let parts = suffix.split(separator: ":").compactMap { Int($0) }
    let lineNum = parts.count >= 1 ? parts[0] : nil
    let col = parts.count >= 2 ? parts[1] : nil
    return (pathPart, lineNum, col)
}

/// Compute UTF-8 byte range for a Swift String.Index range within `text`.
private func utf8ByteRange(of range: Range<String.Index>, in text: String, utf8Data: Data) -> Range<Int>? {
    let lower = text.utf8.distance(from: text.utf8.startIndex, to: range.lowerBound)
    let upper = text.utf8.distance(from: text.utf8.startIndex, to: range.upperBound)
    guard lower <= upper, upper <= utf8Data.count else { return nil }
    return lower..<upper
}
