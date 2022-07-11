import AppKit
import SwiftUI
import Combine

let iconSize: CGFloat = 20
let defaultIcon = #imageLiteral(resourceName: "AppIcon")
let errorIcon = #imageLiteral(resourceName: "DeadFish")

let quickLaunchWindowMaxHeight: CGFloat = 727

class StatusBarController {
    var quickLaunchWindow = KeyboardNavigableWindow(
        contentRect: NSRect(x: 0, y: 0, width: 700, height: quickLaunchWindowMaxHeight),
        backing: .buffered, defer: false)
    var managerWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 500, height: 500), styleMask: [.closable, .titled, .resizable],
        backing: .buffered, defer: false)
    var onBoardingWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 500, height: 820), styleMask: [.closable, .titled],
        backing: .buffered, defer: false)
    
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var mainPopover: NSPopover
    private var quickLaunchWindowReady = false
    private var onBoardingWindowReady = false
    private var managerWindowReady = false
    private var runningTasksSubscription: AnyCancellable?

    init(_ popover: NSPopover) {
        self.mainPopover = popover
        statusBar = .system
        statusItem = statusBar.statusItem(withLength: iconSize)

        if !AppEnvironment.isInPreviewMode {
            if let statusBarButton = statusItem.button {
                statusBarButton.image = defaultIcon
                statusBarButton.image?.size = NSSize(width: iconSize, height: iconSize)
                statusBarButton.image?.isTemplate = false
                statusBarButton.imagePosition = .imageLeft

                statusBarButton.action = #selector(onIconClicked(sender:))
                statusBarButton.target = self
            }
        }

        quickLaunchWindow.isReleasedWhenClosed = false
        onBoardingWindow.isReleasedWhenClosed = false
        managerWindow.isReleasedWhenClosed = false

        runningTasksSubscription = TaskScheduler.shared.$runningTasks.sink { [weak self] tasks in
            var newText = tasks.values.isEmpty ? "" : "\(tasks.values.count)"

            if newText.count > 2 {
                newText = "99+"
            }

            let textWidth = newText.width(withConstrainedHeight: iconSize, font: .systemFont(ofSize: 14))
            self?.statusItem.length = iconSize + textWidth
            self?.statusItem.button?.title = newText
        }
    }

    @objc func onIconClicked(sender: AnyObject) {
        if !appSetting.onboardingFinished {
            showOnBoardingWindow()
        } else {
            showManagerWindow()
        }
    }

    func refreshQuickLaunchWindow() {
        quickLaunchWindow.close()
        let contentView = QuickLaunchBarView()
            .frame(minWidth: 700, maxHeight: quickLaunchWindowMaxHeight)

        quickLaunchWindow.contentView = NSHostingView(rootView: contentView)
    }

    func toggleQuickLaunchWindow() {
        if quickLaunchWindow.isKeyWindow {
            quickLaunchWindow.close()
            return
        }

        guard !quickLaunchWindowReady else {
            showQuickLaunch()
            return
        }

        // Create the SwiftUI view that provides the window contents.
        let contentView = QuickLaunchBarView()
            .frame(minWidth: 700, maxHeight: quickLaunchWindowMaxHeight)

        quickLaunchWindow.contentView = NSHostingView(rootView: contentView)
        quickLaunchWindow.isOpaque = false
        quickLaunchWindow.backgroundColor = .clear
        quickLaunchWindow.center()
        quickLaunchWindow.setFrame(quickLaunchWindow.frame.applying(CGAffineTransform.init(translationX: 0, y: -40)), display: false)
        quickLaunchWindowReady = true
        showQuickLaunch()
    }

    private func showQuickLaunch() {
        guard !AppEnvironment.isInPreviewMode else {
            return
        }

        DataSource.shared.refreshProjectBranches()
        MouseMoveMonitor.shared.reset()
        NSApp.activate(ignoringOtherApps: true)
        quickLaunchWindow.makeKeyAndOrderFront(nil)
        quickLaunchWindow.orderFrontRegardless()
        autoSelectTextBlock()
    }

    func showOnBoardingWindow() {
        guard !onBoardingWindowReady else {
            showOnBoarding()
            return
        }

        let contentView = OnBoardingView()
            .frame(minWidth: 700, maxHeight: 900)

        onBoardingWindow.contentView = NSHostingView(rootView: contentView)
        onBoardingWindow.isOpaque = false
        onBoardingWindow.backgroundColor = .clear
        onBoardingWindow.center()
        onBoardingWindowReady = true
        showOnBoarding()
    }

    private func showOnBoarding() {
        guard !AppEnvironment.isInPreviewMode else {
            return
        }

        NSApp.activate(ignoringOtherApps: true)
        onBoardingWindow.makeKeyAndOrderFront(nil)
        onBoardingWindow.orderFrontRegardless()
    }

    func toggleDashboardWindow() {
        if managerWindow.isKeyWindow {
            managerWindow.close()
        } else {
            showManagerWindow()
            ManagerView.selectedTab.send(.dashboard)
        }
    }

    func showManagerWindow() {
        guard !managerWindowReady else {
            showManager()
            return
        }

        let contentView = ManagerView()
            .frame(minWidth: 700)

        managerWindow.contentView = NSHostingView(rootView: contentView)
        managerWindow.isOpaque = false
        managerWindow.backgroundColor = .clear
        managerWindow.center()
        managerWindow.setFrame(managerWindow.frame.applying(CGAffineTransform.init(translationX: 0, y: -100)), display: false)
        managerWindowReady = true
        showManager()
    }

    private func showManager() {
        quickLaunchWindow.close()
        guard !AppEnvironment.isInPreviewMode else {
            return
        }

        MouseMoveMonitor.shared.reset()
        NSApp.activate(ignoringOtherApps: true)
        managerWindow.title = "Bosswift"
        managerWindow.makeKeyAndOrderFront(nil)
        managerWindow.orderFrontRegardless()
    }

    func autoSelectTextBlock() {
        DispatchQueue.main.async { [weak self] in
            guard let contentView = self?.quickLaunchWindow.contentView, let textField = self?.locateQuickLaunchTextField(view: contentView) else {
                return
            }

            if let commandBeginRange = textField.stringValue.range(of: " /") {
                textField.currentEditor()?.selectedRange = NSRange(commandBeginRange.upperBound..<textField.stringValue.endIndex
, in: textField.stringValue)
            } else {
                textField.selectText(textField)
            }
        }
    }

    func locateQuickLaunchTextField(view: NSView) -> NSTextField? {
        if let textField = view as? NSTextField {
            return textField
        }

        for subview in view.subviews {
            if let textField = locateQuickLaunchTextField(view: subview) {
                return textField
            }
        }

        return nil
    }

    func togglePopover() {
        onIconClicked(sender: self)
//        if (mainPopover.isShown) {
//            hidePopover()
//        } else {
//            showPopover()
//        }
    }

    func showPopover() {
        if let statusBarButton = statusItem.button {
            mainPopover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: .maxY)
            DispatchQueue.main.async {
                NSApplication.shared.activate(ignoringOtherApps: true)
                if let textField = self.findFirstTextField(subViews: self.mainPopover.contentViewController?.view.subviews ?? []) {
                    self.mainPopover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
                    textField.becomeFirstResponder()
                }
            }
        }
    }

    func hidePopover() {
        mainPopover.close()
    }

    func showNormal() {
        if let statusBarButton = statusItem.button {
            statusBarButton.image = defaultIcon
            statusBarButton.image?.size = NSSize(width: iconSize, height: iconSize)
            statusBarButton.image?.isTemplate = false
        }
    }

    func showError() {
        if let statusBarButton = statusItem.button {
            statusBarButton.image = errorIcon
            statusBarButton.image?.size = NSSize(width: iconSize, height: iconSize)
            statusBarButton.image?.isTemplate = false
        }
    }

    func updateBadgeIcon(icon: NSImage) {
        statusItem.button?.image = icon
        statusItem.button?.image?.size = NSSize(width: iconSize, height: iconSize)
    }

    func destroy() {
        statusBar.removeStatusItem(statusItem)
    }

    func findFirstTextField(subViews: [NSView]) -> NSTextField? {
        for view in subViews {
            if let field = view as? NSTextField {
                return field
            }
            if let subTextField = findFirstTextField(subViews: view.subviews) {
                return subTextField
            }
        }

        return nil
    }
}
