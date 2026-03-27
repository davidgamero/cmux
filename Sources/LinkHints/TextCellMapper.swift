import Foundation

struct CellPosition: Equatable {
    let row: Int    // 0-based row in viewport
    let col: Int    // 0-based column in viewport
}

// MARK: - Wide character detection

private func isWideCharacter(_ scalar: Unicode.Scalar) -> Bool {
    let v = scalar.value
    return (v >= 0x1100  && v <= 0x115F)   // Hangul Jamo
        || (v >= 0x2E80  && v <= 0xA4CF)   // CJK (wide range)
        || (v >= 0xAC00  && v <= 0xD7AF)   // Hangul Syllables
        || (v >= 0xF900  && v <= 0xFAFF)   // CJK Compatibility Ideographs
        || (v >= 0xFE10  && v <= 0xFE6F)   // CJK Forms
        || (v >= 0xFF01  && v <= 0xFF60)   // Fullwidth Forms
        || (v >= 0xFFE0  && v <= 0xFFE6)   // Fullwidth Signs
        || (v >= 0x20000 && v <= 0x2FFFD)  // CJK Extension B-F
        || (v >= 0x30000 && v <= 0x3FFFD)  // CJK Extension G+
}

// MARK: - Cell width of a Character

private func cellWidth(of char: Character) -> Int {
    guard let scalar = char.unicodeScalars.first else { return 1 }
    return isWideCharacter(scalar) ? 2 : 1
}

// MARK: - Single offset mapper

/// Maps a UTF-8 byte offset in terminal text to (row, col) cell position.
func mapByteOffsetToCellPosition(
    text: String,
    byteOffset: Int,
    columns: Int,
    tabWidth: Int = 8
) -> CellPosition {
    let results = mapByteOffsetsToCellPositions(
        text: text,
        byteOffsets: [byteOffset],
        columns: columns,
        tabWidth: tabWidth
    )
    return results.first ?? CellPosition(row: 0, col: 0)
}

// MARK: - Batch mapper (single pass)

/// Batch version - maps multiple byte offsets in a single pass.
/// byteOffsets MUST be sorted ascending.
func mapByteOffsetsToCellPositions(
    text: String,
    byteOffsets: [Int],
    columns: Int,
    tabWidth: Int = 8
) -> [CellPosition] {
    guard !byteOffsets.isEmpty else { return [] }

    var results = [CellPosition](repeating: CellPosition(row: 0, col: 0), count: byteOffsets.count)
    var targetIndex = 0

    var currentByteOffset = 0
    var currentRow = 0
    var currentCol = 0

    for char in text {
        while targetIndex < byteOffsets.count && byteOffsets[targetIndex] == currentByteOffset {
            results[targetIndex] = CellPosition(row: currentRow, col: currentCol)
            targetIndex += 1
        }
        if targetIndex >= byteOffsets.count { break }

        let charByteCount = char.utf8.count

        if char == "\n" {
            currentRow += 1
            currentCol = 0
        } else if char == "\t" {
            let nextTabCol = ((currentCol / tabWidth) + 1) * tabWidth
            if nextTabCol >= columns {
                currentRow += 1
                currentCol = 0
            } else {
                currentCol = nextTabCol
            }
        } else {
            let width = cellWidth(of: char)
            if width == 2 {
                if currentCol + 2 > columns {
                    currentRow += 1
                    currentCol = 0
                }
                currentCol += 2
                if currentCol >= columns {
                    currentRow += 1
                    currentCol = 0
                }
            } else {
                currentCol += 1
                if currentCol >= columns {
                    currentRow += 1
                    currentCol = 0
                }
            }
        }

        currentByteOffset += charByteCount
    }

    while targetIndex < byteOffsets.count {
        results[targetIndex] = CellPosition(row: currentRow, col: currentCol)
        targetIndex += 1
    }

    return results
}
