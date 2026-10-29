import SwiftUI
import FinderSync
import TermHereCore

struct ContentView: View {
    @State private var extensionEnabled = FIFinderSyncController.isExtensionEnabled
    @State private var scriptInstalled = ScriptInstaller.isInstalled
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TermHere").font(.largeTitle).bold()
            Text("Adds “New iTerm2 Window Here” and “New iTerm2 Tab Here” to Finder's right-click menu.")
                .foregroundStyle(.secondary)

            row("Finder extension", ok: extensionEnabled,
                okText: "Enabled", badText: "Disabled") {
                Button("Open Extension Settings") {
                    FIFinderSyncController.showExtensionManagementInterface()
                }
            }
            row("Automation script", ok: scriptInstalled,
                okText: "Installed", badText: "Not installed") {
                Button("Reinstall") { reinstall() }
            }
            HStack {
                Button("Test: open iTerm2 tab in ~") { runTest() }
                Button("Refresh") { refresh() }
            }
            if let message {
                Text(message).font(.callout).foregroundStyle(.red).textSelection(.enabled)
            }
        }
        .padding(24)
        .frame(width: 520)
        .onAppear {
            reinstall()
            refresh()
        }
    }

    private func row<Action: View>(_ title: String, ok: Bool, okText: String, badText: String,
                                   @ViewBuilder action: () -> Action) -> some View {
        HStack {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(ok ? .green : .orange)
            Text("\(title): \(ok ? okText : badText)")
            Spacer()
            action()
        }
    }

    private func refresh() {
        extensionEnabled = FIFinderSyncController.isExtensionEnabled
        scriptInstalled = ScriptInstaller.isInstalled
    }

    private func reinstall() {
        do {
            try ScriptInstaller.install()
            message = nil
        } catch {
            message = "Install failed: \(error.localizedDescription)"
        }
        refresh()
    }

    /// 宿主进程用 NSAppleScript 执行同一脚本；自动化权限按进程归属，与扩展分开授权。
    private func runTest() {
        guard let url = ScriptInstaller.bundledURL else { message = "Bundled script missing."; return }
        var compileError: NSDictionary?
        guard let script = NSAppleScript(contentsOf: url, error: &compileError) else {
            message = "Cannot load script: \(compileError ?? [:])"
            return
        }
        let command = ScriptInvocation.command(for: FileManager.default.homeDirectoryForCurrentUser)
        var runError: NSDictionary?
        script.executeAppleEvent(ScriptInvocation.event(mode: .tab, command: command), error: &runError)
        if let runError {
            message = (runError[NSAppleScript.errorMessage] as? String) ?? "\(runError)"
        } else {
            message = nil
        }
    }
}
