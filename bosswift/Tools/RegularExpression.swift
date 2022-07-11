//
//  RegularExpression.swift
//  Bosswift
//
//  Created by huikai on 2022/6/26.
//

import Foundation

extension NSRegularExpression {
    func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}
