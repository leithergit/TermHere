import Foundation

public enum InstallLocation {
    /// Finder 扩展只有在 Applications 目录下运行的 App 才会被 PlugInKit 可靠注册。
    /// 按路径组件比较（而非字符串前缀），避免 /ApplicationsFoo 之类误判。
    public static func isInApplicationsFolder(bundleURL: URL, homeDirectory: URL) -> Bool {
        let bundle = bundleURL.standardizedFileURL.pathComponents
        let roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            homeDirectory.appendingPathComponent("Applications", isDirectory: true),
        ].map { $0.standardizedFileURL.pathComponents }
        return roots.contains { root in
            bundle.count > root.count && Array(bundle.prefix(root.count)) == root
        }
    }
}
