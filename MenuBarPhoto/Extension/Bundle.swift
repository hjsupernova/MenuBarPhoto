//
//  Bundle.swift
//  MenuBarPhoto
//
//  Created by KHJ on 11/10/24.
//

import Foundation

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
