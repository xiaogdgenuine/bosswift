//
//  Storage.swift
//  Bosswift
//
//  Created by huikai on 2022/6/24.
//

import Foundation
import AppKit

enum Storage {

    static let applicationDirectory = (try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)).appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
    static let commandsDirectory = applicationDirectory.appendingPathComponent("commands")
    static let commandRCFilePath = commandsDirectory.appendingPathComponent(".bosswiftrc", isDirectory: false)
    static let tempDirectory = applicationDirectory.appendingPathComponent("tmp")
    static private var iconIdCounter = 0

    static func setup() {
        print("Command store at: ", commandsDirectory.path.removingPercentEncoding!)
        try? FileManager.default.createDirectory(atPath: commandsDirectory.path, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: tempDirectory.path, withIntermediateDirectories: true)
    }

    static func createCommandScriptIfNeeded(taskId: String, command: Command, branch: Branch? = nil) -> String {
        let finalScriptURL = commandsDirectory.appendingPathComponent("\(taskId).sh", isDirectory: false)
        if FileManager.default.fileExists(atPath: finalScriptURL.path) {
            return finalScriptURL.path
        }
        
        let encodedTaskId = taskId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? taskId

        var environments = ""
        if let branch = branch {
            environments = """
            source '\(commandRCFilePath.path)'
            BOSSWIFT_WORK_FOLDER="\(appSetting.baseFolder ?? "")"
            BOSSWIFT_PROJECT_NAME="\(branch.project.name)"
            BOSSWIFT_BRANCH_NAME="\(branch.name)"
            BOSSWIFT_WORKTREE_PATH="\(branch.folder)"
            BOSSWIFT_DEFAULT_WORKTREE_PATH="\(branch.project.folder)"
            BOSSWIFT_XCODE_DERIVED_PATH="\(branch.derivedDataPath)"
            BOSSWIFT_XCODE_WORKSPACE_FILE="\(branch.workspace ?? "")"
            BOSSWIFT_XCODE_PROJECT_FILE="\(branch.xcodeproj ?? "")"
            """
        }


        let port = appSetting.taskServerListenPort
        let setup =
            """
            set -e

            \(environments)
            curl -s "http://127.0.0.1:\(port)/start?taskId=\(encodedTaskId)" > /dev/null

            \(branch == nil ? "" : "cd \"${BOSSWIFT_WORKTREE_PATH}\"")

            trap abort SIGHUP SIGINT SIGQUIT SIGABRT EXIT

            abort() {
              RESULT=$?
              if [[ $RESULT -ne 0 ]]
              then
                echo "\\x1b[31mCommand exit with code ${RESULT}"
                curl -s "http://127.0.0.1:\(port)/stop?taskId=\(encodedTaskId)&failed=true" > /dev/null

                read -n1 -p "Retry? <y/n> " prompt
                if [[ $prompt == "y" || $prompt == "Y" ]]
                then
                  curl -s "http://127.0.0.1:\(port)/restart?taskId=\(encodedTaskId)" > /dev/null
                else
                  curl -s "http://127.0.0.1:\(port)/stop?taskId=\(encodedTaskId)" > /dev/null
                fi
                exit 0
              else
                curl -s \"http://127.0.0.1:\(port)/stop?taskId=\(encodedTaskId)\" > /dev/null
                exit 0
              fi
            }
            """
        let finalScript =
            """
            \(setup)
            \(command.executableScript)
            """

        try? finalScript.write(to: finalScriptURL, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions:0o777], ofItemAtPath: finalScriptURL.path)

        return finalScriptURL.path
    }

    static func deleteAllScripts() {
        let commandFiles = (try? FileManager.default.contentsOfDirectory(at: commandsDirectory, includingPropertiesForKeys: nil)) ?? []

        commandFiles.forEach { filePath in
            if filePath.lastPathComponent.hasSuffix(".sh") {
                print("Deleting \(filePath.path)")
                try? FileManager.default.removeItem(at: filePath)
            }
        }
    }

    static func deleteAffectedScripts(command: Command) {
        let commandFiles = (try? FileManager.default.contentsOfDirectory(at: commandsDirectory, includingPropertiesForKeys: nil)) ?? []

        commandFiles.forEach { filePath in
            if filePath.lastPathComponent.hasPrefix("Bosswift_") && filePath.lastPathComponent.hasSuffix("_\(command.id).sh") {
                print("Deleting \(filePath.path)")
                try? FileManager.default.removeItem(at: filePath)
            }
        }
    }

    static func createTempCommandScriptIfNeeded(taskId: String, script: String) -> String {
        let finalScriptURL = tempDirectory.appendingPathComponent("\(taskId).sh", isDirectory: false)
        if FileManager.default.isExecutableFile(atPath: finalScriptURL.path.removingPercentEncoding ?? finalScriptURL.path) {
            return finalScriptURL.path
        }
        
        try? script.write(to: finalScriptURL, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions:0o777], ofItemAtPath: finalScriptURL.path)

        return finalScriptURL.path
    }

    static func iconPathFor(command: Command) -> URL {
        let iconURL = commandsDirectory.appendingPathComponent("\(command.id).png", isDirectory: false)

        return iconURL
    }

    static func storeTempCommandIcon(image: NSImage) -> URL? {
        iconIdCounter += 1
        let imageURL = tempDirectory.appendingPathComponent("\(iconIdCounter).png", isDirectory: false)

        do {
            try image.png?.write(to: imageURL)
            return imageURL
        } catch {
            return nil
        }
    }

    static func storeCommandIcon(command: Command, tempIconPath: URL) {
        let from = tempIconPath
        let to = iconPathFor(command: command)

        do {
            if to.path != from.path {
                try? FileManager.default.removeItem(at: to)
                try FileManager.default.moveItem(at: from, to: to)
            }
        } catch {
            print("Fail to store icon: ", error.localizedDescription)
        }
        clearTemporaryCommandIcons()
    }

    static func removeCommandIcon(command: Command) {
        try? FileManager.default.removeItem(at: iconPathFor(command: command))
    }

    static func clearTemporaryCommandIcons() {
        try? FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil).forEach { url in
            if url.path.lowercased().hasSuffix(".png") {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}

