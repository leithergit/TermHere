import Foundation

public enum ScriptInvocation {
    // keyASSubroutineName (`snam`) 在 Swift 中未导出，直接用四字符码。
    private static let subroutineNameKeyword: AEKeyword = 0x736E616D

    public static func command(for directory: URL) -> String {
        "cd \(ShellEscaper.singleQuoted(directory.path)) && clear"
    }

    public static func event(mode: OpenMode, command: String) -> NSAppleEventDescriptor {
        let event = NSAppleEventDescriptor(
            eventClass: 0x61736372 /* ascr */,
            eventID: 0x70736272 /* psbr */,
            targetDescriptor: NSAppleEventDescriptor.currentProcess(),
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID))
        event.setParam(NSAppleEventDescriptor(string: mode.handlerName),
                       forKeyword: subroutineNameKeyword)
        let args = NSAppleEventDescriptor.list()
        args.insert(NSAppleEventDescriptor(string: command), at: 1)
        event.setParam(args, forKeyword: AEKeyword(keyDirectObject))
        return event
    }
}
