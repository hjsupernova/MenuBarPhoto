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
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Show photos", name: .togglePopover)
            }

            Section {
                LaunchAtLogin.Toggle()
            }

            Section {
                Text("You have missed your SO for \(accessCount) times")
            }

            Section {
                HStack {
                    Text("Quit Menubar Gallery")

                    Spacer()

                    Button {
                        appDelegate.terminate()
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
