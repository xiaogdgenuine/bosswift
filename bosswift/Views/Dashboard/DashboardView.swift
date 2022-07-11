//
//  DashboardView.swift
//  Bosswift
//
//  Created by huikai on 2022/6/26.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var taskScheduler = TaskScheduler.shared

    var body: some View {
        VStack {
            if taskScheduler.runningTasks.isEmpty {
                Text("No tasks is currently running.")
                    .font(.system(size: 42))
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    let runningTasks = taskScheduler.runningTasks
                        .map { $0.value }
                        .sorted { $0.startAt < $1.startAt }
                    ForEach(runningTasks) { task in
                        DashboardRunningTaskView(task: task)
                    }
                }.padding(0)
                HStack {
                    Button {
                        taskScheduler.terminateAllTasks()
                    } label: {
                        Text("Stop all").foregroundColor(.red)
                    }

                    Spacer()
                }.padding()
            }
        }
            .background(Color(NSColor.textBackgroundColor))
    }
}

struct DashboardRunningTaskView: View {
    @ObservedObject var taskScheduler = TaskScheduler.shared
    @ObservedObject var task: RunningTask
    @State var hover = false

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    if let branch = task.branch {
                        Text(branch.project.displayName + ":" + branch.displayName)
                            .font(.system(size: 14))
                            .foregroundColor(Color.orange)
                    } else {
                        Text("Universal")
                            .font(.system(size: 14))
                            .foregroundColor(Color.purple)
                    }
                    HStack {
                        Text(task.command.displayName)
                            .font(.system(size: 16))
                            .padding(.leading)
                        Text("\(getElapsedDescription(seconds: task.elapsedSeconds))")
                            .foregroundColor(.gray)
                            .padding(.leading)
                            .font(.system(size: 11))
                    }
                }
                Spacer()
                if task.status == .failed {
                    Image(systemName: "exclamationmark.triangle").resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.red)
                    Button("Retry") {
                        taskScheduler.startNewTask(taskId: task.taskId, command: task.command, branch: task.branch)
                    }
                    Button {
                        taskScheduler.finishTask(taskId: task.taskId)
                    } label: {
                        Text("Ignore")
                    }
                } else if task.status == .running {
                    Button {
                        taskScheduler.finishTask(taskId: task.taskId)
                    } label: {
                        Text("Cancel").foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .cursor(.pointingHand)
            Divider()
        }
            .contentShape(Rectangle())
            .onHover { hover = $0 }
            .background(hover ? Color.accentColor : Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .onTapGesture {
                task.activeScreen()
            }
    }

    func getElapsedDescription(seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 60 * 60  {
            return "\(seconds / 60)m \(seconds % 60)s"
        } else {
            let hours = seconds / 60 / 60
            let minutes = (seconds - (hours * 60 * 60)) / 60
            return "\(hours)h \(minutes)m \(seconds % 60)s"
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView().onAppear {
            let testProject = Project(name: "Kedamanga", branches: [])
            TaskScheduler.shared.runningTasks = [
                "ping": RunningTask(taskId: "Ping", branch: nil, command: Command(id: 1, commandKeyword: "test", displayName: "Ping command", scripts: [])),
                "build-and-upload": RunningTask(taskId: "build-and-uploadf", branch: Branch(name: "feature/1988-support_7z_format", folder: "", belongTo: testProject), command: Command(id: 2, commandKeyword: "build and upload", displayName: "Build and upload to AppStore", scripts: []))
            ]
        }
    }
}
