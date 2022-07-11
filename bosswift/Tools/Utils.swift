import Foundation
import Cocoa
import SwiftUI

func addPathComponentIfNotSet(_ pathComponent: String) {
    // If path component already exists in PATH, return.
    let path = ProcessInfo.processInfo.environment["PATH"]!
    let pathComponents = path.split(separator: ":")
    if pathComponents.contains(Substring(pathComponent)) {
        return
    }
    // Otherwise, prepend path component to PATH via setenv.
    let newPath = "\(pathComponent):\(path)"
    setenv("PATH", newPath, 1)
}

func shellTask(_ command: String, cwd: String? = nil, needOutput: Bool = true) -> ShellTask {
    let task = Process()

    addPathComponentIfNotSet("/usr/local/bin")
    addPathComponentIfNotSet("\(FileManager.default.homeDirectoryForCurrentUser.path)/.rbenv/shims")
    if let cwd = cwd {
        task.currentDirectoryPath = cwd
    }
    task.launchPath = "/usr/bin/env"
    task.arguments = command.split(separator: " ").map(String.init)

    let shellTask = ShellTask(task: task, command: command, needOutput: needOutput)

    return shellTask
}

@discardableResult
func shellImmediately(_ command: String, cwd: String? = nil) -> (Int32, String?) {
    let task = Process()
    let pipe = Pipe()

    if let cwd = cwd {
        task.currentDirectoryPath = cwd
    }
    task.standardOutput = pipe
    task.standardError = pipe
    task.launchPath = "/usr/bin/env"
    task.arguments = command.split(separator: " ").map(String.init)

    task.launch()
    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines)

    return (task.terminationStatus, output)
}

func generateHighlightableText(keyword: String, candidate: String) -> HighlightableText? {
    guard let matchRange = candidate.lowercased().range(of: keyword.lowercased()) else {
        return nil
    }

    let begin = candidate[candidate.startIndex..<matchRange.lowerBound]
    let middle = candidate[matchRange.lowerBound..<min(matchRange.upperBound, candidate.endIndex)]
    var end = ""
    if matchRange.upperBound < candidate.endIndex {
        end = String(candidate[matchRange.upperBound..<candidate.endIndex])
    }

    return HighlightableText(begin: String(begin), middle: String(middle), end: String(end))
}

func doAppleScript(script: String) {
    let task = Process()
    task.launchPath = "/usr/bin/osascript"
    task.arguments = ["-e", script]
    task.launch()
    task.waitUntilExit()
}
