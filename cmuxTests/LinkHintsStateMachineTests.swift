import XCTest
import CoreGraphics

#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

final class LinkHintsStateMachineTests: XCTestCase {

    private func makeHint(label: String, text: String = "https://example.com") -> LinkHintsState.HintedLink {
        LinkHintsState.HintedLink(
            link: ExtractedLink(text: text, type: .url, byteRange: 0..<text.utf8.count, lineNumber: nil, column: nil),
            label: label,
            pixelX: 0,
            pixelY: 0
        )
    }

    func testInitialStateShowsAllHints() {
        let state = LinkHintsState(hints: [makeHint(label: "S"), makeHint(label: "A"), makeHint(label: "D")])
        XCTAssertEqual(state.filteredHints.count, 3)
        XCTAssertEqual(state.inputBuffer, "")
        XCTAssertNil(state.selectedHint)
    }

    func testAppendCharacterFiltersHints() {
        var state = LinkHintsState(hints: [
            makeHint(label: "SA"), makeHint(label: "SD"), makeHint(label: "SF"),
            makeHint(label: "DA"), makeHint(label: "DS")
        ])
        state.appendCharacter("s")
        XCTAssertEqual(state.filteredHints.count, 3)
        XCTAssertNil(state.selectedHint)
    }

    func testTwoCharacterSelection() {
        var state = LinkHintsState(hints: [
            makeHint(label: "SA"), makeHint(label: "SD"), makeHint(label: "SF")
        ])
        state.appendCharacter("s")
        XCTAssertEqual(state.filteredHints.count, 3)
        state.appendCharacter("d")
        XCTAssertEqual(state.filteredHints.count, 1)
        XCTAssertEqual(state.selectedHint?.label, "SD")
    }

    func testSingleCharacterExactMatch() {
        var state = LinkHintsState(hints: [
            makeHint(label: "S"), makeHint(label: "A"), makeHint(label: "D")
        ])
        state.appendCharacter("a")
        XCTAssertEqual(state.selectedHint?.label, "A")
    }

    func testCaseInsensitiveMatching() {
        var state = LinkHintsState(hints: [
            makeHint(label: "SA"), makeHint(label: "SD")
        ])
        state.appendCharacter("s")
        XCTAssertEqual(state.filteredHints.count, 2)
        state.appendCharacter("a")
        XCTAssertEqual(state.selectedHint?.label, "SA")
    }

    func testDeleteLastCharacterWidensFilter() {
        var state = LinkHintsState(hints: [
            makeHint(label: "SA"), makeHint(label: "SD"), makeHint(label: "SF")
        ])
        state.appendCharacter("s")
        state.appendCharacter("d")
        XCTAssertEqual(state.filteredHints.count, 1)
        state.deleteLastCharacter()
        XCTAssertEqual(state.filteredHints.count, 3)
        XCTAssertEqual(state.inputBuffer, "s")
    }

    func testDeleteOnEmptyBufferIsNoOp() {
        var state = LinkHintsState(hints: [makeHint(label: "S")])
        state.deleteLastCharacter()
        XCTAssertEqual(state.inputBuffer, "")
        XCTAssertEqual(state.filteredHints.count, 1)
    }

    func testResetClearsInputAndShowsAllHints() {
        var state = LinkHintsState(hints: [
            makeHint(label: "SA"), makeHint(label: "SD")
        ])
        state.appendCharacter("s")
        state.appendCharacter("d")
        state.reset()
        XCTAssertEqual(state.inputBuffer, "")
        XCTAssertEqual(state.filteredHints.count, 2)
        XCTAssertNil(state.selectedHint)
    }

    func testInvalidCharacterResultsInNoMatches() {
        var state = LinkHintsState(hints: [
            makeHint(label: "S"), makeHint(label: "A"), makeHint(label: "D")
        ])
        state.appendCharacter("z")
        XCTAssertEqual(state.filteredHints.count, 0)
        XCTAssertNil(state.selectedHint)
    }
}
