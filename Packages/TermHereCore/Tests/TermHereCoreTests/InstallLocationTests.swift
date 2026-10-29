import XCTest
@testable import TermHereCore

final class InstallLocationTests: XCTestCase {
    private let home = URL(fileURLWithPath: "/Users/leether", isDirectory: true)

    private func check(_ path: String) -> Bool {
        InstallLocation.isInApplicationsFolder(
            bundleURL: URL(fileURLWithPath: path, isDirectory: true), homeDirectory: home)
    }

    func testSystemApplications() { XCTAssertTrue(check("/Applications/TermHere.app")) }
    func testUtilitiesSubfolder() { XCTAssertTrue(check("/Applications/Utilities/TermHere.app")) }
    func testUserApplications() { XCTAssertTrue(check("/Users/leether/Applications/TermHere.app")) }
    func testTrailingDotsAreStandardized() {
        XCTAssertTrue(check("/Applications/../Applications/TermHere.app"))
    }

    func testDmgVolume() { XCTAssertFalse(check("/Volumes/TermHere 1.0/TermHere.app")) }
    func testBuildFolder() { XCTAssertFalse(check("/Users/x/Work/TermHere/build/TermHere.app")) }
    func testSimilarPrefixSystem() { XCTAssertFalse(check("/ApplicationsFoo/TermHere.app")) }
    func testSimilarPrefixUser() { XCTAssertFalse(check("/Users/leether/ApplicationsX/TermHere.app")) }
    func testTranslocation() {
        XCTAssertFalse(check("/private/var/folders/ab/xyz/T/AppTranslocation/UUID/d/TermHere.app"))
    }
    func testDotDotEscape() { XCTAssertFalse(check("/Applications/../Volumes/X/TermHere.app")) }
}
