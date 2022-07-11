# Bosswift - A command launcher for git users

Bosswift work along with [git worktree](https://git-scm.com/docs/git-worktree) to give you power everyday.

System Requirement:
macOS 11.0+

## A troublesome thing

![bosswift_cover](https://s2.loli.net/2022/07/10/AOeoQdW5Nk7pliG.jpg)

As a developer，have you ever had this experience?

> You are working on some feature development, your colleague Slack you and ask you why an on-live feature is behaving weirdly, he want you to help check the problem and reproduce it.

You say ok, then you open Terminal, type bunch of commands:

```bash
# Store your temporary works
git stash -u
# Switch to problematic branch
git checkout release/v1
# Pull the latest changes
git pull
# Install 3rd dependencies, setup runtime
npm install...
# Run the project and try to address issue
npm run...
```

This usually will take you couple minutes, and after the issue is resolved, you go back to work on your original task, by type these commands in Terminal:

```bash
# Switch back to work branch
git checkout feature/in-development
# Restore your temporary works
git stash apply
# Install 3rd dependencies, setup runtime
npm install...
# Run the project and continue to work
npm run...
```

This can happen multiple times in a day, not just to address a production issue, sometimes you also need to check different branch's runtime behavior, so you need to **switch > build and run > switch > build and run...** over and over.

This doesn't sound productive, what can we do about it?

Well, imagine that if we could checkout multiple branch in same machine from a repo, every branch got it's own worktree, by this way can we solve the problem?

Yes we did! Git team apparently notice this problem too, start from git v2.5, [multiple worktrees](https://git-scm.com/docs/git-worktree) support is added, you can create multiple worktree copies from one repo, each worktree got it's own branch, just like this：

![bosswift-git-worktree-explain](https://s2.loli.net/2022/07/11/bqQ4cdguWPxza3Z.webp)

With **git worktree**，we don't checkout branch anymore, instead we **_cd_** around worktrees，and also no need to stash/unstash anymore：

![bosswift-new-fashion](https://s2.loli.net/2022/07/11/U62tEvT1gIrsKlY.jpg)

The most important is, you don't need to re-install 3rd dependencies constantly, because every worktree is stable if you don't touch them!

Also if we do it right, **git worktree** can help us make sure there is always a branch that can run anytime, you don't need to worry about your in-development works impact other stable worktrees, sometime this is important.

## New solution always come with problems
**git worktree** command got some pain points when using it：
- Too many keystrokes, when you create a new worktree, you need to specify it's path, it's branch name, I often make mistake on these arguments
- When you **_cd_** around worktrees, you often get lost
- Too many disk usage, because now every worktree got it's own copy of 3rd dependencies(like _node_modules_)

## ✨✨✨ Bosswift ✨✨✨
To solve these pain points come with use **git worktree** in command line way，**Bosswift** is born.
**Bosswift** is a GUI app that integrated with git worktree deeply, it will help you manage worktrees without presure.

![bosswift-introduction](https://s2.loli.net/2022/07/11/dQnKzR5gjMTA718.png)

# Installation + Setup
You can download the latest release from [here](https://github.com/xiaogdgenuine/bosswift/releases/latest)

![bosswift-install](https://s2.loli.net/2022/07/11/E9tuLSBJAUX6bjd.png)

Some setups is required when you open **Bosswift**，the only important step is to specify where you put your working repos, so that **Bosswift** can monitor & sync the worktree status with your repos:

![bosswift-on-boarding](https://s2.loli.net/2022/07/11/WJIgGTZHxsq92ak.png)

# Usage
After you done configuration, press **_Option + Space_** (Default) to open quick launch bar.

![bosswift-quick-launch-bar](https://s2.loli.net/2022/07/11/BA4dlWFDEuaqjVe.png)

Step 1, search & pick a worktree，hit enter/tab to select it：

![bosswift-quick-launch-search-branch](https://s2.loli.net/2022/07/11/icIqUQ8T3s9m1jX.png)

Step 2. Search & pick a command, hit enter to execute：

![bosswift-quick-pick-command](https://s2.loli.net/2022/07/11/9tc7LSs6mf5IJMQ.png)

## Create new Worktree
When you need a new worktree, do this command:

![bosswift-create-worktree](https://s2.loli.net/2022/07/11/6EXZYkdlr5Pa2Jv.png)

All you need is to input a branch name:

![bosswift-create-worktree-branch-name](https://s2.loli.net/2022/07/11/N7PVZYqS6zlv2nC.png)

It will take care these cases for you
- A local branch with same name exist：Switch new worktree to that branch.
- A same name branch exists in remote：Fetch that remote branch to local，create new worktree and switch to that branch.
- Totally new branch：Create new worktree with specified branch name.

You could modify that command, add some steps like "**Copy node_modules from original worktree**" to the end, to avoid re-install node modules in new worktree.

## Delete Worktree
Whe you no longer work on a worktree, you can save the disk usage by doing this command to delete the worktree：

![bosswift-delete-worktree](https://s2.loli.net/2022/07/11/KXynVNlpHodg69h.png)

You could modify that command, add some steps like "**Delete Xcode Derived Data folder**" to the end, to release disk space.

# Create custom commands
What kind of Boss you are if you can't create your own command?

I encourage you to write commands that suits your project and workflow, I don't have that energy to provide you a fancy command editor, but I will give you my help as much as I can, there are some variables you can use when creating new command:

![bosswift-command-glossary](https://s2.loli.net/2022/07/11/rvRZuxigzPkdTVJ.png)

For example, if I select _feature_ branch of _Doll_ Repo under path _/Users/huikai/dev_, here is all variable's value:
|  Name | Means | Value  |
|  ----  | ----  | ----  |
| $BOSSWIFT_WORK_FOLDER  |  Bosswift's working folder  | /Users/huikai/dev |
| $BOSSWIFT_PROJECT_NAME |  Repo's folder name  | Doll |
| $BOSSWIFT_BRANCH_NAME |  Selected branch's name  | feature |
| $BOSSWIFT_WORKTREE_PATH |  The folder path of current worktree  | /Users/huikai/dev/Bosswift_Work/Doll/feature |
| $BOSSWIFT_DEFAULT_WORKTREE_PATH |  The folder path of repo's main worktree | /Users/huikai/dev/Doll |
| $BOSSWIFT_XCODE_DERIVED_PATH |  Xcode Derived folder path for worktree (For Apple developers)  | /Users/huikai/Library/Developer/Xcode/DerivedData/Doll-cikiwqgnfwrbgzgebttnrazqigks |
| $BOSSWIFT_XCODE_WORKSPACE_FILE |  xcworkspace file name inside worktree (For Apple developers)  | Doll.xcworkspace |
| $BOSSWIFT_XCODE_PROJECT_FILE | xcodeproj file name inside worktree (For Apple developers)  | Doll.xcodeproj |

# Dashboard
You can check running tasks in Dashboard:

![bosswift-dashboard](https://s2.loli.net/2022/07/11/sdKzgDEtYRvQj5N.png)

# As an Universal command launcher
Some command can be run from anywhere, and you always forgot how to type them, for example sometimes Xcode failed to recognize iPhone connected by usb cable, to fix that I need to restart **usb service**, but I never remember the command, I always need to copy it from google or Notes app.

Now with **Bosswift**，you could put these commands into **Universal Command**：

![bosswift-universal-commands](https://s2.loli.net/2022/07/11/ivKCaHUuGOwADyX.png)

Type "/" in quick launch box, then you can pick an Universal Command to run:

![bosswift-select-universal-command](https://s2.loli.net/2022/07/11/tkEiXnsAhY9Bxcb.png)

# As a temporary command launcher
If there's not command match the keyword in quick launch box, you can hit enter and execute the keyword as command directly:

![bosswift-temporary-commands](https://s2.loli.net/2022/07/11/UIE45RKTbSrCiNg.png)

## Command line or GUI?
To be honest, as a developer, I never get used to Terminal.

I'm very careful when doing tasks in command line, I check my input over and over again to make sure I didn't write to wrong file, delete the wrong folder, I'm rather slow on Terminal because these stresses...

I love GUI, really, proper designed GUI tools is really master pice, easy to use and stress-free.
But when it comes to automation, command line just.... kill GUI :). GUI just not design for automation tasks, you just can't setup the workflow easily with GUI.

Luckly, we don't have to choice between them, we can have an application that include both Command line and GUI.

This app can't run without command line, the _screen_ command is the core behind it(For dispatching tasks), and in order to manage running tasks, commands like _ps_, _grep_, _pkill_ is necessary too, put all these commands with an easy to use GUI, we got **Bosswift** :P.

# Source code
https://github.com/xiaogdgenuine/bosswift

Disclaimer:
When it comes to personal project, my code style is rather rough.

I prefer do the damn thing first then see how it goes, if it works I will clear the code and re-architecture, if it's not working I will keep rough style till it works.

This Repo is currently full of ugly global variables, un-reasonable module separation and un-reliable assumptions about running environment.
