//
//  AppDelegate.swift
//  MenuBarPhoto
//
//  Created by KHJ on 8/14/24.
//

import Cocoa
import SwiftUI

import Defaults
import KeyboardShortcuts

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    private var imageWindow: NSWindow!
    private var settingsWindow: NSWindow!
    private var cropWindow: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
//        print(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path ?? "nil")

        if let statusButton = statusItem.button {
            statusButton.image = NSImage(systemSymbolName: "heart", accessibilityDescription: "Menubar Gallery")
            statusButton.action = #selector(togglePopover)
        }

        self.popover = NSPopover()
        self.popover.contentSize = NSSize(width: 300, height: 300)
        self.popover.behavior = .transient

        let savedPhotos = CoreDataStack.shared.fetchPhotos()
        self.popover.contentViewController = NSHostingController(rootView: HomeView(photos: savedPhotos))
        self.popover.animates = false

        KeyboardShortcuts.onKeyUp(for: .togglePopover) {
            self.togglePopover()
        }
    }

    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                self.popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)

                /// Make the popover close when users interact with outside
                /// Without this the popover will stay
                popover.contentViewController?.view.window?.makeKey()

                Defaults[.accessCount] += 1
            }
        }
    }

    func openSettingsWindow() {
        let contentView = SettingsScreen()

        if settingsWindow != nil {
            settingsWindow.close()
        }

        settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 340),
            styleMask: [.closable, .titled],
            backing: .buffered,
            defer: false
        )

        settingsWindow.title = "Settings"
        settingsWindow.contentView = NSHostingView(rootView: contentView)
        settingsWindow.makeKeyAndOrderFront(nil)
        settingsWindow.styleMask.remove(.resizable)

//        NSApplication.shared.activate()

        let controller = NSWindowController(window: settingsWindow)
        controller.showWindow(self)

        settingsWindow.center()
        settingsWindow.orderFrontRegardless()
    }

    func openCropWindow(photo: Photo) {
        let contentView = CropWindow(photo: photo)

        if cropWindow != nil {
            cropWindow.close()
        }

        cropWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
            styleMask: [.closable, .titled],
            backing: .buffered,
            defer: false
        )

        cropWindow.title = "Crop your Image"
        cropWindow.contentView = NSHostingView(rootView: contentView)
        cropWindow.makeKeyAndOrderFront(nil)
        cropWindow.styleMask.remove(.resizable)

        NSApplication.shared.activate()
        let controller = NSWindowController(window: cropWindow)
        controller.showWindow(self)

        cropWindow.center()
        cropWindow.orderFrontRegardless()
    }

    func terminate() {
        NSApplication.shared.terminate(self)
    }
}
