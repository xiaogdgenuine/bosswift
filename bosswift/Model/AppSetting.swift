import Foundation
import KeyboardShortcuts
import Combine
import AppKit

let appSetting = AppSetting()

class AppSetting: ObservableObject {
    let taskServerListenPort: UInt16 = 7893

    @UserDefaultSetting("BASE_FOLDER")
    var baseFolder: String? = nil {
        didSet {
            DataSource.shared.updateProjectRootURL()
            // $BOSSWIFT_WORK_FOLDER changed, all scripts need to be regenerate
            Storage.deleteAllScripts()
        }
    }

    @UserDefaultSetting("WORKTREE_FOLDER")
    var worktreeFolder: String? = "../Bosswift"

    @UserDefaultSetting("ONBOARDING_FINISHED")
    var onboardingFinished = false

    @UserDefaultSetting("FIRST_COMMAND_SUCCESSFULLY_STARTED")
    var firstCommandSuccessfullyStarted = false

    @UserDefaultSetting("EXCLUDED_PROJECTS")
    var excludedProjects: [String: Bool] = [:] {
        didSet { excludedProjects$ = excludedProjects }
    }

    @UserDefaultSetting("PINNED_PROJECTS")
    var pinnedProjects: [String] = [] {
        didSet {
            pinnedProjects$ = pinnedProjects
            DataSource.shared.sortProjects()
        }
    }

    @UserDefaultSetting("PROJECTS_NAME_MAPPINGS")
    var projectNameMappings: [String: String] = [:] {
        didSet { projectNameMappings$ = projectNameMappings }
    }

    @UserDefaultSetting("QUICK_LAUNCH_HOT_KEY", useJson: true)
    var quickLaunchHotKey = KeyboardShortcuts.Shortcut(.space, modifiers: [.option])

    @UserDefaultSetting("DASHBOARD_HOT_KEY", useJson: true)
    var dashboardHotKey = KeyboardShortcuts.Shortcut(.space, modifiers: [.option, .control])

    @UserDefaultSetting("UNIVERSAL_COMMANDS", useJson: true)
    var universalCommands: [Command] = [] {
        didSet { universalCommands$ = universalCommands }
    }

    @UserDefaultSetting("PROJECT_COMMANDS", useJson: true)
    var projectCommands: [Command] = [] {
        didSet {
            projectCommands$ = projectCommands
        }
    }

    @Published var excludedProjects$: [String: Bool] = [:]
    @Published var projectNameMappings$: [String: String] = [:]
    @Published var pinnedProjects$: [String] = []
    @Published var projectCommands$: [Command] = []
    @Published var universalCommands$: [Command] = []

    init() {
        excludedProjects$ = excludedProjects
        projectNameMappings$ = projectNameMappings
        pinnedProjects$ = pinnedProjects
        projectCommands$ = projectCommands
        universalCommands$ = universalCommands
    }

    func refreshCommandIcons() {
        func loadCmdIcon(_ command: Command) {
            if let icon = NSImage(contentsOf: Storage.iconPathFor(command: command)) {
                DataSource.shared.commandIcons[command.id] = icon
            }
        }
        universalCommands.forEach(loadCmdIcon)
        projectCommands.forEach(loadCmdIcon)
    }
}
