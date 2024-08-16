//
//  SettingsScreen.swift
//  MenuBarPhoto
//
//  Created by KHJ on 8/14/24.
//

import SwiftUI

import Defaults
import KeyboardShortcuts
import LaunchAtLogin

struct SettingsScreen: View {
    @Default(.accessCount) var accessCount
    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Toggle Popover", name: .togglePopover)
            }

            Section {
                LaunchAtLogin.Toggle()
            }

            Section {
                Text("You have missed Jana for \(accessCount) times")
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .fixedSize()
        .windowLevel(.floating + 1)
    }
}

#Preview {
    SettingsScreen()
}
