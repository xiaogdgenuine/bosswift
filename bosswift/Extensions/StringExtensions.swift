//
//  StringExtensions.swift
//  Bosswift
//
//  Created by huikai on 2022/6/20.
//

import Foundation
import AppKit

extension String {
    func substr(_ r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return String(self[start..<end])
    }

    func width(withConstrainedHeight height: CGFloat, font: NSFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }
    
    var pathWithoutExt: String {
        var components = self.components(separatedBy: ".")
        if components.count > 1 {
            components.popLast()
        }
        return components.joined(separator: ".")
    }
}
