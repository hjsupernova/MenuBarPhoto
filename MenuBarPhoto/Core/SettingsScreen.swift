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
                Text("You've opened your memories \(accessCount) times")
            }

            Section {
                KeyboardShortcuts.Recorder("Toggle Gallery", name: .togglePopover)
            }

            Section {
                LaunchAtLogin.Toggle()
            }

            Section {
                HStack {
                    Text("Quit Gallery")

                    Spacer()

                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Image(systemName: "power")
                    }
                }
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
