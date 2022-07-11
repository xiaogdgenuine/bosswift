//
//  KeyboardShortcuts.swift
//  Bosswift
//
//  Created by huikai on 2022/6/17.
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleQuickLaunch = Self("toggleQuickLaunch", default: KeyboardShortcuts.Shortcut(.space, modifiers: [.option]))
    static let toggleDashboard = Self("toggleDashboard", default: KeyboardShortcuts.Shortcut(.d, modifiers: [.shift, .command]))
}
