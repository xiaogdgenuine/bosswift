//
//  AppEnvironment.swift
//  Bosswift
//
//  Created by huikai on 2022/6/25.
//

import Foundation

enum AppEnvironment {

    static var isInPreviewMode: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

}
