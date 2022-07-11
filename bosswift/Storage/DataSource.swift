import Foundation
import Combine
import AppKit

class DataSource: ObservableObject {
    static let shared = DataSource()

    @Published var commandIcons: [Int: NSImage] = [:]
    @Published var projects: [Project] = []
    var onProjectRefreshed$ = PassthroughSubject<Project, Never>()
    private var folderObserver: FileChangeObserver?

    func setup() {
        updateProjectRootURL()
        appSetting.refreshCommandIcons()
    }

    func refreshProjectBranches() {
        self.projects.forEach { project in
            project.loadBranches()
        }
    }

    func updateProjectRootURL() {
        if let projectRootURL = URL(string: (appSetting.baseFolder ?? "").addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "") {
            print("Watching: ", projectRootURL.path.removingPercentEncoding ?? "")
            self.updateProjects(rootURL: projectRootURL)
            folderObserver = FileChangeObserver(url: projectRootURL) {
                self.updateProjects(rootURL: projectRootURL)
            }
        } else {
            folderObserver = nil
        }
    }

    func updateProjects(rootURL: URL) {
        let latestProjects = fetchProjects(at: rootURL)
        let deletedProjects = projects.filter { cachedProject in !latestProjects.contains { project in project.name == cachedProject.name } }
        deletedProjects.forEach { project in
            project.branches.forEach { branch in
                TaskScheduler.shared.terminateTask(relatedTo: branch)
            }
        }

        projects = latestProjects
        sortProjects()
    }

    func sortProjects() {
        let pinnedProjects = appSetting.pinnedProjects
        projects.sort {
            let pinnedIndexA = pinnedProjects.firstIndex(of: $0.name)
            let pinnedIndexB = pinnedProjects.firstIndex(of: $1.name)
            if pinnedIndexA != nil && pinnedIndexB == nil {
                return true
            }

            if pinnedIndexA == nil && pinnedIndexB != nil {
                return false
            }

            if pinnedIndexA == nil && pinnedIndexB == nil {
                return $0.name.localizedCompare($1.name) == .orderedAscending
            }

            return pinnedIndexA! < pinnedIndexB!
        }
    }

    private func fetchProjects(at: URL) -> [Project] {
        let projects = ((try? FileManager.default
            .contentsOfDirectory(at: at, includingPropertiesForKeys: [URLResourceKey.isDirectoryKey])) ?? [])
            .filter { $0.hasDirectoryPath }
            .compactMap { folderURL -> Project? in
                let projectName = folderURL.lastPathComponent
                let project = Project(name: projectName, branches: [])
                let projectRootContents = (try? FileManager.default.contentsOfDirectory(atPath: folderURL.path)) ?? []

                if !(projectRootContents.contains { $0 == ".git" }) {
                    // Not a git repository
                    return nil
                }

                // if ".git" is a file, we are looking at a worktree copy, ignore them
                if (try? folderURL.appendingPathComponent(".git").resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false) == false {
                    return nil
                }
                
                if let workspaceFile = (projectRootContents.first {
                    $0.hasSuffix(".xcworkspace")
                }) {
                    project.workspace = "\(workspaceFile)"
                }

                project.displayName = appSetting.projectNameMappings[project.name] ?? project.name
                project.folder = folderURL.path
                project.loadBranches()

                return project
            }


//        let noClonedProjectNames = allProjectNames.keys.filter { projectName in
//            !projects.contains {
//                $0.name == projectName
//            }
//        }
//        let noClonedProjects: [Project] = []
//
//        projects.append(contentsOf: noClonedProjects)

        return projects
    }
}
