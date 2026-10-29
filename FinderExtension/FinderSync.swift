import Cocoa
import FinderSync
import UserNotifications
import os
import TermHereCore

/// representedObject 需要引用类型；包一层记录菜单弹出时的 FIMenuKind。
private final class ContextBox {
    let context: MenuContext
    init(_ context: MenuContext) { self.context = context }
}

final class FinderSync: FIFinderSync {
    private static let log = Logger(subsystem: "com.xionggaoli.termhere", category: "extension")
    private static let scriptName = "TermHere.scpt"

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    // MARK: Menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let context: MenuContext
        switch menuKind {
        case .contextualMenuForContainer: context = .container
        case .contextualMenuForItems: context = .items
        default: return nil
        }
        let menu = NSMenu(title: "")
        let icon = Self.iTermIcon()
        for (title, mode) in [("New iTerm2 Window Here", OpenMode.window), ("New iTerm2 Tab Here", .tab)] {
            let item = NSMenuItem(title: title, action: #selector(openHere(_:)), keyEquivalent: "")
            item.target = self
            item.tag = mode.rawValue
            item.representedObject = ContextBox(context)
            item.image = icon
            menu.addItem(item)
        }
        return menu
    }

    private static func iTermIcon() -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.googlecode.iterm2")
        else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 16, height: 16)
        return icon
    }

    // MARK: Action

    @objc private func openHere(_ sender: NSMenuItem) {
        guard let mode = OpenMode(rawValue: sender.tag) else { return }
        let controller = FIFinderSyncController.default()
        let selected = controller.selectedItemURLs() ?? []
        let context = (sender.representedObject as? ContextBox)?.context ?? .container
        guard let dir = TargetResolver.resolve(
            context: context, targetedURL: controller.targetedURL(), selectedURLs: selected,
            isDirectory: { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false })
        else {
            report("Could not determine the target folder.")
            return
        }
        run(mode: mode, command: ScriptInvocation.command(for: dir))
    }

    private func run(mode: OpenMode, command: String) {
        guard let scriptsDir = try? FileManager.default.url(
            for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        else {
            report("Application Scripts directory unavailable. Open the TermHere app once.")
            return
        }
        let url = scriptsDir.appendingPathComponent(Self.scriptName)
        do {
            let task = try NSUserAppleScriptTask(url: url)
            task.execute(withAppleEvent: ScriptInvocation.event(mode: mode, command: command)) { [weak self] _, error in
                if let error { self?.report("Failed to drive iTerm2: \(error.localizedDescription)") }
            }
        } catch {
            report("Cannot load \(Self.scriptName): \(error.localizedDescription). Open the TermHere app to install it.")
        }
    }

    // MARK: Errors

    /// os_log 为主；系统通知尽力而为（未授权则静默）。
    private func report(_ message: String) {
        Self.log.error("\(message, privacy: .public)")
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                Self.post(message, via: center)
            case .notDetermined:
                center.requestAuthorization(options: [.alert]) { granted, _ in
                    if granted { Self.post(message, via: center) }
                }
            default:
                break
            }
        }
    }

    private static func post(_ message: String, via center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = "TermHere"
        content.body = message
        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}
