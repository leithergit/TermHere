import Foundation
import os

enum ScriptInstaller {
    static let extensionBundleID = "com.xionggaoli.termhere.FinderExtension"
    static let scriptName = "TermHere.scpt"
    private static let log = Logger(subsystem: "com.xionggaoli.termhere", category: "installer")

    static var destinationDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Scripts/\(extensionBundleID)", isDirectory: true)
    }
    static var destinationURL: URL { destinationDirectory.appendingPathComponent(scriptName) }
    static var bundledURL: URL? { Bundle.main.url(forResource: "TermHere", withExtension: "scpt") }

    static var isInstalled: Bool { FileManager.default.fileExists(atPath: destinationURL.path) }

    /// 覆盖安装，保证脚本与 App 版本一致。
    @discardableResult
    static func install() throws -> URL {
        guard let src = bundledURL else { throw InstallError.missingBundledScript }
        let fm = FileManager.default
        try fm.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        if fm.fileExists(atPath: destinationURL.path) { try fm.removeItem(at: destinationURL) }
        try fm.copyItem(at: src, to: destinationURL)
        log.info("Installed script to \(destinationURL.path, privacy: .public)")
        return destinationURL
    }

    enum InstallError: LocalizedError {
        case missingBundledScript
        var errorDescription: String? { "TermHere.scpt is missing from the app bundle." }
    }
}
