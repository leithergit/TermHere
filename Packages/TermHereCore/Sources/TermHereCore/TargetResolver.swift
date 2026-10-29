import Foundation

public enum TargetResolver {
    public static func resolve(context: MenuContext, targetedURL: URL?, selectedURLs: [URL],
                               isDirectory: (URL) -> Bool) -> URL? {
        switch context {
        case .container:
            return targetedURL.map(absolute)
        case .items:
            guard let first = selectedURLs.first.map(absolute) else { return targetedURL.map(absolute) }
            return isDirectory(first) ? first : first.deletingLastPathComponent()
        }
    }

    /// 相对 URL 的 base 若未标记为目录，deletingLastPathComponent 会丢掉 base，
    /// 所以先把 base 当目录拼成绝对路径。
    private static func absolute(_ url: URL) -> URL {
        guard let base = url.baseURL else { return url }
        return URL(fileURLWithPath: base.path, isDirectory: true)
            .appendingPathComponent(url.relativePath)
    }
}
