//
//  Constants.swift
//  MenuBarPhoto
//
//  Created by KHJ on 8/14/24.
//

import Foundation

import Defaults
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePopover = Self("togglePopover")
}

extension Defaults.Keys {
    static let accessCount = Key<Int>("accessCount", default: 0)
}
