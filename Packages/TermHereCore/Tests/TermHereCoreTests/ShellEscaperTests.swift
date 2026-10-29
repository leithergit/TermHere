import XCTest
@testable import TermHereCore

final class ShellEscaperTests: XCTestCase {
    func testPlain() { XCTAssertEqual(ShellEscaper.singleQuoted("abc"), "'abc'") }
    func testEmpty() { XCTAssertEqual(ShellEscaper.singleQuoted(""), "''") }
    func testSpaces() { XCTAssertEqual(ShellEscaper.singleQuoted("a b c"), "'a b c'") }
    func testSingleQuote() { XCTAssertEqual(ShellEscaper.singleQuoted("it's"), #"'it'\''s'"#) }
    func testOnlySingleQuote() { XCTAssertEqual(ShellEscaper.singleQuoted("'"), #"''\'''"#) }
    func testDollar() { XCTAssertEqual(ShellEscaper.singleQuoted("$HOME"), "'$HOME'") }
    func testBacktick() { XCTAssertEqual(ShellEscaper.singleQuoted("`x`"), "'`x`'") }
    func testDoubleQuote() { XCTAssertEqual(ShellEscaper.singleQuoted("a\"b"), "'a\"b'") }
    func testBackslash() { XCTAssertEqual(ShellEscaper.singleQuoted(#"a\b"#), #"'a\b'"#) }
    func testNewline() { XCTAssertEqual(ShellEscaper.singleQuoted("a\nb"), "'a\nb'") }
    func testCJK() { XCTAssertEqual(ShellEscaper.singleQuoted("文档/项目"), "'文档/项目'") }
    func testEmoji() { XCTAssertEqual(ShellEscaper.singleQuoted("📁 x"), "'📁 x'") }
}
