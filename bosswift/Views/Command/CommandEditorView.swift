//
//  CommandEditorView.swift
//  Bosswift
//
//  Created by huikai on 2022/6/23.
//

import SwiftUI

class CommandEditModel: ObservableObject {
    var commandId: Int?
    @Published var commandKeyword = ""
    var commandIconRefreshCounter = 0
    @Published var displayName = ""
    @Published var script = ""
    @Published var runSilently = false
    @Published var playSoundWhenDone = false
    @Published var playSoundWhenFailed = false
    @Published var iconPath: URL?

    init(command: Command?) {
        if let command = command {
            commandId = command.id
            commandKeyword = command.commandKeyword
            displayName = command.displayName
            script = command.executableScript
            runSilently = command.runSilently
            playSoundWhenDone = command.playSoundWhenDone
            playSoundWhenFailed = command.playSoundWhenFailed
            iconPath = Storage.iconPathFor(command: command)
            commandIconRefreshCounter = command.commandIconRefreshCounter
        }
    }
}

struct CommandEditorView: View {
    let showing: Binding<Bool>
    @ObservedObject var model: CommandEditModel
    let onSave: (Command) -> Void
    @State var changed = false
    @State var warnningSave = false
    @State var presentingGlossary = false
    @State var icon: NSImage?

    var body: some View {
        ScrollView {
            VStack {
                VStack {
                    LeadingTextView("Keyword")
                    TextField("A unique keyword for the command", text: $model.commandKeyword)
                        { markChanged(isChanged: $0) }
                        .onExitCommand { exit() }
                }

                VStack {
                    LeadingTextView("Display Name (Optional)")
                    TextField("A short text that describe the command", text: $model.displayName) { markChanged(isChanged: $0) }
                        .onExitCommand { exit() }
                }

                VStack {
                    HStack {
                        LeadingTextView("Command Script")
                        Button {
                            presentingGlossary = true
                        } label: {
                            Image(systemName: "eyeglasses")
                        }
                    }
                    let scriptBinding = Binding(get: { model.script }, set: {
                        model.script = $0
                        changed = true
                    })
                    TextEditor(text: scriptBinding)
                        .foregroundColor(.secondary)
                        .frame(minHeight: 250, maxHeight: 400)
                        .onExitCommand { exit() }
                        .border(Color.primary)
                }

                VStack(alignment: .leading) {
                    LeadingTextView("Icon (Optional, any square shape image)")
                    HStack {
                        VStack {
                            if let iconFile = icon {
                                Image(nsImage: iconFile)
                                    .resizable()
                                    .frame(width: 100, height: 100)
                            } else {
                                Image(systemName: "plus")
                            }
                        }
                        .padding()
                        .frame(width: 120, height: 120)
                        .border(Color.secondary)
                        .contentShape(Rectangle())
                        .cursor(.pointingHand)
                        .onTapGesture {
                            pickIconFile()
                        }

                        if icon != nil {
                            Button("Remove icon") {
                                model.iconPath = nil
                                icon = nil
                            }
                        } else {
                            VStack {
                                Text("You can download free icon from:")
                                Text("https://www.flaticon.com/")
                                    .foregroundColor(.blue)
                                    .underline()
                                    .cursor(.pointingHand)
                                    .onTapGesture {
                                        NSWorkspace.shared.open(URL(string: "https://www.flaticon.com/")!)
                                    }
                            }
                        }
                        Spacer()
                    }
                }

                HStack {
                    Toggle("Run silently (No shell window will show)", isOn: $model.runSilently)
                    Spacer()
                }

                HStack {
                    Toggle("Play sound on complete", isOn: $model.playSoundWhenDone)
                        .onChange(of: model.playSoundWhenDone) { playSound in
                            if playSound {
                                NSSound(named: "Purr")?.play()
                            }
                        }
                    Spacer()
                }

                HStack {
                    Toggle("Play sound on failing", isOn: $model.playSoundWhenFailed)
                        .onChange(of: model.playSoundWhenFailed) { playSound in
                            if playSound {
                                NSSound(named: "Ping")?.play()
                            }
                        }
                    Spacer()
                }

                HStack {
                    Button("Cancel") {
                        exit()
                    }
                    Spacer()
                    Button {
                        guard !model.commandKeyword.isEmpty, !model.script.isEmpty else {
                            return
                        }
                        let displayName = model.displayName.isEmpty ? model.commandKeyword : model.displayName
                        var newCommand = Command(id: model.commandId ?? -1, commandKeyword: model.commandKeyword, displayName: displayName, playSoundWhenDone: model.playSoundWhenDone, playSoundWhenFailed: model.playSoundWhenFailed, scripts: [.script(content: model.script)], runSilently: model.runSilently, commandIconRefreshCounter: model.commandIconRefreshCounter + 1)

                        // New command
                        if newCommand.id == -1 {
                            commandIdCounter += 1
                            newCommand.id = commandIdCounter
                        }

                        if let iconPath = model.iconPath {
                            Storage.storeCommandIcon(command: newCommand, tempIconPath: iconPath)
                            if let newIcon = NSImage(contentsOf: Storage.iconPathFor(command: newCommand)) {
                                DataSource.shared.commandIcons[newCommand.id] = newIcon
                            }
                        } else {
                            DataSource.shared.commandIcons[newCommand.id] = nil
                            Storage.removeCommandIcon(command: newCommand)
                        }

                        onSave(newCommand)
                    } label: {
                        Text("Save the command")
                    }
                }.padding(.vertical)
            }.padding()
        }
        .onAppear {
            if let url = model.iconPath {
                icon = NSImage(contentsOf: url)
            }
        }
        .sheet(isPresented: $presentingGlossary) {
            VStack {
                LeadingTextView("You can use these variables passed by Bosswift")
                    .font(.system(size: 18))
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    GlossaryVariableItem(name: "$BOSSWIFT_WORK_FOLDER", description: "Bosswift work folder path")
                    GlossaryVariableItem(name: "$BOSSWIFT_PROJECT_NAME", description: "Project name")
                    GlossaryVariableItem(name: "$BOSSWIFT_BRANCH_NAME", description: "Branch name")
                    GlossaryVariableItem(name: "$BOSSWIFT_WORKTREE_PATH", description: "The folder of branch's worktree")
                    GlossaryVariableItem(name: "$BOSSWIFT_DEFAULT_WORKTREE_PATH", description: "The folder of worktree in work folder")
                    GlossaryVariableItem(name: "$BOSSWIFT_XCODE_DERIVED_PATH", description: "The Xcode derived data path for this project")
                    GlossaryVariableItem(name: "$BOSSWIFT_XCODE_WORKSPACE_FILE", description: "The name of Xcode workspace file for this project")
                    GlossaryVariableItem(name: "$BOSSWIFT_XCODE_PROJECT_FILE", description: "The name of Xcode  xcodeproj file for this project")
                }
                HStack {
                    Spacer()
                    Button("done") {
                        presentingGlossary = false
                    }
                }
            }.padding()
        }.sheet(isPresented: $warnningSave) {
            VStack {
                Text("Discard changes?")
                    .font(.title)
                    .padding()

                HStack {
                    Spacer()

                    Button("Cancel") {
                        warnningSave = false
                    }

                    Button("Yes") {
                        changed = false
                        exit()
                    }
                }
            }.padding()
        }
    }

    func markChanged(isChanged: Bool) {
        if !changed {
            changed = isChanged
        }
    }

    func exit() {
        if changed {
            warnningSave = true
        } else {
            warnningSave = false
            showing.wrappedValue = false
        }
    }

    func pickIconFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg, .application]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                model.iconPath = Storage.storeTempCommandIcon(image: image)
                icon = image
            } else {
                if let rep = NSWorkspace.shared.icon(forFile: url.path)
                    .bestRepresentation(for: NSRect(x: 0, y: 0, width: 1024, height: 1024), context: nil, hints: nil) {
                    let appIcon = NSImage(size: rep.size)
                    appIcon.addRepresentation(rep)
                    model.iconPath = Storage.storeTempCommandIcon(image: appIcon)
                    icon = appIcon
                }
            }
        }
    }
}

struct GlossaryVariableItem: View {
    let name: String
    let description: String
    @State private var nameCopied = false

    var body: some View {
        HStack {
            Text(name).foregroundColor(.accentColor)
            Text(" - \(description)")
            Spacer()
            Button {
                let pasteBoard = NSPasteboard.general
                pasteBoard.clearContents()
                pasteBoard.setString(name, forType: .string)
                nameCopied = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    nameCopied = false
                }
            } label: {
                if nameCopied {
                    Image(systemName: "checkmark.rectangle").foregroundColor(.green)
                } else {
                    Image(systemName: "doc.on.doc")
                }
            }
        }
        Divider()
    }
}

struct CommandEditorView_Previews: PreviewProvider {
    static var previews: some View {
        CommandEditorView(showing: .constant(true), model: CommandEditModel(command: nil)) {_ in }
            .frame(height: 900)
    }
}
