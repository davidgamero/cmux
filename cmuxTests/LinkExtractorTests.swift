import XCTest

#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

final class LinkExtractorTests: XCTestCase {

    // MARK: - URL tests

    func testStandardHttpsURL() {
        let text = "Visit https://example.com/path?q=1&r=2#section for info"
        let links = extractLinks(from: text)
        XCTAssertEqual(links.count, 1)
        let link = try! XCTUnwrap(links.first)
        XCTAssertEqual(link.type, .url)
        XCTAssertEqual(link.text, "https://example.com/path?q=1&r=2#section")
        XCTAssertNil(link.lineNumber)
        XCTAssertNil(link.column)
    }

    func testBalancedParensURL() {
        let text = "See https://en.wikipedia.org/wiki/Foo_(bar) for details."
        let links = extractLinks(from: text)
        XCTAssertEqual(links.count, 1)
        let link = try! XCTUnwrap(links.first)
        XCTAssertEqual(link.type, .url)
        XCTAssertTrue(link.text.hasSuffix(")"), "URL should include closing paren: \(link.text)")
        XCTAssertFalse(link.text.hasSuffix("."), "URL should not include trailing period: \(link.text)")
    }

    // MARK: - File path tests

    func testFilePathWithLineAndColumn() {
        let text = "Error at /Users/foo/bar.swift:42:10 — type mismatch"
        let links = extractLinks(from: text)
        XCTAssertEqual(links.count, 1)
        let link = try! XCTUnwrap(links.first)
        XCTAssertEqual(link.type, .filePath)
        XCTAssertEqual(link.lineNumber, 42)
        XCTAssertEqual(link.column, 10)
    }

    func testRelativeAndHomePaths() {
        let text = "Files: ./src/main.rs and ~/Documents/notes.txt:5"
        let links = extractLinks(from: text)
        XCTAssertEqual(links.count, 2)

        let first = links[0]
        XCTAssertEqual(first.type, .filePath)
        XCTAssertTrue(first.text.hasPrefix("./src/"))
        XCTAssertNil(first.lineNumber)

        let second = links[1]
        XCTAssertEqual(second.type, .filePath)
        XCTAssertTrue(second.text.hasPrefix("~/Documents/"))
        XCTAssertEqual(second.lineNumber, 5)
        XCTAssertNil(second.column)
    }

    // MARK: - Mixed content

    func testMixedURLsAndFilePaths() {
        let text = "See https://github.com/repo and ./src/main.rs:15 and http://localhost:3000/api"
        let links = extractLinks(from: text)
        XCTAssertEqual(links.count, 3)

        XCTAssertEqual(links[0].type, .url)
        XCTAssertTrue(links[0].text.hasPrefix("https://github.com"))

        XCTAssertEqual(links[1].type, .filePath)
        XCTAssertEqual(links[1].lineNumber, 15)

        XCTAssertEqual(links[2].type, .url)
        XCTAssertTrue(links[2].text.hasPrefix("http://localhost"))
    }

    // MARK: - Negative cases

    func testNoLinksInPlainText() {
        let text = "Just some regular text with no links at all 12:30 PM"
        let links = extractLinks(from: text)
        XCTAssertEqual(links.count, 0)
    }

    // MARK: - Byte range correctness

    func testByteRangeRoundtripsToOriginalText() {
        let text = "Visit https://example.com/path for info"
        guard let utf8 = text.data(using: .utf8) else { return XCTFail("UTF-8 encode failed") }
        let links = extractLinks(from: text)
        XCTAssertEqual(links.count, 1)
        let link = try! XCTUnwrap(links.first)
        let slice = utf8.subdata(in: link.byteRange)
        XCTAssertEqual(String(data: slice, encoding: .utf8), link.text)
    }

    func testByteRangeWithUnicodeText() {
        let text = "エラー: /Users/foo/bar.swift:10 を確認してください"
        guard let utf8 = text.data(using: .utf8) else { return XCTFail("UTF-8 encode failed") }
        let links = extractLinks(from: text)
        XCTAssertEqual(links.count, 1)
        let link = try! XCTUnwrap(links.first)
        let slice = utf8.subdata(in: link.byteRange)
        XCTAssertEqual(String(data: slice, encoding: .utf8), link.text)
    }
}
