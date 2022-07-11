//
//  TaskMonitor.swift
//  Bosswift
//
//  Created by huikai on 2022/6/15.
//

import AppKit
import Foundation
import Combine

enum ScreenMonitor {

    static func getScreenUniqueId(screenName: String) -> String {
        let pipe = Pipe()

        let screen = Process()
        setenv("TERM", "xterm-256color", 1)
        screen.launchPath = "/usr/bin/screen"
        screen.arguments = ["-ls"]
        screen.standardOutput = pipe

        let grep = Process()
        grep.launchPath = "/usr/bin/grep"
        grep.arguments = [screenName]
        grep.standardInput = pipe

        let out = Pipe()
        grep.standardOutput = out

        screen.launch()
        grep.launch()
        grep.waitUntilExit()

        let data = out.fileHandleForReading.readDataToEndOfFile()

        if let output = String(data: data, encoding: String.Encoding.utf8)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), let screenId = output.split(separator: "\t")[safe: 0] {
            return String(screenId)
        }

        return screenName
    }

    static func activeScreen(screenSessionName: String) {
        let script = """
            tell application "Terminal"
                do script "screen -d -r \(screenSessionName);exit"
                activate
            end tell
        """
        doAppleScript(script: script)
        clearDeadTerminalWindows()
    }

    static func terminateScreen(screenSessionName: String, scriptPath: String) {
        let killScreen = Process()
        killScreen.launchPath = "/usr/bin/screen"
        killScreen.arguments = ["-XS", screenSessionName, "quit"]
        killScreen.launch()
        killScreen.waitUntilExit()

        if let scriptProcessGroupId = getTaskScriptProcessGroupId(scriptPath: scriptPath) {
            let killScript = Process()
            killScript.launchPath = "/usr/bin/env"
            killScript.arguments = ["kill", scriptProcessGroupId]
            killScript.launch()
            killScript.waitUntilExit()
        }

        clearDeadTerminalWindows()
    }

    static func getTaskScriptProcessGroupId(scriptPath: String) -> String? {
        // Get the script process group id by this command
        //        ps -a -o pgid,command | grep '[s]h $scriptPath' | awk '{print $1}'
        let psPipe = Pipe()
        let grepPipe = Pipe()
        let awkPipe = Pipe()

        let ps = Process()
        ps.launchPath = "/bin/ps"
        ps.arguments = ["-a", "-o", "pgid,command"]
        ps.standardOutput = psPipe

        let grep = Process()
        grep.launchPath = "/usr/bin/grep"
        grep.arguments = ["[s]h \(scriptPath)"]
        grep.standardInput = psPipe
        grep.standardOutput = grepPipe

        let awk = Process()
        awk.launchPath = "/usr/bin/awk"
        awk.arguments = ["{print $1}"]
        awk.standardInput = grepPipe
        awk.standardOutput = awkPipe

        ps.launch()
        grep.launch()
        awk.launch()
        awk.waitUntilExit()

        let data = awkPipe.fileHandleForReading.readDataToEndOfFile()

        if let pgid = String(data: data, encoding: String.Encoding.utf8)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
            return String(pgid)
        }

        return nil
    }

    static func runTemporaryScreen(scritp: String) {
        let script = """
            tell application "Terminal"
                do script "\(scritp)"
                activate
            end tell
        """
        doAppleScript(script: script)
        clearDeadTerminalWindows()
    }

    static func clearDeadTerminalWindows() {
        let script = """
            tell application "Terminal"
                delay 0.5
                close (every window whose contents contains "[remote detached]")
                close (every window whose contents contains "[screen is terminating]")
                close (every window whose processes = {})
            end tell
        """
        doAppleScript(script: script)
    }

    static var appleScriptPermissionEnabled = PassthroughSubject<Bool, Never>()
    static func testAppleScriptCapability() -> Bool {
        let testScript = """
            tell application "Terminal"
                do shell script "echo Test AppleScript Permission"
            end tell
        """
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", testScript]
        task.launch()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            appleScriptPermissionEnabled.send(false)
            return false
        }

        if !appSetting.firstCommandSuccessfullyStarted {
            appSetting.firstCommandSuccessfullyStarted = true
            TaskScheduler.shared.setupDefaultShellEnvironments()
        }
        return true
    }

}

