//
//  KeyAwareTextFieldDelegate.swift
//  Bosswift
//
//  Created by huikai on 2022/6/18.
//

import AppKit
import Foundation

class KeyAwareTextFieldDelegate : NSObject, NSTextFieldDelegate {

    var originDelegate: NSTextFieldDelegate!

    enum MoveDirection {
        case up, down, left, right
    }

    var onArrowKeyMoved: ((MoveDirection) -> Void)?
    var onEnterKeyPressed: (() -> Void)?
    var onTabKeyPressed: (() -> Void)?
    var onDeleteBackward: (() -> Void)?

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.moveUp(_:)) {
            onArrowKeyMoved?(.up)
        } else if commandSelector == #selector(NSResponder.moveDown(_:)) {
            onArrowKeyMoved?(.down)
        } else if commandSelector == #selector(NSResponder.moveLeft(_:)) {
            onArrowKeyMoved?(.left)
            return false
        } else if commandSelector == #selector(NSResponder.moveRight(_:)) {
            onArrowKeyMoved?(.right)
            return false
        } else if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            onEnterKeyPressed?()
            return false
        } else if commandSelector == #selector(NSResponder.insertTab(_:)) {
            onTabKeyPressed?()
            return false
        } else if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
            onDeleteBackward?()
            return false
        } else {
            return false
        }

        return true
    }

    func textField(_ textField: NSTextField, textView: NSTextView, candidatesForSelectedRange selectedRange: NSRange) -> [Any]? {
        originDelegate.textField?(textField, textView: textView, candidatesForSelectedRange: selectedRange)
    }

    func textField(_ textField: NSTextField, textView: NSTextView, candidates: [NSTextCheckingResult], forSelectedRange selectedRange: NSRange) -> [NSTextCheckingResult] {
        originDelegate.textField?(textField, textView: textView, candidates: candidates, forSelectedRange: selectedRange) ?? []
    }

    func textField(_ textField: NSTextField, textView: NSTextView, shouldSelectCandidateAt index: Int) -> Bool {
        originDelegate.textField?(textField, textView: textView, shouldSelectCandidateAt: index) ?? true
    }

    func controlTextDidBeginEditing(_ obj: Notification) {
        originDelegate.controlTextDidBeginEditing?(obj)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        originDelegate.controlTextDidEndEditing?(obj)
    }

    func controlTextDidChange(_ obj: Notification) {
        originDelegate.controlTextDidChange?(obj)
    }

    func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        originDelegate.control?(control, textShouldBeginEditing: fieldEditor) ?? true
    }

    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        originDelegate.control?(control, textShouldEndEditing: fieldEditor) ?? true
    }

    func control(_ control: NSControl, didFailToFormatString string: String, errorDescription error: String?) -> Bool {
        originDelegate.control?(control, didFailToFormatString: string, errorDescription: error) ?? true
    }

    func control(_ control: NSControl, didFailToValidatePartialString string: String, errorDescription error: String?) {
        originDelegate.control?(control, didFailToValidatePartialString: string, errorDescription: error)
    }

    func control(_ control: NSControl, isValidObject obj: Any?) -> Bool {
        originDelegate.control?(control, isValidObject: obj) ?? true
    }


    func control(_ control: NSControl, textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String] {
        originDelegate.control?(control, textView: textView, completions: words, forPartialWordRange: charRange, indexOfSelectedItem: index) ?? []
    }
}
