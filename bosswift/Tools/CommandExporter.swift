//
//  CommandExporter.swift
//  Bosswift
//
//  Created by huikai on 2022/6/30.
//

import Foundation
import ZIPFoundation
import AppKit

enum CommandExporter {
    static func export() throws {
        let settingFolder = Storage.tempDirectory.appendingPathComponent("bosswift-settings", isDirectory: true)
        let universalCommandFolder = settingFolder.appendingPathComponent("universal_commands", isDirectory: true)
        let projectCommandFolder = settingFolder.appendingPathComponent("project_commands", isDirectory: true)
        try FileManager.default.createDirectory(at: universalCommandFolder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: projectCommandFolder, withIntermediateDirectories: true)


        let universalCommandJson = try jsonEncoder.encode(appSetting.universalCommands)
        if let universalCommandJsonEncoded = String(data: universalCommandJson, encoding: .utf8) {
            try universalCommandJsonEncoded.write(to:
                                                    universalCommandFolder.appendingPathComponent("commands.json", isDirectory: false), atomically: true, encoding: .utf8)
        }

        let projectCommandJson = try jsonEncoder.encode(appSetting.projectCommands)
        if let projectCommandJsonEncoded = String(data: projectCommandJson, encoding: .utf8) {
            try projectCommandJsonEncoded.write(to:
                                                    projectCommandFolder.appendingPathComponent("commands.json", isDirectory: false), atomically: true, encoding: .utf8)
        }

        appSetting.universalCommands.forEach {
            let iconPath = Storage.iconPathFor(command: $0)
            try? FileManager.default.copyItem(at: iconPath, to: universalCommandFolder.appendingPathComponent(iconPath.lastPathComponent, isDirectory: false))
        }

        appSetting.projectCommands.forEach {
            let iconPath = Storage.iconPathFor(command: $0)
            try? FileManager.default.copyItem(at: iconPath, to: projectCommandFolder.appendingPathComponent(iconPath.lastPathComponent, isDirectory: false))
        }

        let tempURL = Storage.tempDirectory.appendingPathComponent("bosswift-settings.zip", isDirectory: false)

        try? FileManager.default.removeItem(at: tempURL)
        try FileManager.default.zipItem(at: settingFolder, to: tempURL)

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "bosswift-settings.zip"
        panel.allowedContentTypes = [.zip]

        if panel.runModal() == .OK, let destination = panel.url {
           try? FileManager.default.removeItem(at: destination)
           try FileManager.default.moveItem(at: tempURL, to: destination)
        }
    }
}
