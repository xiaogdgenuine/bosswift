//
//  TaskInfo.swift
//  Bosswift
//
//  Created by huikai on 2022/6/14.
//

import AppKit
import Foundation

class RunningTask: ObservableObject, Identifiable {

    var id: String {
        taskId
    }

    let taskId: String
    let branch: Branch?
    let command: Command
    @Published var status: TaskStatus
    @Published var screenSessionName = ""
    var isHolder = false
    var scriptPath = ""
    let startAt = Date()
    @Published var elapsedSeconds: Int = 0

    init(taskId: String, branch: Branch?, command: Command) {
        self.taskId = taskId
        self.branch = branch
        self.command = command
        self.status = .running
    }

    init() {
        self.taskId = ""
        self.command = Command(id: -1, commandKeyword: "", displayName: "", scripts: [])
        self.status = .running
        self.isHolder = true
        self.branch = nil
    }

    func activeScreen() {
        ScreenMonitor.activeScreen(screenSessionName: screenSessionName)
    }

    func terminateScreen() {
        ScreenMonitor.terminateScreen(screenSessionName: screenSessionName, scriptPath: scriptPath)
    }
}

enum TaskStatus: String {
    case running, failed
}
