import XCTest
@testable import LinguaCards

final class AnswerMatcherTests: XCTestCase {

    // MARK: - Exact and normalized matches

    func testExactMatch() {
        XCTAssertEqual(AnswerMatcher.evaluate(input: "дом", expected: "дом"), .correct)
    }

    func testCaseInsensitive() {
        XCTAssertEqual(AnswerMatcher.evaluate(input: "ДОМ", expected: "дом"), .correct)
        XCTAssertEqual(AnswerMatcher.evaluate(input: "House", expected: "house"), .correct)
    }

    func testDiacriticsIgnored() {
        XCTAssertEqual(AnswerMatcher.evaluate(input: "cafe", expected: "café"), .correct)
        XCTAssertEqual(AnswerMatcher.evaluate(input: "uber", expected: "über"), .correct)
    }

    func testWhitespaceTrimmedAndCollapsed() {
        XCTAssertEqual(
            AnswerMatcher.evaluate(input: "  good   morning  ", expected: "good morning"),
            .correct
        )
    }

    func testPunctuationIgnored() {
        XCTAssertEqual(
            AnswerMatcher.evaluate(input: "dont know", expected: "don't know!"),
            .correct
        )
    }

    // MARK: - Typo tolerance

    func testSingleTypoOnMediumWordIsAlmostCorrect() {
        XCTAssertEqual(AnswerMatcher.evaluate(input: "freind", expected: "friend"), .almostCorrect)
    }

    func testTwoTyposOnLongWordIsAlmostCorrect() {
        XCTAssertEqual(
            AnswerMatcher.evaluate(input: "путешествоватб", expected: "путешествовать"),
            .almostCorrect
        )
    }

    func testShortWordsRequireExactMatch() {
        XCTAssertEqual(AnswerMatcher.evaluate(input: "дым", expected: "дом"), .wrong)
        XCTAssertEqual(AnswerMatcher.evaluate(input: "cat", expected: "car"), .wrong)
    }

    func testCompletelyDifferentAnswerIsWrong() {
        XCTAssertEqual(AnswerMatcher.evaluate(input: "собака", expected: "дом"), .wrong)
    }

    func testEmptyInputIsWrong() {
        XCTAssertEqual(AnswerMatcher.evaluate(input: "", expected: "дом"), .wrong)
        XCTAssertEqual(AnswerMatcher.evaluate(input: "   ", expected: "дом"), .wrong)
    }

    // MARK: - Alternative answers

    func testAnyAlternativeAccepted() {
        let expected = "дом / здание, строение"
        XCTAssertEqual(AnswerMatcher.evaluate(input: "дом", expected: expected), .correct)
        XCTAssertEqual(AnswerMatcher.evaluate(input: "здание", expected: expected), .correct)
        XCTAssertEqual(AnswerMatcher.evaluate(input: "строение", expected: expected), .correct)
        XCTAssertEqual(AnswerMatcher.evaluate(input: "квартира", expected: expected), .wrong)
    }

    func testIsCorrectAcceptsNearMatches() {
        XCTAssertTrue(AnswerMatcher.isCorrect(input: "friend", expected: "friend"))
        XCTAssertTrue(AnswerMatcher.isCorrect(input: "freind", expected: "friend"))
        XCTAssertFalse(AnswerMatcher.isCorrect(input: "enemy", expected: "friend"))
    }

    // MARK: - Building blocks

    func testNormalize() {
        XCTAssertEqual(AnswerMatcher.normalize("  Café,  au   LAIT! "), "cafe au lait")
    }

    func testEditDistance() {
        XCTAssertEqual(AnswerMatcher.editDistance("kitten", "sitting"), 3)
        XCTAssertEqual(AnswerMatcher.editDistance("abc", "abc"), 0)
        XCTAssertEqual(AnswerMatcher.editDistance("", "abc"), 3)
        XCTAssertEqual(AnswerMatcher.editDistance("abc", ""), 3)
        // Adjacent transposition counts as a single edit.
        XCTAssertEqual(AnswerMatcher.editDistance("freind", "friend"), 1)
    }

    func testTypoTolerance() {
        XCTAssertEqual(AnswerMatcher.typoTolerance(forLength: 3), 0)
        XCTAssertEqual(AnswerMatcher.typoTolerance(forLength: 5), 1)
        XCTAssertEqual(AnswerMatcher.typoTolerance(forLength: 10), 2)
    }
}
