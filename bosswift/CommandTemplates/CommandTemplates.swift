//
//  CommandTemplates.swift
//  Bosswift
//
//  Created by huikai on 2022/6/16.
//

import Foundation

enum CommandTemplates {

    static var latestCommandId: Int {
        commandIdCounter += 1
        return commandIdCounter
    }

    static let universalTemplates: [CommandGroup] = [
        CommandGroup(groupName: "Universal", commands: [
            Command(id: latestCommandId, commandKeyword: "restart-usb-service", displayName: "Restart usb service", scripts: [.script(content:
            """
            echo "sudo pkill usbmuxd"
            sudo pkill usbmuxd
            """)], runSilently: false),
            Command(id: latestCommandId, commandKeyword: "restart-audio-service", displayName: "Restart core audio service", scripts: [.script(content:
                """
                echo "sudo killall coreaudiod"
                sudo killall coreaudiod
                """)], runSilently: false)
        ])
    ]
    static let templates: [CommandGroup] = [
        CommandGroup(groupName: "General", commands: [
            Command(id: latestCommandId, commandKeyword: "terminal", displayName: "Open in Terminal", scripts: [.script(content: "open -b com.apple.terminal \"$BOSSWIFT_WORKTREE_PATH\"")], runSilently: true),
            Command(id: latestCommandId, commandKeyword: "finder", displayName: "Open in finder", scripts: [.script(content: "open .")], runSilently: true),
            Command(id: latestCommandId, commandKeyword: "vscode", displayName: "Open in VS Code", scripts: [.script(content: "open -b com.microsoft.VSCode $BOSSWIFT_WORKTREE_PATH")], runSilently: true),
            Command(id: latestCommandId, commandKeyword: "xed", displayName: "Open in Xcode", scripts: [.script(content: "xed .")], runSilently: true),
            Command(id: latestCommandId, commandKeyword: "git-create-worktree", displayName: "Git: create a new worktree base on this branch", scripts: [.script(content:
            """
            # Modify this if you want a different working folder for new worktrees
            NEW_WORKTREE_FOLDER="${BOSSWIFT_WORK_FOLDER}/Bosswift_Work"

            echo "\\x1b[1mWhat branch should this new worktree use? \\x1b[0m"
            echo "\\x1b[2m(Could be a remote branch, no 'origin/' prefix needed, I will fetch it for you~)\\x1b[0m"
            read -p "Branch Name: " NEW_BRANCH_NAME

            set +e
            git worktree list | grep "\\[$NEW_BRANCH_NAME\\]" > /dev/null
            if [[ $? -ne 1 ]]
            then
                echo "This branch is already checkouted in another workspace:"
                git worktree list | grep "\\[$NEW_BRANCH_NAME\\]"
                exit 1
            fi

            # Check if target branch exist
            git show-ref --verify --quiet "refs/heads/${NEW_BRANCH_NAME}"
            CheckBranchExistResult=$?
            set -e

            NEW_WOKRTREE_DESTINATION="${NEW_WORKTREE_FOLDER}/${BOSSWIFT_PROJECT_NAME}/${NEW_BRANCH_NAME}"
            if [[ CheckBranchExistResult -ne 0 ]]
            then
                # No local branch with this name, let's check remote
                set +e
                git fetch origin ${NEW_BRANCH_NAME}

                if [[ $? -ne 128 ]]
                then
                    set -e
                    # A remote branch exist with same name, create the worktree with a temp branch, then checkout to target branch, delete the temp branch.
                    TEMP_BRANCH="${NEW_BRANCH_NAME}_bosswift_temp"
                    git branch -d "${TEMP_BRANCH}"

                    git worktree add -b "${NEW_BRANCH_NAME}" "${NEW_WOKRTREE_DESTINATION}" "${BOSSWIFT_BRANCH_NAME}"

                    cd "${NEW_WOKRTREE_DESTINATION}"
                    git checkout "${NEW_BRANCH_NAME}"
                    git branch -d "${TEMP_BRANCH}"
                else
                    set -e
                    # There is not corresponding branch on remote either, let's create a fresh new worktree
                    git worktree add -b "${NEW_BRANCH_NAME}" "${NEW_WOKRTREE_DESTINATION}" "${BOSSWIFT_BRANCH_NAME}"
                fi
            else
                # A local branch with same name exit, create the worktree with a temp branch, then checkout to target branch, delete the temp branch.
                set +e
                TEMP_BRANCH="${NEW_BRANCH_NAME}_bosswift_temp"
                git branch -D "${TEMP_BRANCH}"
                set -e

                git worktree add -b "${TEMP_BRANCH}" "${NEW_WOKRTREE_DESTINATION}" "${BOSSWIFT_BRANCH_NAME}"
                cd "${NEW_WOKRTREE_DESTINATION}"
                git checkout "${NEW_BRANCH_NAME}"
                git branch -D "${TEMP_BRANCH}"
            fi

            # fetch submodules
            git submodule update --init --recursive
            # insert your after-create-worktree-script here, like copy node_modules from original branch
            # cp -r "${BOSSWIFT_WORKTREE_PATH}/node_modules" "${NEW_WOKRTREE_DESTINATION}/node_modules"

            # open new created worktree in finder
            open "${NEW_WOKRTREE_DESTINATION}"
            """)]),
            Command(id: latestCommandId, commandKeyword: "git-pullall", displayName: "Git: pull the latest branch & submodule changes from remote", scripts: [.script(content: "git pull && git submodule update --init --recursive")], runSilently: false),
            Command(id: latestCommandId, commandKeyword: "git-rebase-develop", displayName: "Git: rebase latest develop branch", scripts: [.script(content:
                """
                echo "Fetching latest develop from remote..."
                git fetch origin develop:develop
                echo "Changes synced!!"
                git rebase develop
                """)], runSilently: false),
            Command(id: latestCommandId, commandKeyword: "git-delete-worktree", displayName: "Git: Delete worktree", scripts: [.script(content:
                """
                git worktree remove "${BOSSWIFT_WORKTREE_PATH}"
                # insert your after-delete-worktree-script here, like delete xcode derived data
                # rm -rf "${BOSSWIFT_XCODE_DERIVED_PATH}"
                """)], runSilently: false),
            Command(id: latestCommandId, commandKeyword: "git-delete-worktree-force", displayName: "Git: Delete worktree (Force)", scripts: [.script(content:
                """
                git worktree remove "${BOSSWIFT_WORKTREE_PATH}" -f
                # insert your after-delete-worktree-script here, like delete xcode derived data
                # rm -rf "${BOSSWIFT_XCODE_DERIVED_PATH}"
                """)], runSilently: false)
        ]),
        CommandGroup(groupName: "Apple Developer", commands: [
            Command(id: latestCommandId, commandKeyword: "spm", displayName: "Resolve Swift Packages", scripts: [.script(content:
                """
                COMMAND="xcodebuild -resolvePackageDependencies -IDECustomDerivedDataLocation=$HOME/Library/Developer/Xcode/DerivedData"
                if [ "$BOSSWIFT_XCODE_WORKSPACE_FILE" != "" ]
                then
                    $COMMAND="${COMMAND} -workspace ${BOSSWIFT_XCODE_WORKSPACE_FILE} -list"
                fi
                $COMMAND
                """)]),
            Command(id: latestCommandId, commandKeyword: "pod", displayName: "Pod install", scripts: [.script(content: "bundle exec pod install")]),
            Command(id: latestCommandId, commandKeyword: "derived", displayName: "Open derived data folder", scripts: [.script(content:
            """
            mkdir -p $BOSSWIFT_XCODE_DERIVED_PATH
            cd $BOSSWIFT_XCODE_DERIVED_PATH
            open .
            """)], runSilently: true),
            Command(id: latestCommandId, commandKeyword: "clear-derived", displayName: "Clear derived data", scripts: [.script(content: "rm -rf $BOSSWIFT_XCODE_DERIVED_PATH")], runSilently: true)
        ]),
        CommandGroup(groupName: "Web Developer", commands: [
            Command(id: latestCommandId, commandKeyword: "npm-install", displayName: "Npm install", scripts: [.script(content: "npm install")]),
            Command(id: latestCommandId, commandKeyword: "npm-build", displayName: "Npm build", scripts: [.script(content: "npm run build")]),
            Command(id: latestCommandId, commandKeyword: "npm-test", displayName: "Npm Test", scripts: [.script(content: "npm run test")])
        ])
    ]
}

struct CommandGroup {
    let groupName: String
    let commands: [Command]
}
