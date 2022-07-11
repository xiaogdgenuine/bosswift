//
//  CommandPickerView.swift
//  Bosswift
//
//  Created by huikai on 2022/6/18.
//

import SwiftUI

struct CommandPickerView: View {
    let keyword: String
    let highlightingRow: Int
    var selectedBranch: Branch?
    var candidateCommands: [Command] = []
    let executeItemAt: (Int) -> Void
    @State var commandOffset = 0
    @ObservedObject var taskScheduler = TaskScheduler.shared

    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: 0) {
                    ForEach(Array(candidateCommands.enumerated()), id: \.offset) { (index, command) in
                        let hightlight = index == highlightingRow
                        let commandId = selectedBranch?.generateCommandId(command: command) ?? command.universalId
                        CommandCandidateView(currentKeyword: keyword,
                                             highlighted: hightlight,
                                             selectedBranch: selectedBranch,
                                             command: command,
                                             commandIndex: index - commandOffset,
                                             runningTask: taskScheduler.runningTasks[commandId] ?? RunningTask())
                            .frame(height: candidateRowHeight)
                            .onTapGesture {
                                executeItemAt(index)
                            }
                            .id(index)
                    }
                }
                .padding(.trailing, 16)
                .onChange(of: highlightingRow) { row in
                    proxy.scrollTo(row)
                }
            }
        }
        .didScroll { offset in
            commandOffset = Int(ceil(offset.y) / candidateRowHeight)
        }

        VStack {
            QuickLaunchShortcuts { index in
                executeItemAt(index + commandOffset)
            }
            // Ctrl+c to cancel highlighted task
            Button("") {
                if let command = candidateCommands[safe: highlightingRow] {
                    let commandId = selectedBranch?.generateCommandId(command: command) ?? command.universalId
                    taskScheduler.finishTask(taskId: commandId)
                }
            }
                .keyboardShortcut("c", modifiers: .control)
                .frame(width: 0, height: 0)
        }
            .frame(width: 0, height: 0)
            .clipped()
    }
}

struct CommandCandidateView: View {
    let currentKeyword: String
    let highlighted: Bool
    let selectedBranch: Branch?
    let command: Command
    let commandIndex: Int
    @State var highlightByHover = false
    @ObservedObject var mouseMoveMonitor = MouseMoveMonitor.shared
    @ObservedObject var runningTask: RunningTask
    @ObservedObject var taskScheduler = TaskScheduler.shared
    @ObservedObject var dataSource = DataSource.shared

    var body: some View {
        let commandId = selectedBranch?.generateCommandId(command: command) ?? ""
        let highlightableCommandName = generateHighlightableText(keyword: currentKeyword, candidate: command.displayName)

        HStack {
            if let icon = dataSource.commandIcons[command.id] {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 40, height: 40)
            } else {
                Image(systemName: "terminal")
                    .resizable()
                    .frame(width: 40, height: 32)
            }

            VStack(alignment: .leading) {
                if let highlightableText = highlightableCommandName {
                    Group {
                        Text(highlightableText.begin)
                             +
                        Text(highlightableText.middle)
                            .foregroundColor(Color.orange)
                            .underline() +
                        Text(highlightableText.end)
                    }.font(.system(size: 16))
                } else {
                    LeadingTextView(command.displayName)
                        .font(.system(size: 16))
                }
                Group {
                    if highlightableCommandName == nil, let highlightableText = generateHighlightableText(keyword: currentKeyword, candidate: command.commandKeyword) {
                        Text("/") +
                        Text(highlightableText.begin) +
                        Text(highlightableText.middle)
                            .foregroundColor(Color.orange)
                            .underline() +
                        Text(highlightableText.end)
                    }else{
                        LeadingTextView("/\(command.commandKeyword)")
                    }
                }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !runningTask.isHolder {
                switch runningTask.status {
                case .running:
                    HStack(spacing: 4) {
                        Spacer()

                        if highlighted {
                            Text("Ctrl + c to stop")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        ProgressView()
                            .scaleEffect(0.5)
                        Button {
                            taskScheduler.finishTask(taskId: commandId)
                        } label: {
                            Image(systemName: "stop.fill")
                                .foregroundColor(.red)
                        }
                    }
                case .failed:
                    Button{
                        runningTask.activeScreen()
                    } label: {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            } else {
                if highlighted {
                    Image("EnterKey")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.accentColor)
                } else {
                    HStack {
                        Image(systemName: "command")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("\(commandIndex + 1)")
                    }
                }
            }
        }
        .onTapGesture {
            guard !runningTask.isHolder,
                    runningTask.status == .running else {
                return
            }

            runningTask.activeScreen()
        }
        .frame(
            maxWidth: .infinity,
            alignment: .topLeading
        )
        .frame(height: 52)
        .padding(6)
        .contentShape(Rectangle())
        .onHover {
            highlightByHover = $0
        }
        .background((highlightByHover && mouseMoveMonitor.mouseMoved) ? Color.accentColor.opacity(0.7) : highlighted ? Color.accentColor : Color(NSColor.textBackgroundColor))
        .cornerRadius(4)
    }
}

struct CommandPickerView_Previews: PreviewProvider {
    static var previews: some View {
        CommandPickerView(keyword: "", highlightingRow: 0, candidateCommands: [
            Command(id: -1, commandKeyword: "cd", displayName: "Open terminal in here", scripts: []),
            Command(id: -1, commandKeyword: "resolve-spm", displayName: "Resolve Swift Package", scripts: []),
            Command(id: -1, commandKeyword: "pod-install", displayName: "Pod install", scripts: [])
        ]) { _ in

        }
    }
}
