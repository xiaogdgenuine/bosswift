//
//  SettingsView.swift
//  Bosswift
//
//  Created by huikai on 2022/7/2.
//

import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin

struct SettingsView: View {
    var body: some View {
        VStack {

            LeadingTextView("Hot key for open Bosswift")
                .padding(.top)
            HStack {
                KeyboardShortcuts
                    .Recorder("", name: .toggleQuickLaunch, onChange: { shortcut in
                        if let shortcut = shortcut {
                            appSetting.quickLaunchHotKey = shortcut
                        }
                    })
                    .offset(x: -10)
                Spacer()
            }
            Divider().padding(.top)

            LeadingTextView("Hot key for open Dashboard")
                .padding(.top)
            HStack {
                KeyboardShortcuts
                    .Recorder("", name: .toggleDashboard, onChange: { shortcut in
                        if let shortcut = shortcut {
                            appSetting.dashboardHotKey = shortcut
                        }
                    })
                    .offset(x: -10)
                Spacer()
            }
            Divider().padding(.top)

            HStack {
                LaunchAtLogin.Toggle {
                    Text("Launch at login")
                }
                Spacer()
            }.padding(.top)

            Spacer()
        }
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
