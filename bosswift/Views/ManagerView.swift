//
//  ManagerView.swift
//  Bosswift
//
//  Created by huikai on 2022/7/2.
//

import SwiftUI
import Combine

enum ManagerViewTabs {
    case dashboard, projects, commands, settings, about
}

struct ManagerView: View {

    static let selectedTab = PassthroughSubject<ManagerViewTabs, Never>()
    @State var tab: ManagerViewTabs? = ManagerViewTabs.dashboard

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: DashboardView(), tag: ManagerViewTabs.dashboard, selection: $tab) { Text("Dashboard").padding().onTapGesture { tab = .dashboard }
                }
                NavigationLink(destination: ProjectManagerView(), tag: ManagerViewTabs.projects, selection: $tab) { Text("Projects").padding().onTapGesture { tab = .projects }
                }
                NavigationLink(destination: CommandManagerView(), tag: ManagerViewTabs.commands, selection: $tab) { Text("Commands").padding().onTapGesture { tab = .commands }
                }
                NavigationLink(destination: SettingsView(), tag: ManagerViewTabs.settings, selection: $tab) { Text("Settings").padding().onTapGesture { tab = .settings }
                }
                NavigationLink(destination: AboutView(), tag: ManagerViewTabs.about, selection: $tab) { Text("About").padding().onTapGesture { tab = .about }
                }
            }.onReceive(ManagerView.selectedTab) {
                tab = $0
            }
        }.background(Color(NSColor.textBackgroundColor))
    }
}

struct ManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ManagerView()
    }
}
