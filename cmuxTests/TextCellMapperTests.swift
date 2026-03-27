import XCTest

#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

final class TextCellMapperTests: XCTestCase {

    // MARK: - Single offset tests

    func testASCIINewline() {
        let pos = mapByteOffsetToCellPosition(
            text: "hello\nworld",
            byteOffset: 6,
            columns: 80
        )
        XCTAssertEqual(pos, CellPosition(row: 1, col: 0))
    }

    func testCJKWideCharacters() {
        let pos = mapByteOffsetToCellPosition(
            text: "AB你好CD",
            byteOffset: 8,
            columns: 80
        )
        XCTAssertEqual(pos, CellPosition(row: 0, col: 6))
    }

    func testTabAlignment() {
        let pos = mapByteOffsetToCellPosition(
            text: "AB\tCD",
            byteOffset: 3,
            columns: 80,
            tabWidth: 8
        )
        XCTAssertEqual(pos, CellPosition(row: 0, col: 8))
    }

    func testLineWrap() {
        let text = String(repeating: "A", count: 85)
        let pos = mapByteOffsetToCellPosition(
            text: text,
            byteOffset: 80,
            columns: 80
        )
        XCTAssertEqual(pos, CellPosition(row: 1, col: 0))
    }

    func testEmptyStringEdgeCase() {
        let pos = mapByteOffsetToCellPosition(
            text: "",
            byteOffset: 0,
            columns: 80
        )
        XCTAssertEqual(pos, CellPosition(row: 0, col: 0))
    }

    // MARK: - Batch mapping tests

    func testBatchMappingMatchesSingleCalls() {
        let text = "hello\nworld\t!"
        let columns = 80
        let offsets = [0, 3, 6, 11, 12]

        let batchResults = mapByteOffsetsToCellPositions(
            text: text,
            byteOffsets: offsets,
            columns: columns
        )
        XCTAssertEqual(batchResults.count, offsets.count)

        for (i, offset) in offsets.enumerated() {
            let single = mapByteOffsetToCellPosition(
                text: text,
                byteOffset: offset,
                columns: columns
            )
            XCTAssertEqual(
                batchResults[i],
                single,
                "Mismatch at byteOffset \(offset): batch=\(batchResults[i]) single=\(single)"
            )
        }
    }

    func testBatchMappingWithMixedContent() {
        let text = "Hi\n你好\tEnd"
        let columns = 40
        let offsets = [0, 1, 2, 3, 6, 9, 10]

        let results = mapByteOffsetsToCellPositions(
            text: text,
            byteOffsets: offsets,
            columns: columns
        )

        XCTAssertEqual(results[0], CellPosition(row: 0, col: 0))
        XCTAssertEqual(results[1], CellPosition(row: 0, col: 1))
        XCTAssertEqual(results[2], CellPosition(row: 0, col: 2))
        XCTAssertEqual(results[3], CellPosition(row: 1, col: 0))
        XCTAssertEqual(results[4], CellPosition(row: 1, col: 2))
        XCTAssertEqual(results[5], CellPosition(row: 1, col: 4))
        XCTAssertEqual(results[6], CellPosition(row: 1, col: 8))
    }

    func testBatchEmptyOffsets() {
        let results = mapByteOffsetsToCellPositions(
            text: "hello",
            byteOffsets: [],
            columns: 80
        )
        XCTAssertEqual(results, [])
    }

    func testBatchSingleOffset() {
        let results = mapByteOffsetsToCellPositions(
            text: "abc",
            byteOffsets: [2],
            columns: 80
        )
        XCTAssertEqual(results, [CellPosition(row: 0, col: 2)])
    }
}
