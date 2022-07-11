import Cocoa
import SwiftUI
import Combine

class KeyboardNavigableWindow: NSPanel {

    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.fullSizeContentView], backing: backing, defer: flag)

        self.isFloatingPanel = true
        self.level = .floating
        self.isReleasedWhenClosed = false
        acceptsMouseMovedEvents = true
    }

    // `canBecomeKey` and `canBecomeMain` are required so that text inputs inside the panel can receive focus
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

    override func mouseMoved(with event: NSEvent) {
        MouseMoveMonitor.shared.onMouseMove()
    }
}

