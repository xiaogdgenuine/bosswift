//
//  Command.swift
//  Bosswift
//
//  Created by huikai on 2022/6/16.
//

import Foundation
import AppKit
import SwiftUI

var commandIdCounter = 0

struct Command: Equatable, Codable, Identifiable {
    var id: Int = -1
    var commandKeyword: String
    var commandIconRefreshCounter = 0
    var displayName: String
    var enabled = true
    var playSoundWhenDone = false
    var playSoundWhenFailed = false
    var scripts: [CommandScript] = []
    var runSilently = false
    var retryTimes = 0
    var watchedFiles: [String] = []

    init(id: Int, commandKeyword: String, displayName: String, enabled: Bool = true, playSoundWhenDone: Bool = false, playSoundWhenFailed: Bool = false, scripts: [CommandScript], runSilently: Bool = false, retryTimes: Int = 0, watchedFiles: [String] = [], commandIconRefreshCounter: Int = 0) {
        self.id = id
        self.commandKeyword = commandKeyword
        self.displayName = displayName
        self.enabled = enabled
        self.playSoundWhenDone = playSoundWhenDone
        self.playSoundWhenFailed = playSoundWhenFailed
        self.scripts = scripts
        self.runSilently = runSilently
        self.retryTimes = retryTimes
        self.watchedFiles = watchedFiles
        self.commandIconRefreshCounter = commandIconRefreshCounter
        if let icon = NSImage(contentsOf: Storage.commandsDirectory.appendingPathComponent("\(id).png", isDirectory: false)) {
            DataSource.shared.commandIcons[id] = icon
        }
    }

    var executableScript: String {
        var scriptStr = ""
        for script in scripts {
            switch script {
            case .script(let scriptContent):
                scriptStr += scriptContent
            }
        }

        return scriptStr
    }

    static func == (lhs: Command, rhs: Command) -> Bool {
        lhs.id == rhs.id &&
        lhs.commandKeyword == rhs.commandKeyword &&
        lhs.commandIconRefreshCounter == rhs.commandIconRefreshCounter &&
        lhs.displayName == rhs.displayName &&
        lhs.enabled == rhs.enabled &&
        lhs.playSoundWhenDone == rhs.playSoundWhenDone &&
        lhs.playSoundWhenFailed == rhs.playSoundWhenFailed &&
        lhs.scripts == rhs.scripts &&
        lhs.runSilently == rhs.runSilently &&
        lhs.retryTimes == rhs.retryTimes &&
        lhs.watchedFiles == rhs.watchedFiles
    }

    var universalId: String {
        "Bosswift_Universal_\(id)"
    }
}

enum CommandScript: Codable, Equatable {
    case script(content: String)
}
