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
    private var aboutWindow: NSWindow!
    private var settingsWindow: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        print(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path ?? "nil")

        if let statusButton = statusItem.button {
            statusButton.image = NSImage(systemSymbolName: "heart", accessibilityDescription: "photo")
            statusButton.action = #selector(togglePopover)
        }

        self.popover = NSPopover()
        self.popover.contentSize = NSSize(width: 300, height: 300)
        self.popover.behavior = .transient

        let savedPhotos = CoreDataStack.shared.fetchPhotos()
        let data = savedPhotos.compactMap { $0.imageData}
        self.popover.contentViewController = NSHostingController(rootView: ContentView(data: data))
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
                Defaults[.accessCount] += 1
            }
        }
    }

    func openImageWindow() {
        let contentView = ImageView()

        if imageWindow != nil {
            imageWindow.close()
        }

        imageWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
            styleMask: [.resizable, .titled, .closable],
            backing: .buffered,
            defer: false
        )

        imageWindow.contentView = NSHostingView(rootView: contentView)
        imageWindow.makeKeyAndOrderFront(nil)

        NSApplication.shared.activate()

        let controller = NSWindowController(window: imageWindow)
        controller.showWindow(self)

        imageWindow.center()
        imageWindow.orderFrontRegardless()
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

        NSApplication.shared.activate(ignoringOtherApps: true)

        let controller = NSWindowController(window: settingsWindow)
        controller.showWindow(self)

        settingsWindow.center()
        settingsWindow.orderFrontRegardless()
    }
}

struct ImageView: View {
    @State private var images: [Image] = []
    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack {
            if !images.isEmpty {
                GeometryReader { geometry in
                    ZStack {
                        ForEach(0..<images.count, id: \.self) { index in
                            images[index]
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .opacity(index == selectedIndex ? 1.0 : 0.0)
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                                .animation(.easeInOut, value: selectedIndex)
                        }
                        VStack {
                            Spacer()

                            HStack {
                                Spacer()
                                DotsIndicator(numberOfDots: images.count, selectedIndex: selectedIndex)
                                    .padding()
                            }
                        }
                    }
                    .gesture(DragGesture().onEnded { value in
                        if value.translation.width < -50 {
                            // Swipe left
                            withAnimation {
                                selectedIndex = (selectedIndex + 1) % images.count
                            }
                        } else if value.translation.width > 50 {
                            // Swipe right
                            withAnimation {
                                selectedIndex = (selectedIndex - 1 + images.count) % images.count
                            }
                        }
                    })
                }
            }
        }
        .frame(width: 300, height: 300)
        .windowLevel(.floating + 1)
        .onAppear {
            let savedPhotos = CoreDataStack.shared.fetchPhotos()
            let data = savedPhotos.compactMap { $0.imageData}

            for data in data {
                if let nsImage = NSImage(data: data) {
                    images.append(Image(nsImage: nsImage))
                }
            }
        }

    }
}
