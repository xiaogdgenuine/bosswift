import SwiftUI
import AppKit
import KeyboardShortcuts

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController!
    static var shared: AppDelegate!
    var folderObserver: FileChangeObserver?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.shared = self

        Storage.setup()
        DataSource.shared.setup()
        TaskScheduler.shared.setup()
        TaskMonitorServer.start()

        clearCommandScripts()
        setupDefaultCommands()

        let maxUniversalCommandId = appSetting.universalCommands.max { $0.id < $1.id }?.id ?? 0
        let maxProjectCommandId = appSetting.projectCommands.max { $0.id < $1.id }?.id ?? 0
        commandIdCounter = max(maxUniversalCommandId, maxProjectCommandId)

        statusBarController = createNewStatusBar()

        if !AppEnvironment.isInPreviewMode {
            KeyboardShortcuts.onKeyDown(for: .toggleQuickLaunch) {
                if !appSetting.onboardingFinished {
                    self.statusBarController.showOnBoardingWindow()
                } else {
                    self.statusBarController.toggleQuickLaunchWindow()
                }
            }

            KeyboardShortcuts.onKeyDown(for: .toggleDashboard) {
                if !appSetting.onboardingFinished {
                    self.statusBarController.showOnBoardingWindow()
                } else {
                    self.statusBarController.toggleDashboardWindow()
                }
            }

            if !appSetting.onboardingFinished {
                self.statusBarController.showOnBoardingWindow()
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationWillResignActive(_ notification: Notification) {
        statusBarController.hidePopover()
    }

    private func createNewStatusBar() -> StatusBarController {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 500, height: 580)
        popover.behavior = .transient

        let newStatusBar = StatusBarController(popover)

        return newStatusBar
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        TaskScheduler.shared.terminateAllTasks()

        return .terminateNow
    }

    func clearCommandScripts() {
        let files = (try? FileManager.default.contentsOfDirectory(at: Storage.commandsDirectory, includingPropertiesForKeys: nil)) ?? []
        files.forEach { url in
            if url.path.hasSuffix(".sh") {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    func setupDefaultCommands() {
        guard !appSetting.onboardingFinished else {
            return
        }

        let uninversalCommands = CommandTemplates.universalTemplates.flatMap {$0.commands}
        let projectCommands = CommandTemplates.templates.flatMap {$0.commands}
        appSetting.universalCommands = uninversalCommands
        appSetting.projectCommands = projectCommands

        if let assetsFolderUrl = Bundle.main.resourceURL?.appendingPathComponent("Assets", isDirectory: true),
            let assetsFileNames = try? FileManager.default.contentsOfDirectory(atPath: assetsFolderUrl.path) {
                assetsFileNames.forEach { fileName in
                    let fileNameWithoutExt = fileName.pathWithoutExt
                    if let universalCommand = uninversalCommands.first { $0.commandKeyword == fileNameWithoutExt } {
                        try? FileManager.default.removeItem(atPath: "\(Storage.commandsDirectory.path)/\(universalCommand.id).png")
                        try? FileManager.default.copyItem(
                            atPath: "\(assetsFolderUrl.path)/\(fileName)",
                            toPath: "\(Storage.commandsDirectory.path)/\(universalCommand.id).png"
                        )
                        DataSource.shared.commandIcons[universalCommand.id] = NSImage(contentsOf: Storage.iconPathFor(command: universalCommand))
                    }

                    if let projectCommand = projectCommands.first { $0.commandKeyword == fileNameWithoutExt } {
                        try? FileManager.default.removeItem(atPath: "\(Storage.commandsDirectory.path)/\(projectCommand.id).png")
                        try? FileManager.default.copyItem(
                            atPath: "\(assetsFolderUrl.path)/\(fileName)",
                            toPath: "\(Storage.commandsDirectory.path)/\(projectCommand.id).png"
                        )
                        DataSource.shared.commandIcons[projectCommand.id] = NSImage(contentsOf: Storage.iconPathFor(command: projectCommand))
                    }
                }
        }
    }
}
