//
//  MenuBarPhotoApp.swift
//  MenuBarPhoto
//
//  Created by KHJ on 8/13/24.
//

import SwiftUI

@main
struct MenuBarPhotoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsScreen()
        }
    }
}
