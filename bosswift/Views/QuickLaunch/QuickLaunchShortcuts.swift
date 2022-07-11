//
//  QuickLaunchShortcuts.swift
//  Bosswift
//
//  Created by huikai on 2022/6/28.
//

import SwiftUI

struct QuickLaunchShortcuts: View {
    let executeItemAt: (Int) -> Void

    var body: some View {
        VStack {
            Button("") { executeItemAt(0) }.keyboardShortcut("1", modifiers: .command)
            Button("") { executeItemAt(1) }.keyboardShortcut("2", modifiers: .command)
            Button("") { executeItemAt(2) }.keyboardShortcut("3", modifiers: .command)
            Button("") { executeItemAt(3) }.keyboardShortcut("4", modifiers: .command)
            Button("") { executeItemAt(4) }.keyboardShortcut("5", modifiers: .command)
            Button("") { executeItemAt(5) }.keyboardShortcut("6", modifiers: .command)
            Button("") { executeItemAt(6) }.keyboardShortcut("7", modifiers: .command)
            Button("") { executeItemAt(7) }.keyboardShortcut("8", modifiers: .command)
            Button("") { executeItemAt(8) }.keyboardShortcut("9", modifiers: .command)
        }.hidden().frame(width: 0, height: 0)
    }
}
