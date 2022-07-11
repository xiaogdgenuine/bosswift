import Foundation
import SwiftUI
import Combine

// path hash [branch name]
let workTreeMatchRegex = try! NSRegularExpression(pattern: "(?<path>.*)\\s+(?<hash>.*)\\s+\\[(?<name>.*)\\]$")

class Project: ObservableObject, Identifiable {

    var id: String {
        name
    }
    var name: String
    @Published var displayName: String = ""
    var workspace: String?
    var gitPath: String?
    var folder: String = ""
    @Published var branches: [Branch]

    init(name: String, branches: [Branch]) {
        self.name = name
        self.branches = branches
    }

    init(name: String, gitPath: String) {
        self.name = name
        self.displayName = name
        self.gitPath = gitPath
        branches = []
    }

    func loadBranches() {
        let folder = self.folder
        DispatchQueue.global(qos: .userInteractive).async {
            let (_, workTreesStr) = shellImmediately("git worktree list", cwd: folder)

            if let workTreesStr = workTreesStr {
                let lines = workTreesStr.split(separator: "\n").map(String.init)
                let existBranchInfos = lines.compactMap { line -> (String, String)? in
                    if let match = workTreeMatchRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.count)),
                       let pathRange = Range(match.range(withName: "path")),
                       let branchNameRange = Range(match.range(withName: "name")) {
                        let branchPath = line.substr(pathRange).trimmingCharacters(in: .whitespaces)
                        let branchName = line.substr(branchNameRange).trimmingCharacters(in: .whitespaces)
                        return (branchName, branchPath)
                    }

                    return nil
                }
                
                DispatchQueue.main.async {
                    self.branches = existBranchInfos.map { Branch(name: $0.0, folder: $0.1, belongTo: self) }
                    DataSource.shared.onProjectRefreshed$.send(self)
                }
            }
        }
    }
}

class Branch: ObservableObject, Equatable {
    static func == (lhs: Branch, rhs: Branch) -> Bool {
        lhs.id == rhs.id
    }

    var id: String {
        project.name + "_" + name
    }

    let name: String
    let folder: String
    let workspace: String?
    let xcodeproj: String?
    let project: Project
    var displayName: String {
        name
    }
    var derivedDataPath: String {
        // 如果有 workspace 或者 xcodeproj 文件，则 derived 开头为对应的名字，否则就是文件夹名字
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let branchHash = hashStringForPath(folder + "/" + (workspace ?? xcodeproj ?? "")) ?? ""
        var derivedDataPrefix = String(folder.split(separator: "/").last ?? "")

        if let projectName = (workspace ?? xcodeproj)?.split(separator: ".").first {
            derivedDataPrefix = String(projectName)
        }

        return "\(home)/Library/Developer/Xcode/DerivedData/\(derivedDataPrefix)-\(branchHash)"
    }
    @Published var runningTasks: [RunningTask] = []

    init(name: String, folder: String, belongTo: Project) {
        self.name = name
        self.folder = folder
        self.workspace = belongTo.workspace
        self.project = belongTo
        
        var proj = ""
        if let firstProjFile = (try? FileManager.default.contentsOfDirectory(atPath: folder).first { $0.hasSuffix(".xcodeproj") }) {
            proj = firstProjFile
        }

        self.xcodeproj = proj
    }

    func generateCommandId(command: Command) -> String {
        "Bosswift_\(id)_\(command.id)".replacingOccurrences(of: "/", with: "_")
    }
}

enum CloneStatus {
    case cloned
    case waitingForClone
    case cloning(ShellTask)
    case failed(ShellTask)

    var isCloned: Bool {
        if case .cloned = self {
            return true
        }

        return false
    }

    var isWaitingForClone: Bool {
        if case .waitingForClone = self {
            return true
        }

        return false
    }

    var shellTask: ShellTask? {
        if case let .cloning(task) = self {
            return task
        }

        if case let .failed(task) = self {
            return task
        }

        return nil
    }
}

enum SPMStatus {
    case standBy, resolving(ShellTask), failed(ShellTask)

    var shellTask: ShellTask? {
        if case let .resolving(task) = self {
            return task
        }

        if case let .failed(task) = self {
            return task
        }

        return nil
    }
}

enum CocoapodsStatus {
    case standBy, resolving(ShellTask), failed(ShellTask)

    var shellTask: ShellTask? {
        if case let .resolving(task) = self {
            return task
        }

        if case let .failed(task) = self {
            return task
        }

        return nil
    }
}

enum WorkTreeStatus {
    case standBy
    case processing(ShellTask)
    case failed(ShellTask)

    var shellTask: ShellTask? {
        if case let .processing(task) = self {
            return task
        }

        if case let .failed(task) = self {
            return task
        }

        return nil
    }
}
