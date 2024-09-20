//
//  ContentView.swift
//  MenuBarPhoto
//
//  Created by KHJ on 8/13/24.
//

import SwiftUI

extension Data {

    func toNSImage() -> NSImage? {
        return NSImage(data: self)
    }

    func toSwiftUIImage() -> Image? {
        guard let nsImage = self.toNSImage() else { return nil }
        return Image(nsImage: nsImage)
    }
}

struct ContentView: View {
    @State private var isTargeted: Bool = false
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var photos: [Photo] = []
    @State private var isHovering = false

    init(photos: [Photo]) {
        self.photos = photos
    }
    var body: some View {
        VStack {
            if !photos.isEmpty {
                GeometryReader { geo in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 0.0, content: {
                                ForEach(Array(photos.enumerated()), id: \.element.photoId) { index, photo in
                                    if let image = photo.photoData?.toSwiftUIImage() {
                                        ZStack {
                                            image
                                                .resizable()
                                                .frame(width: geo.size.width, height: geo.size.height)
      
                                            if isHovering {
                                                VStack {
                                                    HStack {
                                                        Spacer()

                                                        Button {
                                                            CoreDataStack.shared.deletePhoto(id: photo.photoId)
                                                            photos = CoreDataStack.shared.fetchPhotos()
                                                        } label: {
                                                            Image(systemName: "trash")
                                                                .foregroundColor(.red)
                                                                .padding()
                                                        }
                                                    }

                                                    Spacer()
                                                }
                                            }
                                        }
                                    }
                                }
                            })
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.viewAligned)

                }
                .onHover { hovering in
                    isHovering = hovering
                }
            } else {
                ZStack {
                    Image(systemName: "globe")
                        .resizable()
                        .scaledToFit()
                }
            }
        }
        .overlay {
            if isTargeted {
                ZStack {
                    Color.black.opacity(0.7)

                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                        Text("Drop your image here")
                    }
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 250)
                    .multilineTextAlignment(.center)
                }
            }
        }
        .animation(.default, value: isTargeted)
        .onDrop(of: [.image], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }

            _ = provider.loadDataRepresentation(for: .image, completionHandler: { data, error in
                if error == nil, let data {
                    CoreDataStack.shared.savePhoto(data)
                    
                    let newPhotos = CoreDataStack.shared.fetchPhotos()

                    DispatchQueue.main.async {
                        photos = newPhotos
                    }
                }
            })
            return true
        }
    }
}

// #Preview {
//    ContentView()
// }
struct DotsIndicator: View {
    let numberOfDots: Int
    let selectedIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfDots, id: \.self) { index in
                Circle()
                    .fill(index == selectedIndex ? Color.black : Color.gray)
                    .frame(width: 8, height: 8)
            }
        }
    }
}
