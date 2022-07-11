//
//  ImportProjectsView.swift
//  Bosswift
//
//  Created by huikai on 2022/6/16.
//

import SwiftUI
import KeyboardShortcuts

struct SetupView: View {
    @State var projectsRootFolder: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            LeadingTextView("First, set the work folder.")
                .font(.system(size: 24))

            HStack {
                TextField("You can skip this if you want", text: $projectsRootFolder)
                    .font(.system(size: 16))
                Button("Pick") {
                    pickRootFolder()
                }
            }

            LeadingTextView("It's where your git repos lays on.")
                .font(.system(size: 12))
                .padding([.top, .leading])
                .foregroundColor(.secondary)
            Image("WorkingFolder")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 480)

            Divider()

            LeadingTextView("Second, remember this hot key to open Bosswift:")
                .padding(.top)
                .font(.system(size: 24))
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

            RectangleButton(text: "Go Go Go!") {
                appSetting.baseFolder = projectsRootFolder
                appSetting.onboardingFinished = true
                AppDelegate.shared.statusBarController.onBoardingWindow.close()
                AppDelegate.shared.statusBarController.toggleQuickLaunchWindow()
            }.padding(.top)
        }
            .padding(32)
            .background(Color(NSColor.textBackgroundColor))
    }

    private func pickRootFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK, let folder = panel.url {
            self.projectsRootFolder = folder.path
            appSetting.baseFolder = folder.path
        }
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView(projectsRootFolder: "/dev")
        .frame(height: 900)
    }
}
