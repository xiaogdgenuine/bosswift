//
//  ProjectManagerView.swift
//  Bosswift
//
//  Created by huikai on 2022/6/29.
//

import SwiftUI
import AppKit

struct ProjectManagerView: View {
    @ObservedObject var dataSource = DataSource.shared
    @State var projectsRootFolder: String = ""
    @State var editingNickNameProject: Project?

    var body: some View {
        VStack {
            VStack {
                HStack {
                    LeadingTextView("Project name (Click to set a nick name)")
                    Spacer()
                    Text("Actions")
                }.foregroundColor(.secondary)
            }.padding()

            List {
                ForEach(dataSource.projects) { project in
                    ProjectItemRowView(project: project, editingNickNameProject: $editingNickNameProject)
                    Divider()
                }
            }
            VStack {
                LeadingTextView("Work folder")
                HStack {
                    TextField("Specify a folder that contains your working repos", text: $projectsRootFolder)
                        .font(.system(size: 16))
                    Button("Pick") {
                        pickRootFolder()
                    }
                }
            }.padding()
        }.onAppear {
            projectsRootFolder = appSetting.baseFolder ?? ""
        }
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

struct ProjectItemRowView: View {
    @ObservedObject var project: Project
    @ObservedObject var setting = appSetting
    @Binding var editingNickNameProject: Project?
    @State var nickName = ""
    @State var textField: NSTextField?
    private let textFieldDelegate = KeyAwareTextFieldDelegate()

    var body: some View {
        let projectNickName = appSetting.projectNameMappings[project.name]
        let pinnedBinding = Binding(get: {
            appSetting.pinnedProjects$.contains(project.name)
        }, set: { pinned in
            withAnimation(.spring()) {
                if pinned {
                    appSetting.pinnedProjects.append(project.name)
                } else {
                    appSetting.pinnedProjects = appSetting.pinnedProjects.filter { $0 != project.name }
                }
            }
        })
        let visibleBinding = Binding(get: {
            setting.excludedProjects$[project.name] == nil
        }, set: { visible in
            if visible {
                setting.excludedProjects[project.name] = nil
            } else {
                setting.excludedProjects[project.name] = true
            }
        })
        HStack {
            if editingNickNameProject === project {
                TextField("Set a nick name for \"\(project.name)\"", text: $nickName).introspectTextField { textField in
                    self.textField = textField
                    if textField.delegate !== textFieldDelegate {
                        textFieldDelegate.originDelegate = textField.delegate
                        textField.delegate = textFieldDelegate
                        textFieldDelegate.onEnterKeyPressed = {
                            if nickName.isEmpty || nickName == project.name {
                                appSetting.projectNameMappings[project.name] = nil
                                project.displayName = project.name
                            } else {
                                appSetting.projectNameMappings[project.name] = nickName
                                project.displayName = nickName
                            }
                            editingNickNameProject = nil
                        }
                    }
                }.onExitCommand {
                    editingNickNameProject = nil
                }
                .textFieldStyle(.roundedBorder)
            } else {
                let displayName = projectNickName ?? project.name
                HStack {
                    Text(displayName) +
                    Text(projectNickName == nil ? "" : "(\(project.name))")
                        .foregroundColor(.gray)
                    Spacer()
                }
                    .contentShape(Rectangle())
                    .cursor(.pointingHand)
                    .onTapGesture {
                        nickName = appSetting.projectNameMappings$[project.name] ?? project.name
                        editingNickNameProject = project
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.textField?.becomeFirstResponder()
                            self.textField?.currentEditor()?.selectAll(nil)
                        }
                    }
            }
            Spacer()
            Toggle(isOn: pinnedBinding) {
                Text("Pinned")
            }
            Toggle(isOn: visibleBinding) {
                Text("Visible")
            }
        }
    }
}

struct ProjectManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectManagerView()
    }
}
