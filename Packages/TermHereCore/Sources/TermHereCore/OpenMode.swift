import Foundation

public enum OpenMode: Int {
    case window = 1, tab = 2

    /// AppleScript 子程序名；AppleScript 按小写匹配 handler。
    public var handlerName: String {
        switch self {
        case .window: return "openwindow"
        case .tab: return "opentab"
        }
    }
}

public enum MenuContext { case container, items }
