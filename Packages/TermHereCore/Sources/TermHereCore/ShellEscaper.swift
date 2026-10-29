import Foundation

public enum ShellEscaper {
    /// 单引号内除 ' 外无特殊字符，故只需把 ' 替换为 '\'' 。
    public static func singleQuoted(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
