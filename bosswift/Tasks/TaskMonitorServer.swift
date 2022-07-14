//
//  TaskMonitorServer.swift
//  Bosswift
//
//  Created by huikai on 2022/6/14.
//

import Foundation
import Swifter

enum TaskMonitorServer {
    static func start() {
        guard !AppEnvironment.isInPreviewMode else {
            return
        }

        DispatchQueue.global(qos: .userInteractive).async {
            let server = HttpServer()
            server.middleware.append({ req in
                let comeFromCURL = (req.headers["user-agent"] ?? req.headers["User-Agent"])?.starts(with: "curl") ?? false

                if !comeFromCURL {
                    return .forbidden(nil)
                }

                return nil
            })
            server["/start"] = { req in
                startTask(id: req.queryParams.first{ $0.0 == "taskId" }?.1 ?? "")

                return .ok(.htmlBody("Started"))
            }
            server["/restart"] = { req in
                restartTask(id: req.queryParams.first{ $0.0 == "taskId" }?.1 ?? "")

                return .ok(.htmlBody("ReStarted"))
            }
            server["/stop"] = { req in
                let taskId = req.queryParams.first{ $0.0 == "taskId" }?.1 ?? ""
                let isFailed = req.queryParams.first{ $0.0 == "failed" }?.1 == "true"

                stopTask(id: taskId, failed: isFailed)
                return .ok(.htmlBody("Stopped"))
            }
            server["/xcode/derived-path"] = { req in
                // 如果有 workspace 或者 xcodeproj 文件，则 derived 开头为对应的名字，否则就是文件夹名字
                let home = FileManager.default.homeDirectoryForCurrentUser.path
                let repoFolder = (req.queryParams.first{ $0.0 == "folder" }?.1 ?? "").removingPercentEncoding ?? ""
                let workspaceFile = req.queryParams.first{ $0.0 == "workspace" }?.1
                let projectFile = req.queryParams.first{ $0.0 == "xcodeproj" }?.1 ?? ""

                let branchHash = hashStringForPath(repoFolder + "/" + (workspaceFile ?? projectFile ?? "")) ?? ""
                var derivedDataPrefix = String(repoFolder.split(separator: "/").last ?? "")

                if let projectName = (workspaceFile ?? projectFile)?.split(separator: ".").first {
                    derivedDataPrefix = String(projectName)
                }

                let derivedPath = "\(home)/Library/Developer/Xcode/DerivedData/\(derivedDataPrefix)-\(branchHash)"
                return .ok(.text(derivedPath))
            }

            let semaphore = DispatchSemaphore(value: 0)
            do {
                try server.start(appSetting.taskServerListenPort, forceIPv4: true)
                print("Server has started ( port = \(try server.port()) ). Try to connect now...")
                semaphore.wait()
            } catch {
              print("Server start error: \(error)")
              semaphore.signal()
            }
        }
    }

    private static func startTask(id: String) {
        DispatchQueue.main.sync {
            TaskScheduler.shared.onTaskStarted(taskId: id.removingPercentEncoding ?? id)
        }
    }

    private static func restartTask(id: String) {
        DispatchQueue.main.sync {
            TaskScheduler.shared.restartTask(taskId: id.removingPercentEncoding ?? id)
        }
    }

    private static func stopTask(id: String, failed: Bool) {
        DispatchQueue.main.sync {
            TaskScheduler.shared.onTaskStopped(taskId: id.removingPercentEncoding ?? id, isFailed: failed)
        }
    }
}
