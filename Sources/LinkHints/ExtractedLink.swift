import Foundation

struct ExtractedLink: Equatable {
    enum LinkType: Equatable {
        case url
        case filePath
    }

    let text: String          // The matched link text
    let type: LinkType
    let byteRange: Range<Int> // Byte offset range within source text UTF-8
    let lineNumber: Int?      // For file paths with :line
    let column: Int?          // For file paths with :line:col
}
