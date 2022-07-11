//
//  CommandImporter.swift
//  Bosswift
//
//  Created by huikai on 2022/6/30.
//

import Foundation
import ZIPFoundation
import AppKit

enum CommandImporter {
    static func `import`() throws {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.zip]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let zipURL = panel.url {
            let destination = Storage.tempDirectory.appendingPathComponent("bosswift-settings", isDirectory: true)
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.unzipItem(at: zipURL, to: Storage.tempDirectory)

            var universalCommands: [Command] = []
            var projectCommands: [Command] = []
            let universalCommandsFolder = destination.appendingPathComponent("universal_commands", isDirectory: true)
            let projectCommandsFolder = destination.appendingPathComponent("project_commands", isDirectory: true)
            let universalCommandJson = try String(contentsOf: destination.appendingPathComponent("universal_commands/commands.json", isDirectory: false))
            let projectCommandJson = try String(contentsOf: destination.appendingPathComponent("project_commands/commands.json", isDirectory: false))
            if let data = universalCommandJson.data(using: .utf8) {
                universalCommands = (try? jsonDecoder.decode([Command].self, from: data)) ?? []
            }
            if let data = projectCommandJson.data(using: .utf8) {
                projectCommands = (try? jsonDecoder.decode([Command].self, from: data)) ?? []
            }

            universalCommands.forEach { command in
                var updatedCommand = command
                let iconPath = universalCommandsFolder.appendingPathComponent("\(command.id).png", isDirectory: false)

                if let existingCommandIndex = (appSetting.universalCommands.firstIndex {$0.commandKeyword == command.commandKeyword}) {
                    let existingCommand = appSetting.universalCommands[existingCommandIndex]
                    updatedCommand.id = existingCommand.id
                    appSetting.universalCommands[existingCommandIndex] = updatedCommand
                } else {
                    commandIdCounter += 1
                    updatedCommand.id = commandIdCounter
                    appSetting.universalCommands.append(updatedCommand)
                }

                let newIconPath = Storage.iconPathFor(command: updatedCommand)
                if FileManager.default.fileExists(atPath: iconPath.path.removingPercentEncoding ?? iconPath.path) {
                    try? FileManager.default.removeItem(at: newIconPath)
                    try? FileManager.default.moveItem(at: iconPath, to: newIconPath)
                }
            }

            projectCommands.forEach { command in
                var updatedCommand = command
                let iconPath = projectCommandsFolder.appendingPathComponent("\(command.id).png", isDirectory: false)

                if let existingCommandIndex = (appSetting.projectCommands.firstIndex {$0.commandKeyword == command.commandKeyword}) {
                    let existingCommand = appSetting.projectCommands[existingCommandIndex]
                    updatedCommand.id = existingCommand.id
                    appSetting.projectCommands[existingCommandIndex] = updatedCommand
                } else {
                    commandIdCounter += 1
                    updatedCommand.id = commandIdCounter
                    appSetting.projectCommands.append(updatedCommand)
                }

                let newIconPath = Storage.iconPathFor(command: updatedCommand)
                if FileManager.default.fileExists(atPath: iconPath.path.removingPercentEncoding ?? iconPath.path) {
                    try? FileManager.default.removeItem(at: newIconPath)
                    try? FileManager.default.moveItem(at: iconPath, to: newIconPath)
                }
            }
        }
    }
}
