//
//  Image.swift
//  MenuBarPhoto
//
//  Created by KHJ on 11/14/24.
//

import AppKit

extension Data {
    func toNSImage() -> NSImage? {
        return NSImage(data: self)
    }

    var bitmap: NSBitmapImageRep? { NSBitmapImageRep(data: self) }
}

extension NSImage {
    var pngData: Data? { tiffRepresentation?.bitmap?.representation(using: .jpeg, properties: [:])}
}
