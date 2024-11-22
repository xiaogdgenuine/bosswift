//
//  QuickLaunchBar.swift
//  Bosswift
//
//  Created by huikai on 2022/6/12.
//

import SwiftUI
import Introspect

let candidateRowHeight: CGFloat = 64

enum QuickLaunchBarMode {
    case pickingBranch
    case pickingBranchCommand
    case pickingUniversalCommand

    var isPickingCommand: Bool {
        switch self {
        case .pickingBranchCommand, .pickingUniversalCommand:
            return true
        default:
            return false
        }
    }

    var isPickingUniversalCommand: Bool {
        switch self {
        case .pickingUniversalCommand:
            return true
        default:
            return false
        }
    }
}

struct QuickLaunchBarView: View {
    @ObservedObject var taskScheduler = TaskScheduler.shared
    @ObservedObject var dataSource = DataSource.shared
    @State var candidateBranches: [Branch] = []
    @State var candidateCommands: [Command] = []
    @State var mode = QuickLaunchBarMode.pickingBranch
    @State private var highlightingRow: Int = -1
    @State private var keyword: String = ""
    @State private var keywordBeforePickBranchCommand: String = ""
    @State private var initialFocusSet = false
    @State private var selectedBranch: Branch?
    @State private var textField: NSTextField?
    @State private var askingTerminalControPermission = false

    var candidateAvailable: Bool {
        switch mode {
        case .pickingBranch:
            return !candidateBranches.isEmpty
        case .pickingBranchCommand, .pickingUniversalCommand:
            return !candidateCommands.isEmpty
        }
    }

    var body: some View {
        VStack {
            VStack {
                let keywordAutoCompleteBinding = Binding<String>(get: {
                    if keyword.isEmpty {
                        return ""
                    }

                    return getAutoCompletePlaceholder()
                }, set: { _ in
                })

                let searchbarFontSize: CGFloat = 24

                if let branch = selectedBranch {
                    HStack {
                        SelectedContextView(context: branch.project.displayName + ": " + branch.displayName)
                        Spacer()
                    }
                }
                HStack(spacing: 0) {
                    if mode.isPickingCommand {
                        Text("/")
                            .padding(.leading, 4)
                            .font(.system(size: searchbarFontSize))
                    }
                    TextField("", text: $keyword)
                        .onExitCommand {
                            AppDelegate.shared.statusBarController.quickLaunchWindow.close()
                        }
                        .onKeyPress(.return) {
                            onEnterKeyPressed()
                            return .handled
                        }
                        .onKeyPress(.init(Character(UnicodeScalar(127)))) {
                            onDeleteBackward()
                            return .ignored
                        }
                        .onKeyPress(.leftArrow) {
                            onArrowKeyMoved(.left)
                            return .handled
                        }
                        .onKeyPress(.rightArrow) {
                            onArrowKeyMoved(.right)
                            return .handled
                        }
                        .onKeyPress(.upArrow) {
                            onArrowKeyMoved(.up)
                            return .handled
                        }
                        .onKeyPress(.downArrow) {
                            onArrowKeyMoved(.down)
                            return .handled
                        }
                        .onKeyPress(.tab) {
                            onTabKeyPressed()
                            return .handled
                        }
                        .onChange(of: keyword) { newKeyWord in
                            if newKeyWord == "/" {
                                mode = .pickingUniversalCommand
                                keyword = ""
                                keywordBeforePickBranchCommand = ""
                            }
                            filter()
                        }
                        .padding(.horizontal, 4)
                        .placeholder(when: keyword.isEmpty) {
                            let placeholder = mode.isPickingUniversalCommand ? "Pick a universal command" : mode.isPickingCommand ? "Pick a command" : "Pick a branch or type \"/\" to run universal command"
                            Text(placeholder)
                                .padding(.horizontal, 4)
                                    .selfSizeMask(
                                            LinearGradient(
                                                    gradient: Gradient(colors: [.blue, .red, .orange]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing)
                                    )
                        }
                        .textFieldStyle(.plain)
                        .font(.system(size: searchbarFontSize))
                        .introspectTextField {
                            if !initialFocusSet {
                                initialFocusSet = true
                                $0.becomeFirstResponder()
                            }
                            textField = $0
                        }
                        .overlay(
                            TextField("", text: keywordAutoCompleteBinding)
                                .disabled(true)
                                .padding(.horizontal, 4)
                                .textFieldStyle(.plain)
                                .font(.system(size: searchbarFontSize))
                                .foregroundColor(.gray)
                        )

                    Image("Logo")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .padding(.trailing, 16)
                }

                if (!keyword.isEmpty || mode.isPickingCommand) && candidateAvailable {
                    let extraLineHeight: CGFloat = 1
                    let idealHeight = mode.isPickingCommand ? CGFloat(candidateCommands.count) * candidateRowHeight : CGFloat(candidateBranches.count) * candidateRowHeight
                    VStack(spacing: 0) {
                        Divider()
                            .padding(.trailing, 16)
                        if mode.isPickingCommand {
                            CommandPickerView(
                                keyword: keyword,
                                highlightingRow: highlightingRow,
                                selectedBranch: selectedBranch,
                                candidateCommands: candidateCommands,
                                executeItemAt: { index in executeCandidateItem(offset: index) }
                            )
                        } else if !candidateBranches.isEmpty {
                            BranchPickerView(keyword: keyword, highlightingRow: highlightingRow, candidateBranches: candidateBranches,
                                             executeItemAt: { index in executeCandidateItem(offset: index) })
                        }
                    }
                    .frame(maxHeight: min(9 * candidateRowHeight, idealHeight) + extraLineHeight)
                }
            }
                .padding([.vertical, .leading], 16)
                .background(Color(NSColor.textBackgroundColor))
                .onAppear {
                    filter()
                }
            Spacer()
        }
        .sheet(isPresented: $askingTerminalControPermission) {
            VStack {
                Text("Bosswift require permission to open/close Terminal, please grant it in system setting.")
                    .font(.title)
                    .padding()

                Image("PermissionGuide")
                    .resizable()
                    .frame(width: 600, height: 530)

                HStack {
                    Spacer()

                    Button("No way") {
                        askingTerminalControPermission = false
                    }

                    Button("Take me there") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
                        askingTerminalControPermission = false
                    }
                }
            }.padding()
        }
        .onReceive(ScreenMonitor.appleScriptPermissionEnabled) { permissionGranted in
            askingTerminalControPermission = !permissionGranted
        }
        .onReceive(appSetting.$projectCommands$) { _ in
            filter()
        }
        .onReceive(appSetting.$universalCommands$) { _ in
            filter()
        }
        .onReceive(dataSource.onProjectRefreshed$) { project in
            guard let branch = selectedBranch, project.id == branch.project.id else {
                return
            }

            // The selected branch is deleted
            if !(project.branches.contains { $0.id == branch.id }) {
                mode = .pickingBranch
                keyword = ""
                highlightingRow = 0
                selectedBranch = nil
            }
        }
    }
}

extension QuickLaunchBarView {

    func filter() {
        if mode.isPickingCommand {
            filterCommands()
        } else {
            filterBranches()
        }
    }

    func onArrowKeyMoved(_ direction: MoveCommandDirection) {
        navigateBy(direction: direction)
    }

    func onEnterKeyPressed() {
        executeCandidateItem(offset: highlightingRow)
    }

    func onTabKeyPressed() {
        if mode.isPickingCommand {
            selectHighlightedCommand()
        } else {
            keywordBeforePickBranchCommand = keyword
            startPickCommand(at: highlightingRow)
        }
    }

    func onDeleteBackward() {
        if keyword.isEmpty && mode != .pickingBranch {
            mode = .pickingBranch
            keyword = keywordBeforePickBranchCommand
            highlightingRow = candidateBranches.firstIndex { $0.id == selectedBranch?.id } ?? 0
            selectedBranch = nil
        }
    }

    func filterBranches() {
        let lastHighlightedItem = candidateBranches[safe: highlightingRow]

        func restoreHighlightedItem() {
            highlightingRow = candidateBranches.firstIndex {
                $0.project.displayName == lastHighlightedItem?.project.displayName && $0.name == lastHighlightedItem?.name
            } ?? 0
        }

        let keyword = self.keyword.lowercased()
        let allVisibleProjects = dataSource.projects.filter { appSetting.excludedProjects[$0.name] == nil }
        if keyword.isEmpty {
            candidateBranches = allVisibleProjects.flatMap {$0.branches}
            restoreHighlightedItem()
        } else {
            let seperatorCharIndex = keyword.firstIndex(of: ":") ?? keyword.firstIndex(of: " ")
            if let seperatorCharIndex = seperatorCharIndex, seperatorCharIndex != keyword.startIndex {
                // Search with in project(eg: "Doll:master", "Doll master")
                let projectKeyword = String(keyword[keyword.startIndex..<seperatorCharIndex])
                let branchKeywordBeginIndex = min(keyword.index(after: seperatorCharIndex), keyword.endIndex)
                let branchKeyword = String(keyword[branchKeywordBeginIndex..<keyword.endIndex]).trimmingCharacters(in: .whitespaces)

                candidateBranches = allVisibleProjects.flatMap {
                    $0.displayName.lowercased() == projectKeyword ? $0.branches.filter {
                        branchKeyword.isEmpty || $0.name.lowercased().contains(branchKeyword)
                    } : []
                }
            } else {
                candidateBranches = allVisibleProjects.flatMap {
                    $0.branches.filter {
                        $0.name.lowercased().contains(keyword) || $0.project.displayName.lowercased().contains(keyword)
                    }
                }
            }


            restoreHighlightedItem()
        }
    }

    func filterCommands() {
        let lastHighlightedItem = candidateCommands[safe: highlightingRow]

        func restoreHighlightedItem() {
            highlightingRow = candidateCommands.firstIndex {
                $0 == lastHighlightedItem
            } ?? 0
        }

        let allCommands = selectedBranch == nil ? appSetting.universalCommands : appSetting.projectCommands
        let commandKeyword = keyword.lowercased()
        if commandKeyword.isEmpty {
            candidateCommands = allCommands
            restoreHighlightedItem()
        } else {
            candidateCommands = allCommands.filter {
                $0.commandKeyword.lowercased().hasPrefix(commandKeyword) || $0.displayName.lowercased().contains(commandKeyword)
            }

            restoreHighlightedItem()
        }
    }

    func navigateBy(direction: MoveCommandDirection) {
        switch direction {
        case .left:
            break
        case .right:
            if mode.isPickingCommand {
                selectHighlightedCommand()
            } else {
                if textField?.currentEditor()?.selectedRange.lowerBound == keyword.count {
                    keyword = candidateBranches[safe: highlightingRow]?.displayName ?? ""
                }
            }
        case .down:
            // arrow down
            highlightingRow += 1
            if mode.isPickingCommand {
                if highlightingRow > candidateCommands.count - 1 {
                    highlightingRow = 0
                }
            } else {
                if highlightingRow > candidateBranches.count - 1 {
                    highlightingRow = 0
                }
            }
        case .up:
            // arrow up
            highlightingRow -= 1
            if mode.isPickingCommand {
                if highlightingRow < 0 {
                    highlightingRow = candidateCommands.count - 1
                }
            } else {
                if highlightingRow < 0 {
                    highlightingRow = candidateBranches.count - 1
                }
            }
            break
        }
    }

    @discardableResult
    func selectHighlightedBranch(at: Int, forceAutoComplete: Bool) -> Bool {
        if let highlightedBranch = candidateBranches[safe: at],
           let highlightedKeyword = candidateBranches[safe: at]?.name,
           forceAutoComplete || highlightedKeyword.lowercased().starts(with: keyword.lowercased()) {
            DispatchQueue.main.async {
                keyword = ""
                selectedBranch = highlightedBranch
            }
            return true
        }

        return false
    }

    func selectHighlightedCommand() {
        if let highlightedKeyword = candidateCommands[safe: highlightingRow]?.displayName {
            let shouldSelectCommandText = highlightedKeyword.count > keyword.count
            keyword = highlightedKeyword
            DispatchQueue.main.async {
                if shouldSelectCommandText,
                   let textField = textField {
                    if let commandBeginRange = keyword.range(of: "/") {
                        textField.currentEditor()?.selectedRange = NSRange(commandBeginRange.upperBound..<keyword.endIndex, in: keyword)
                    } else {
                        textField.currentEditor()?.selectedRange = NSRange(keyword.startIndex..<keyword.endIndex, in: keyword)
                    }
                }
            }
        }
    }

    func startPickCommand(at: Int) {
        guard !keyword.isEmpty && !candidateBranches.isEmpty else {
            return
        }

        if selectHighlightedBranch(at: at, forceAutoComplete: true) {
            highlightingRow = 0
            mode = .pickingBranchCommand
            filterCommands()
        }
    }

    func executeCandidateItem(offset: Int) {
        switch mode {
        case .pickingBranchCommand:
            if let pickedCommand = candidateCommands[safe: offset],
               let selectedBranch = selectedBranch {
                TaskScheduler.shared.startNewTask(taskId: selectedBranch.generateCommandId(command: pickedCommand), command: pickedCommand, branch: selectedBranch)
            } else if let selectedBranch = selectedBranch {
                TaskScheduler.shared.startTemporaryTask(script: """
                cd '\(selectedBranch.folder)'
                \(keyword)
                """) 
            }
            AppDelegate.shared.statusBarController.quickLaunchWindow.close()
        case .pickingUniversalCommand:
            if let pickedCommand = candidateCommands[safe: offset] {
                TaskScheduler.shared.startNewTask(taskId: pickedCommand.universalId, command: pickedCommand)
            } else {
                TaskScheduler.shared.startTemporaryTask(script: keyword)
            }
            AppDelegate.shared.statusBarController.quickLaunchWindow.close()
        case .pickingBranch:
            keywordBeforePickBranchCommand = keyword
            startPickCommand(at: offset)
        }
    }

    func getAutoCompletePlaceholder() -> String {
        if !mode.isPickingCommand {
            let proposalText = candidateBranches[safe: highlightingRow]?.displayName ?? ""
            if proposalText.lowercased().starts(with: keyword.lowercased()) {
                return "\(keyword)\(proposalText[keyword.endIndex...])"
            }

            if !proposalText.isEmpty {
                return "\(keyword) - \(proposalText)"
            } else {
                return "\(keyword) - Not match"
            }
        } else {
            let candidateCommandName = candidateCommands[safe: highlightingRow]?.displayName ?? ""
            let proposalText = "\(candidateCommandName)"
            if proposalText.lowercased().starts(with: keyword.lowercased()) {
                return "\(keyword)\(proposalText[keyword.endIndex...])"
            }

            if !candidateCommandName.isEmpty {
                return "\(keyword) - \(candidateCommandName)"
            } else {
                return "\(keyword) >>> Hit enter to run in terminal"
            }
        }
    }

}

struct QuickLaunchBar_Previews: PreviewProvider {
    static let mockProjects: [Project] = {
        let projects = [
            Project(name: "Kedamanga", branches: []),
            Project(name: "Doll", branches: []),
            Project(name: "TypeScript", branches: []),
            Project(name: "CoffeeScript", branches: []),
            Project(name: "ReactJS", branches: [])
        ]

        projects.forEach { project in
            project.branches = [
                Branch(name: "master", folder: "./master", belongTo: project),
                Branch(name: "develop", folder: "./develop", belongTo: project),
                Branch(name: "feature", folder: "./feature", belongTo: project),
                Branch(name: "bugfix", folder: "./bugfix", belongTo: project)
            ]
        }

        return projects
    }()

    static var previews: some View {
        QuickLaunchBarView()
    }
}
