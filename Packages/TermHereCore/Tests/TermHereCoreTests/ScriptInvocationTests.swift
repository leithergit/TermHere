import XCTest
@testable import TermHereCore

final class ScriptInvocationTests: XCTestCase {
    func testCommand() {
        let url = URL(fileURLWithPath: "/Users/me/My Dir/it's")
        XCTAssertEqual(ScriptInvocation.command(for: url), #"cd '/Users/me/My Dir/it'\''s' && clear"#)
    }

    func testHandlerNames() {
        XCTAssertEqual(OpenMode.window.handlerName, "openwindow")
        XCTAssertEqual(OpenMode.tab.handlerName, "opentab")
    }

    func testEventClassAndID() {
        let e = ScriptInvocation.event(mode: .window, command: "cd '/x' && clear")
        XCTAssertEqual(e.eventClass, 0x61736372) // 'ascr'
        XCTAssertEqual(e.eventID, 0x70736272)    // 'psbr'
    }

    func testSubroutineNameParam() {
        for mode in [OpenMode.window, .tab] {
            let e = ScriptInvocation.event(mode: mode, command: "c")
            XCTAssertEqual(e.paramDescriptor(forKeyword: 0x736E616D)?.stringValue, mode.handlerName) // 'snam'
        }
    }

    func testDirectObjectIsListWithCommand() {
        let e = ScriptInvocation.event(mode: .tab, command: "cd '/x' && clear")
        let list = e.paramDescriptor(forKeyword: 0x2D2D2D2D) // '----'
        XCTAssertEqual(list?.numberOfItems, 1)
        XCTAssertEqual(list?.atIndex(1)?.stringValue, "cd '/x' && clear")
    }

    func testCommandPathWithQuoteAndNewline() {
        let url = URL(fileURLWithPath: "/tmp/a'b\nc")
        XCTAssertEqual(ScriptInvocation.command(for: url), "cd '/tmp/a'\\''b\nc' && clear")
    }
    func testCommandRoot() {
        XCTAssertEqual(ScriptInvocation.command(for: URL(fileURLWithPath: "/")), "cd '/' && clear")
    }
    func testCommandTrailingSlashDirectory() {
        XCTAssertEqual(ScriptInvocation.command(for: URL(fileURLWithPath: "/tmp/dir/", isDirectory: true)), "cd '/tmp/dir' && clear")
    }
    func testCommandUnicodeNormalization() {
        XCTAssertEqual(ScriptInvocation.command(for: URL(fileURLWithPath: "/tmp/文档 📁")), "cd '/tmp/文档 📁' && clear")
    }
}
