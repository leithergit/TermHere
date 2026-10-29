import XCTest
@testable import TermHereCore

final class TargetResolverTests: XCTestCase {
    private let dir = URL(fileURLWithPath: "/tmp/dir", isDirectory: true)
    private let file = URL(fileURLWithPath: "/tmp/dir/a.txt")
    private let other = URL(fileURLWithPath: "/tmp/other", isDirectory: true)
    private func isDir(_ u: URL) -> Bool { u.path == "/tmp/dir" || u.path == "/tmp/other" }

    func testContainerUsesTargetedURL() {
        XCTAssertEqual(TargetResolver.resolve(context: .container, targetedURL: dir, selectedURLs: [file], isDirectory: isDir), dir)
    }
    func testContainerNilTargetedIsNil() {
        XCTAssertNil(TargetResolver.resolve(context: .container, targetedURL: nil, selectedURLs: [], isDirectory: isDir))
    }
    func testItemsFolderResolvesToSelf() {
        XCTAssertEqual(TargetResolver.resolve(context: .items, targetedURL: nil, selectedURLs: [dir], isDirectory: isDir), dir)
    }
    func testItemsFileResolvesToParent() {
        XCTAssertEqual(TargetResolver.resolve(context: .items, targetedURL: nil, selectedURLs: [file], isDirectory: isDir)?.path, "/tmp/dir")
    }
    func testItemsMultiSelectTakesFirst() {
        XCTAssertEqual(TargetResolver.resolve(context: .items, targetedURL: nil, selectedURLs: [other, file], isDirectory: isDir), other)
    }
    func testItemsEmptySelectionFallsBackToTargeted() {
        XCTAssertEqual(TargetResolver.resolve(context: .items, targetedURL: dir, selectedURLs: [], isDirectory: isDir), dir)
    }
    func testItemsEmptyEverythingIsNil() {
        XCTAssertNil(TargetResolver.resolve(context: .items, targetedURL: nil, selectedURLs: [], isDirectory: isDir))
    }

    func testItemsFileAtRootResolvesToRoot() {
        XCTAssertEqual(TargetResolver.resolve(context: .items, targetedURL: nil, selectedURLs: [URL(fileURLWithPath: "/a.txt")], isDirectory: { _ in false })?.path, "/")
    }
    func testItemsFolderWithTrailingSlashKeepsPath() {
        let u = URL(fileURLWithPath: "/tmp/dir/")
        XCTAssertEqual(TargetResolver.resolve(context: .items, targetedURL: nil, selectedURLs: [u], isDirectory: { _ in true })?.path, "/tmp/dir")
    }
    func testItemsFileWithTrailingSlashURLParent() {
        let u = URL(string: "file:///tmp/dir/a.txt/")!
        XCTAssertEqual(TargetResolver.resolve(context: .items, targetedURL: nil, selectedURLs: [u], isDirectory: { _ in false })?.path, "/tmp/dir")
    }
    func testContainerRootIsPassedThrough() {
        let root = URL(fileURLWithPath: "/")
        XCTAssertEqual(TargetResolver.resolve(context: .container, targetedURL: root, selectedURLs: [], isDirectory: { _ in true })?.path, "/")
    }
    func testItemsFirstSelectedFileIgnoresTargeted() {
        XCTAssertEqual(TargetResolver.resolve(context: .items, targetedURL: other, selectedURLs: [file], isDirectory: isDir)?.path, "/tmp/dir")
    }

    func testRelativeFileURLResolvesAgainstBase() {
        let rel = URL(fileURLWithPath: "rel/a.txt", relativeTo: URL(fileURLWithPath: "/base"))
        XCTAssertEqual(TargetResolver.resolve(context: .items, targetedURL: nil, selectedURLs: [rel], isDirectory: { _ in false })?.path, "/base/rel")
    }
}
