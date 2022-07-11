//
//  CommandManagerView.swift
//  Bosswift
//
//  Created by huikai on 2022/6/23.
//

import SwiftUI

enum CommandEditMode {
    case hiding
    case updateUniversal(index: Int)
    case updateProject(index: Int)
    case deleteUniversal(index: Int)
    case deleteProject(index: Int)
    case createUniversal
    case createProject

    var selectedIndex: Int? {
        switch self {
        case let .updateUniversal(index):
            return index
        case let .updateProject(index):
            return index
        case let .deleteUniversal(index):
            return index
        case let .deleteProject(index):
            return index
        default:
            return nil
        }
    }
    var isUniversal: Bool {
        switch self {
        case .createUniversal, .updateUniversal, .deleteUniversal:
            return true
        default:
            return false
        }
    }
}

struct CommandManagerView: View {
    @State var editing = false
    @State var universalKeyword = ""
    @State var projectKeyword = ""
    @State var filteredUniversalCommands: [Command] = []
    @State var filteredProjectCommands: [Command] = []
    @State var deleteAlerting = false
    @State var editMode = CommandEditMode.hiding {
        didSet {
            switch editMode {
            case .hiding:
                editing = false
                deleteAlerting = false
            case .createUniversal, .createProject, .updateUniversal, .updateProject:
                editing = true
                deleteAlerting = false
            case .deleteUniversal, .deleteProject:
                editing = false
                deleteAlerting = true
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            TabView {
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Group {
                                Text("Command that can run ") +
                                Text("Everywhere").foregroundColor(.accentColor)
                            }
                            .font(.system(size: 16))
                            LeadingTextView("Drag & Drop to re-order")
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 8)
                        Spacer()
                        Button{
                            editMode = .createUniversal
                        } label: {
                            Image(systemName: "plus")
                        }
                    }.padding([.trailing, .leading])

                    HStack {
                        TextField("Search by keyword or command name", text: $universalKeyword)
                            .onChange(of: universalKeyword) { _ in filterUniversalCommands() }
                    }
                        .padding(.horizontal)
                    List {
                        ForEach(Array(filteredUniversalCommands.enumerated()), id: \.element.id) { (index, command) in
                            CommandItemRowView(
                                index: index,
                                command: command,
                                onEdit: {
                                    editMode = .updateUniversal(index: index)
                                }, onDelete: {
                                    editMode = .deleteUniversal(index: index)
                                })
                        }.onMove { indices, destination in
                            if universalKeyword.isEmpty {
                                appSetting.universalCommands.move(fromOffsets: indices,
                                    toOffset: destination)
                            }
                        }
                    }
                    .onReceive(appSetting.$universalCommands$) { _ in
                        filterUniversalCommands()
                    }
                }.tabItem {
                    Text("Universal")
                }

                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Group {
                                Text("Command that runs on ") +
                                Text("Worktree folder").foregroundColor(.accentColor)
                            }
                            .font(.system(size: 16))
                            LeadingTextView("Drag & Drop to re-order")
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 8)
                        Spacer()
                        Button{
                            editMode = .createProject
                        } label: {
                            Image(systemName: "plus")
                        }
                    }.padding([.trailing, .leading])

                    HStack {
                        TextField("Search by keyword or command name", text: $projectKeyword)
                            .onChange(of: projectKeyword) { _ in filterProjectCommands() }
                    }
                        .padding(.horizontal)

                    List {
                        ForEach(Array(filteredProjectCommands.enumerated()), id: \.element.id) { (index, command) in
                            CommandItemRowView(
                                index: index,
                                command: command,
                                onEdit: {
                                    editMode = .updateProject(index: index)
                                }, onDelete: {
                                    editMode = .deleteProject(index: index)
                                })
                        }.onMove { indices, destination in
                            if projectKeyword.isEmpty {
                                appSetting.projectCommands.move(fromOffsets: indices,
                                    toOffset: destination)
                            }
                        }
                    }
                    .onReceive(appSetting.$projectCommands$) { _ in
                        filterProjectCommands()
                    }
                }.tabItem {
                    Text("Worktree")
                }
            }
            HStack {
                Spacer()
                Button {
                    importCommands()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import")
                }
                Button {
                    exportCommands()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export")
                }
            }.padding(.top, 16)
        }
        .padding()
        .background(Color(NSColor.textBackgroundColor))
        .sheet(isPresented: $editing) {
            EditorView(editMode: $editMode) { mode in
                if let index = mode.selectedIndex, let command = mode.isUniversal ? filteredUniversalCommands[safe: index] : filteredProjectCommands[safe: index], let targetIndex = mode.isUniversal ? appSetting.universalCommands.firstIndex { $0 == command } : appSetting.projectCommands.firstIndex { $0 == command } {
                    CommandEditorView(showing: $editing, model: CommandEditModel(command: command)) { updatedCommand in
                        editCommand(updatedCommand, index: targetIndex)
                        editMode = .hiding
                    }
                } else {
                    CommandEditorView(showing: $editing, model: CommandEditModel(command: nil)) { newCommand in
                        createCommand(newCommand)
                        editMode = .hiding
                    }
                }
            }
        }
        .sheet(isPresented: $deleteAlerting) {
            VStack {
                Text("Are you sure you want to delete this command?")
                    .font(.title)
                    .padding()

                HStack {
                    Spacer()

                    Button("Cancel") {
                        deleteAlerting = false
                    }

                    Button("Yes") {
                        let selectedCommand: Command?

                        switch editMode {
                        case let .deleteUniversal(index):
                            selectedCommand = filteredUniversalCommands[index]
                            appSetting.universalCommands = appSetting.universalCommands.filter { $0 != selectedCommand }
                        case let .deleteProject(index):
                            selectedCommand = filteredProjectCommands[index]
                            appSetting.projectCommands = appSetting.projectCommands.filter { $0 != selectedCommand }
                        default:
                            return
                        }

                        filterUniversalCommands()
                        filterProjectCommands()
                        Storage.deleteAffectedScripts(command: selectedCommand!)
                        editMode = .hiding
                        if let selectedCommand = selectedCommand {
                            TaskScheduler.shared.terminateTask(relatedTo: selectedCommand)
                        }
                        AppDelegate.shared.statusBarController.refreshQuickLaunchWindow()
                    }
                }
            }.padding()
        }
    }

    func createCommand(_ command: Command) {
        if editMode.isUniversal {
            appSetting.universalCommands.append(command)
        } else {
            appSetting.projectCommands.append(command)
        }

        filterUniversalCommands()
        filterProjectCommands()
        AppDelegate.shared.statusBarController.refreshQuickLaunchWindow()
    }

    func editCommand(_ command: Command, index: Int) {
        if editMode.isUniversal {
            appSetting.universalCommands[index] = command
        } else {
            appSetting.projectCommands[index] = command
        }

        Storage.deleteAffectedScripts(command: command)
        AppDelegate.shared.statusBarController.refreshQuickLaunchWindow()
    }

    func importCommands() {
        do {
            try CommandImporter.import()
        } catch {
            print("Import failed: ", error.localizedDescription)
        }
    }

    func exportCommands() {
        do {
            try CommandExporter.export()
        } catch {
            print("Export failed: ", error.localizedDescription)
        }
    }

    func filterUniversalCommands() {
        let keyword = universalKeyword.lowercased()
        filteredUniversalCommands = appSetting.universalCommands.filter { keyword.isEmpty || $0.commandKeyword.lowercased().contains(keyword) || $0.displayName.lowercased().contains(keyword) }
    }

    func filterProjectCommands() {
        let keyword = projectKeyword.lowercased()
        filteredProjectCommands = appSetting.projectCommands.filter { keyword.isEmpty || $0.commandKeyword.lowercased().contains(keyword) || $0.displayName.lowercased().contains(keyword) }
    }
}

// Really?? Apple???
// https://stackoverflow.com/questions/62887105/uiviewrepresentable-state-value-isnt-updating
struct EditorView<Content: View>: View {
    var editMode: Binding<CommandEditMode>
    @ViewBuilder var content: (CommandEditMode) -> Content

    var body: some View {
        VStack {
            content(editMode.wrappedValue)
        }.frame(width: 500)
    }
}

struct CommandItemRowView: View {
    let index: Int
    let command: Command
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text("\(index + 1)").foregroundColor(.gray)

                if let icon = DataSource.shared.commandIcons[command.id] {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "terminal")
                        .resizable()
                        .frame(width: 40, height: 32)
                }
                VStack(alignment: .leading) {
                    Text(command.displayName)
                    Text("/" + command.commandKeyword).foregroundColor(.gray)
                }

                Spacer()

                Button("Edit") {
                    onEdit()
                }

                Button("Delete") {
                    onDelete()
                }
            }
            .padding(.trailing)
            .padding(.vertical, 8)
            .background(Color(NSColor.textBackgroundColor))
            Divider()
        }
    }
}

struct CommandManagerView_Previews: PreviewProvider {
    static var previews: some View {
        CommandManagerView()
    }
}
