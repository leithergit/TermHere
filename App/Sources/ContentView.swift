import SwiftUI
import FinderSync
import TermHereCore

private let installedCopyURL = URL(fileURLWithPath: "/Applications/TermHere.app")

struct ContentView: View {
    @State private var extensionEnabled = FIFinderSyncController.isExtensionEnabled
    @State private var scriptInstalled = ScriptInstaller.isInstalled
    @State private var message: String?
    @State private var inApplications = InstallLocation.isInApplicationsFolder(
        bundleURL: Bundle.main.bundleURL, homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
    @State private var showMoveAlert = false

    private var currentPath: String { Bundle.main.bundleURL.standardizedFileURL.path }
    private var otherCopyExists: Bool {
        FileManager.default.fileExists(atPath: installedCopyURL.path)
            && installedCopyURL.standardizedFileURL.path != currentPath
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TermHere").font(.largeTitle).bold()
            Text("Adds “New iTerm2 Window Here” and “New iTerm2 Tab Here” to Finder's right-click menu.")
                .foregroundStyle(.secondary)

            if !inApplications {
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text("Location: \(currentPath) (not in Applications)")
                        .textSelection(.enabled)
                }
            }
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
            if inApplications {
                PluginRegistrar.register { refresh() }
            } else {
                showMoveAlert = true
            }
        }
        .alert("Move TermHere to Applications", isPresented: $showMoveAlert) {
            if otherCopyExists {
                Button("Open the Copy in Applications") { openInstalledCopy() }
                    .keyboardShortcut(.defaultAction)
            } else {
                Button("Show in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
                }
                .keyboardShortcut(.defaultAction)
            }
            Button("Continue Here", role: .cancel) {}
        } message: {
            Text("The Finder extension only works reliably when TermHere runs from the Applications folder.\n\nCurrent location:\n\(currentPath)")
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

    private func openInstalledCopy() {
        // Same bundle ID as this process: without a new instance, LaunchServices
        // just "opens" us again and we'd terminate with no copy running.
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: installedCopyURL,
                                           configuration: configuration) { _, error in
            DispatchQueue.main.async {
                if let error {
                    message = "Cannot open the copy in Applications: \(error.localizedDescription)"
                } else {
                    NSApp.terminate(nil)
                }
            }
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
