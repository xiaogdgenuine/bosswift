//
//  MouseMoveMonitor.swift
//  Bosswift
//
//  Created by huikai on 2022/6/30.
//

import Foundation
import Combine

class MouseMoveMonitor: ObservableObject {
    static let shared = MouseMoveMonitor()

    @Published var mouseMoved = false

    func onMouseMove() {
        mouseMoved = true
    }

    func reset() {
        mouseMoved = false
    }
}
