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

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    private var imageWindow: NSWindow!
    private var settingsWindow: NSWindow!
    private var cropWindow: NSWindow!

    private var eventMonitor: Any? // Reference to the event monitor
    @Published var scrollEvent: NSEvent?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
//        print(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path ?? "nil")

        if let statusButton = statusItem.button {
            let icon = NSImage(named: "bunny-svg")
            icon?.size = NSSize(width: 24, height: 24)
            icon?.isTemplate = true
            statusButton.image = icon
            statusButton.action = #selector(handleClick(_:))
            statusButton.target = self
            statusButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        self.popover = NSPopover()
        self.popover.contentSize = NSSize(width: 300, height: 300)
        self.popover.behavior = .semitransient
        self.popover.animates = false

        let hostingController = NSHostingController(rootView: HomeView(photos: CoreDataStack.shared.fetchPhotos()))
        popover.backgroundColor = .white
        self.popover.contentViewController = hostingController

        KeyboardShortcuts.onKeyUp(for: .togglePopover) {
            self.togglePopover()
        }
    }
    @objc func handleClick(_ sender: NSButton) {
        let event = NSApp.currentEvent!
        if event.type == NSEvent.EventType.rightMouseUp {
            showMenu()
        } else {
            togglePopover()
        }
    }

    func showMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Bunny", action: #selector(togglePopover), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettingsWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Bunny", action: #selector(quit), keyEquivalent: ""))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)

        statusItem.menu = nil
    }

    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                self.popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)

                /// Make the popover close when users interact with outside
                /// Without this the popover will stay
//                popover.contentViewController?.view.window?.makeKey()

                Defaults[.accessCount] += 1
            }
        }
    }
    
    @objc
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

    func openCropWindow(contentView: NSView) {
        if cropWindow != nil {
            cropWindow.close()
        }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel, handler: { event in
            self.scrollEvent = event

            return event
        })

        cropWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
            styleMask: [.closable, .titled],
            backing: .buffered,
            defer: false
        )

        cropWindow.title = "Move & Scale"
        cropWindow.contentView = contentView
        cropWindow.makeKeyAndOrderFront(nil)
        cropWindow.styleMask.remove(.resizable)
        cropWindow.delegate = self

        NSApplication.shared.activate()
        let controller = NSWindowController(window: cropWindow)
        controller.showWindow(self)

        cropWindow.center()
        cropWindow.orderFrontRegardless()
    }

    @objc
    func quit() {
        NSApplication.shared.terminate(nil)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Clean up any references
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }

        eventMonitor = nil

        cropWindow?.contentView = nil
        cropWindow?.delegate = nil
        cropWindow = nil
    }
}

// NSPopover background color
extension NSPopover {
    private struct Keys {
        static var backgroundViewKey = "backgroundKey"
    }

    private var backgroundView: NSView {
        let bgView = objc_getAssociatedObject(self, &Keys.backgroundViewKey) as? NSView
        if let view = bgView {
            return view
        }

        let view = NSView()
        objc_setAssociatedObject(self, &Keys.backgroundViewKey, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        NotificationCenter.default.addObserver(self, selector: #selector(popoverWillOpen(_:)), name: NSPopover.willShowNotification, object: nil)
        return view
    }

    @objc private func popoverWillOpen(_ notification: Notification) {
        if backgroundView.superview == nil {
            if let contentView = contentViewController?.view, let frameView = contentView.superview {
                frameView.wantsLayer = true
                backgroundView.frame = NSInsetRect(frameView.frame, 1, 1)
                backgroundView.autoresizingMask = [.width, .height]
                frameView.addSubview(backgroundView, positioned: .below, relativeTo: contentView)
            }
        }
    }

    var backgroundColor: NSColor? {
        get {
            if let bgColor = backgroundView.layer?.backgroundColor {
                return NSColor(cgColor: bgColor)
            }
            return nil
        }
        set {
            backgroundView.wantsLayer = true
            backgroundView.layer?.backgroundColor = newValue?.cgColor
        }
    }
}
