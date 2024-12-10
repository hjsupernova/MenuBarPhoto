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

    func applicationDidBecomeActive(_ notification: Notification) {
        checkFirstOpen()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        setuptKeyboardShortcuts()
    }

    // MARK: - Setup Functions

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let statusButton = statusItem.button else { return }

        let icon = NSImage(named: "bunny-svg")
        icon?.size = NSSize(width: 24, height: 24)
        icon?.isTemplate = true
        statusButton.image = icon
        statusButton.action = #selector(handleClick(_:))
        statusButton.target = self
        statusButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 300)
        popover.behavior = .semitransient
        popover.animates = false

        let hostingController = NSHostingController(rootView: HomeView())
        popover.backgroundColor = .white
        popover.contentViewController = hostingController
    }

    private func setuptKeyboardShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .togglePopover) {
            self.togglePopover()
        }
    }

    private func checkFirstOpen() {
        if Defaults[.firstOpenDate] == nil {
            Defaults[.firstOpenDate] = Date()
        }
    }

    // MARK: - Window Management

    @objc
    func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)

            Defaults[.accessCount] += 1
        }
    }

    @objc
    func openSettingsWindow() {
        let contentView = SettingsView()

        if settingsWindow != nil {
            settingsWindow.close()
        }

        settingsWindow = SwiftUIWindow(
            contentRect: NSRect(x: 0, y: 0, width: 0, height: 0),
            styleMask: [.closable, .titled],
            backing: .buffered,
            defer: false
        )

        settingsWindow.title = NSLocalizedString("Settings", comment: "Settings window title")
        settingsWindow.contentView = NSHostingView(rootView: contentView)
        settingsWindow.makeKeyAndOrderFront(nil)
        settingsWindow.styleMask.remove(.resizable)

        let controller = NSWindowController(window: settingsWindow)
        controller.showWindow(self)
        settingsWindow.center()
        settingsWindow.orderFrontRegardless()
    }

    func openCropWindow(contentView: NSView) {
        if cropWindow != nil {
            cropWindow.close()
        }

        setupScrollEventMonitor()

        cropWindow = SwiftUIWindow(
            contentRect: NSRect(x: 0, y: 0, width: 0, height: 0),
            styleMask: [.closable, .titled],
            backing: .buffered,
            defer: false
        )

        cropWindow.title = NSLocalizedString("Move & Scale", comment: "Edit window title")
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

    private func setupScrollEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel, handler: { event in
            self.scrollEvent = event

            return event
        })
    }

    // MARK: - Menu Actions

    @objc func handleClick(_ sender: NSButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else {
            togglePopover()
        }
    }

    func showMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: NSLocalizedString("Toggle Bunny", comment: "toggle button on right click"),
                                action: #selector(togglePopover),
                                keyEquivalent: ""))

        menu.addItem(NSMenuItem(title: NSLocalizedString("Settings...", comment: "settings button on right click"),
                                action: #selector(openSettingsWindow),
                                keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: NSLocalizedString("Quit Bunny", comment: "quit button on right click"),
                                action: #selector(quit),
                                keyEquivalent: ""))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(popoverWillOpen(_:)),
                                               name: NSPopover.willShowNotification,
                                               object: nil)
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

/// Enable Command + W to close the window
class SwiftUIWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            if event.charactersIgnoringModifiers == "w" {
                performClose(self)
            }
        }
        super.keyDown(with: event)
    }
}
