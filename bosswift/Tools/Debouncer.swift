//
//  Debouncer.swift
//  Bosswift
//
//  Created by huikai on 2022/6/26.
//

import Foundation

typealias Debounce = () -> Void

func debounce(interval: Int, queue: DispatchQueue, action: @escaping Debounce) -> Debounce {
    let dispatchDelay = DispatchTimeInterval.milliseconds(interval)
    var workItem: DispatchWorkItem?

    return {
        let dispatchTime: DispatchTime = DispatchTime.now() + dispatchDelay
        workItem?.cancel()
        workItem = DispatchWorkItem {
            action()
        }
        queue.asyncAfter(deadline: dispatchTime, execute: workItem!)
    }
}
