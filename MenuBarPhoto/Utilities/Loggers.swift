//
//  Loggers.swift
//  MenuBarPhoto
//
//  Created by KHJ on 12/10/24.
//

import Foundation
import OSLog

let logPhoto = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "photo")
let logRating = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "rating")
let logDB = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "db")

@available(*, deprecated, message: "Use logger instead")
func print(_ items: Any...) {}
