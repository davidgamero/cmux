import XCTest

#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

final class HintLabelGeneratorTests: XCTestCase {
    private let alphabet = Set("SADFJKLEWCMPGH")

    func testGenerateHintLabelsCountZero() {
        XCTAssertEqual(generateHintLabels(count: 0), [])
    }

    func testGenerateHintLabelsCountOne() {
        XCTAssertEqual(generateHintLabels(count: 1), ["S"])
    }

    func testGenerateHintLabelsCountFive() {
        let labels = generateHintLabels(count: 5)
        XCTAssertEqual(labels.count, 5)
        XCTAssertEqual(Set(labels).count, 5)
        XCTAssertTrue(labels.allSatisfy { $0.count == 1 })
        XCTAssertTrue(labels.allSatisfy { alphabet.contains($0.first!) })
        XCTAssertEqual(labels, ["S", "A", "D", "F", "J"])
    }

    func testGenerateHintLabelsCountFourteen() {
        let labels = generateHintLabels(count: 14)
        XCTAssertEqual(labels.count, 14)
        XCTAssertEqual(Set(labels).count, 14)
        XCTAssertTrue(labels.allSatisfy { $0.count == 1 })
        XCTAssertEqual(labels, ["S", "A", "D", "F", "J", "K", "L", "E", "W", "C", "M", "P", "G", "H"])
    }

    func testGenerateHintLabelsCountFifteen() {
        let labels = generateHintLabels(count: 15)
        XCTAssertEqual(labels.count, 15)
        XCTAssertEqual(Set(labels).count, 15)
        XCTAssertTrue(labels.allSatisfy { $0.count == 2 })
        XCTAssertTrue(labels.allSatisfy { label in
            label.allSatisfy { alphabet.contains($0) }
        })
    }

    func testGenerateHintLabelsCountFifty() {
        let labels = generateHintLabels(count: 50)
        XCTAssertEqual(labels.count, 50)
        XCTAssertEqual(Set(labels).count, 50)

        let lengths = Set(labels.map(\.count))
        XCTAssertEqual(lengths.count, 1)

        XCTAssertTrue(labels.allSatisfy { label in
            label.allSatisfy { alphabet.contains($0) }
        })

        // No label should be a prefix of another (uniform length ensures this)
        for i in 0..<labels.count {
            for j in 0..<labels.count where i != j {
                XCTAssertFalse(labels[i].hasPrefix(labels[j]))
            }
        }
    }

    func testLabelsOnlyUseAlphabetCharacters() {
        let labels = generateHintLabels(count: 50)
        XCTAssertTrue(labels.allSatisfy { label in
            label.allSatisfy { alphabet.contains($0) }
        })
    }
}
