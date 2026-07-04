import XCTest
@testable import LinguaCards

final class ImportParserTests: XCTestCase {

    func testParsesDashSeparatedLines() {
        let cards = ImportParser.parse("apple - яблоко\ndog - собака")
        XCTAssertEqual(cards, [
            ImportParser.ParsedCard(front: "apple", back: "яблоко"),
            ImportParser.ParsedCard(front: "dog", back: "собака"),
        ])
    }

    func testParsesTabAndEqualsSeparators() {
        XCTAssertEqual(
            ImportParser.parseLine("cat\tкошка"),
            ImportParser.ParsedCard(front: "cat", back: "кошка")
        )
        XCTAssertEqual(
            ImportParser.parseLine("sun = солнце"),
            ImportParser.ParsedCard(front: "sun", back: "солнце")
        )
    }

    func testParsesEnAndEmDashes() {
        XCTAssertEqual(
            ImportParser.parseLine("bread – хлеб"),
            ImportParser.ParsedCard(front: "bread", back: "хлеб")
        )
        XCTAssertEqual(
            ImportParser.parseLine("milk — молоко"),
            ImportParser.ParsedCard(front: "milk", back: "молоко")
        )
    }

    func testHyphenWithoutSpacesStillSplits() {
        XCTAssertEqual(
            ImportParser.parseLine("tree-дерево"),
            ImportParser.ParsedCard(front: "tree", back: "дерево")
        )
    }

    func testSkipsEmptyAndInvalidLines() {
        let cards = ImportParser.parse("""
        apple - яблоко

        just a line without separator
        - missing front
        missing back -
        dog - собака
        """)
        XCTAssertEqual(cards.count, 2)
        XCTAssertEqual(cards.first?.front, "apple")
        XCTAssertEqual(cards.last?.front, "dog")
    }

    func testTrimsWhitespaceAroundParts() {
        XCTAssertEqual(
            ImportParser.parseLine("  water   -   вода  "),
            ImportParser.ParsedCard(front: "water", back: "вода")
        )
    }
}
