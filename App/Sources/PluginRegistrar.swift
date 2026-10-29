import Foundation
import os

enum PluginRegistrar {
    private static let log = Logger(subsystem: "com.xionggaoli.termhere", category: "pluginkit")

    /// 向 PlugInKit 注册内嵌扩展。只做 -a，绝不 -e，避免改动用户的启用选择。
    static func register(completion: @escaping @Sendable () -> Void) {
        guard let appex = Bundle.main.builtInPlugInsURL?.appendingPathComponent("FinderExtension.appex") else {
            log.error("builtInPlugInsURL is nil")
            completion()
            return
        }
        DispatchQueue.global(qos: .utility).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
            process.arguments = ["-a", appex.path]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            do {
                try process.run()
                let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                process.waitUntilExit()
                log.info("pluginkit -a \(appex.path, privacy: .public) exit=\(process.terminationStatus) \(output, privacy: .public)")
            } catch {
                log.error("pluginkit failed to run: \(error.localizedDescription, privacy: .public)")
            }
            DispatchQueue.main.async { completion() }
        }
    }
}
