//
//  TaskScheduler.swift
//  Bosswift
//
//  Created by huikai on 2022/6/14.
//

import Foundation
import Carbon
import AppKit
import Combine

let updateStatusInterval: TimeInterval = 1.0

class TaskScheduler: ObservableObject {
    static let shared = TaskScheduler()
    @Published var runningTasks: [String:RunningTask] = [:]

    private var screenCounter = 0
    private var taskStatusUpdateTimer: Timer?

    func setup() {
        taskStatusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.runningTasks.forEach { task in
                if task.value.status == .running {
                    task.value.elapsedSeconds += 1
                }
            }
        }
        taskStatusUpdateTimer?.fire()

        setupDefaultShellEnvironments()
    }

    func generateNewScreenId() -> String {
        screenCounter &+= 1
        return "Bosswift_\(screenCounter)"
    }

    func startNewTask(taskId: String, command: Command, branch: Branch? = nil, testAppleScriptCapability: Bool = true) {
        let runningTask = runningTasks[taskId]
        guard runningTask == nil || runningTask?.status == .failed else {
            runningTask?.activeScreen()
            return
        }

        if testAppleScriptCapability && !ScreenMonitor.testAppleScriptCapability() {
            return
        }

        // Kill old screen
        runningTask?.terminateScreen()
        let newTask = RunningTask(taskId: taskId, branch: branch, command: command)
        runningTasks[taskId] = newTask

        let scriptPath = Storage.createCommandScriptIfNeeded(taskId: taskId, command: command, branch: branch)
        let bosswiftScreenRCUrl = Storage.commandsDirectory.appendingPathComponent(".bosswift_screenrc")
        if !FileManager.default.fileExists(atPath: bosswiftScreenRCUrl.path) {
            // Make sure screen is scrollable
            let bosswiftRCConfig = """
            defscrollback 10000
            termcapinfo xterm* ti@:te@
            """
            try? bosswiftRCConfig.write(to: bosswiftScreenRCUrl, atomically: true, encoding: .utf8)
        }

        let newScreenName = generateNewScreenId()
        let task = Process()
        task.launchPath = "/usr/bin/screen"
        task.arguments = ["-c", bosswiftScreenRCUrl.path, "-dmS", newScreenName, "sh", scriptPath]
        task.launch()
        task.waitUntilExit()

        newTask.scriptPath = scriptPath
        newTask.screenSessionName = ScreenMonitor.getScreenUniqueId(screenName: newScreenName)

        if !command.runSilently {
            newTask.activeScreen()
        }
    }

    func startTemporaryTask(script: String) {
        if !ScreenMonitor.testAppleScriptCapability() {
            return
        }

        ScreenMonitor.runTemporaryScreen(scritp: script)
    }

    func finishTask(taskId: String) {
        guard let task = runningTasks[taskId] else {
            return
        }

        runningTasks[taskId] = nil
        task.terminateScreen()

        if task.command.playSoundWhenDone {
            NSSound(named: "Purr")?.play()
        }
    }

    func onTaskStarted(taskId: String) {
        print("Task \(taskId) started")
        runningTasks[taskId]?.status = .running
    }

    func restartTask(taskId: String) {
        guard let runningTask = runningTasks[taskId] else {
            return
        }

        print("Task \(taskId) re-started")
        runningTask.terminateScreen()
        // Wait for previous task finish it's screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.startNewTask(taskId: taskId, command: runningTask.command, branch: runningTask.branch, testAppleScriptCapability: false)
        }
    }

    func onTaskStopped(taskId: String, isFailed: Bool) {
        guard let task = runningTasks[taskId] else {
            return
        }

        print("Task \(taskId) \(isFailed ? "failed" : "finished")")

        if isFailed {
            task.status = .failed
            if task.command.playSoundWhenFailed {
                NSSound(named: "Ping")?.play()
            }
        } else {
            finishTask(taskId: taskId)
        }
    }

    func terminateAllTasks() {
        runningTasks.values.forEach { task in
            task.terminateScreen()
        }
        runningTasks = [:]
    }

    func terminateTask(relatedTo command: Command) {
        let tasks = runningTasks.values.filter { $0.command.id == command.id }
        tasks.forEach { task in
            task.terminateScreen()
            runningTasks[task.taskId] = nil
        }
    }

    func terminateTask(relatedTo branch: Branch) {
        let tasks = runningTasks.values.filter { $0.branch === branch }
        tasks.forEach { task in
            task.terminateScreen()
            runningTasks[task.taskId] = nil
        }
    }

    func setupDefaultShellEnvironments() {
        guard appSetting.onboardingFinished else {
            return
        }

        let script = """
        tell application "Terminal"
            do script "echo 'Syncing latest Terminal Environment variables....'; printenv > '\(Storage.commandRCFilePath.path)' && echo 'Sync latest Terminal Environment variables success!!!!!';exit"

            delay 0.5
            repeat with w in windows
                set lastW to w
            end repeat
            set visible of lastW to false
        end tell
        """
        doAppleScript(script: script)
        ScreenMonitor.clearDeadTerminalWindows()
    }
}
