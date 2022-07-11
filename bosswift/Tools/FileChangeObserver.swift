//
//  FileChangeObserver.swift
//  Bosswift
//
//  Created by huikai on 2022/6/26.
//

import Foundation

class FileChangeObserver {
    private var fileDescriptor: CInt? = nil
    private var source: DispatchSourceProtocol? = nil

    init(url: URL, block: @escaping ()-> Void) {
        if FileManager.default.fileExists(atPath: url.path.removingPercentEncoding ?? url.path) {
            self.fileDescriptor = open(url.path, O_EVTONLY)
            self.source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: self.fileDescriptor!, eventMask: .all, queue: DispatchQueue.main)
        }
        let debouncedCallback = debounce(interval: 1000, queue: .main, action: block)
        self.source?.setEventHandler {
            debouncedCallback()
        }
        self.source?.resume()
    }

    deinit {
        self.source?.cancel()
        if let fileDescriptor = fileDescriptor {
            close(fileDescriptor)
        }
    }
}
