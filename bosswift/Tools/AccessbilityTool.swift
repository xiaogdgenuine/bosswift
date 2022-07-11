//
//  AccessbilityTool.swift
//  Bosswift
//
//  Created by huikai on 2022/6/17.
//

import Foundation
import Combine
import AppKit

enum AccessbilityTool {
    public static let isTrusted = CurrentValueSubject<Bool, Never>(false)

    private static var timer: Timer?

    public static func startCheckAXStatus() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if AXIsProcessTrustedWithOptions(nil) {
                isTrusted.send(true)
                timer.invalidate()
            }
        }
        timer?.fire()
    }
}
