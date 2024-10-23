//
//  main.swift
//  MenuBarPhoto
//
//  Created by KHJ on 10/23/24.
//

import Foundation
import AppKit

// 1
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// 2
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
