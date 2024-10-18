//
//  HomeView.swift
//  MenuBarPhoto
//
//  Created by KHJ on 8/13/24.
//

import SwiftUI

import Kingfisher

struct HomeView: View {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var isTargeted: Bool = false
    @State private var isHovering = false
    @State private var photos: [Photo]
    @State private var scrolledID: Int?

    init(photos: [Photo]) {
        self._photos = State(initialValue: photos)
    }

    var body: some View {
        Group {
            if !photos.isEmpty {
                PhotoScrollView(photos: $photos, scrolledID: $scrolledID, isHovering: $isHovering)
            } else {
                InstructionText()
            }
        }
        .overlay(DropOverLay(isTargeted: $isTargeted))
        .animation(.default, value: isTargeted)
        .onDrop(of: [.image], isTargeted: $isTargeted, perform: addDroppedPhoto)
    }

    private func addDroppedPhoto(providers: [NSItemProvider]) -> Bool {
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

// MARK: - SubViews

struct PhotoScrollView: View {
    @Binding var photos: [Photo]
    @Binding var scrolledID: Int?
    @Binding var isHovering: Bool
    @State private var hoveredPhoto: Photo?

    var body: some View {
        GeometryReader { geo in
                ZStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 0.0) {
                            ForEach(Array(photos.enumerated()), id: \.element.photoId) { index, photo in
                                if let data = photo.photoData {
                                    ZStack {
                                        KFImage(source: .provider(RawImageDataProvider(data: data, cacheKey: photo.photoId?.uuidString ?? index.description)))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: geo.size.width, height: geo.size.height)
                                            .onHover { hovering in
                                                hoveredPhoto = hovering ? photo : nil
                                            }
                                    }
                                    .id(index)
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollPosition(id: $scrolledID)
                    .scrollTargetBehavior(.viewAligned)
                    
                    if let hoveredPhoto, isHovering {
                        VStack {
                            HStack {
                                Spacer()

                                PhotoActionButtons(photos: $photos, photo: hoveredPhoto)
                            }

                            Spacer()
                        }
                    }

                    if isHovering {
                        VStack {
                            Spacer()

                            PageControl(numberOfPages: photos.count, currentPage: $scrolledID)
                                .padding()
                        }
                    }
                }
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct PhotoActionButtons: View {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Binding var photos: [Photo]
    let photo: Photo

    var body: some View {
        HStack {
            Button {
                appDelegate.openCropWindow(photo: photo)
            } label: {
                Image(systemName: "scissors")
            }

            Button {
                CoreDataStack.shared.deletePhoto(id: photo.photoId)
                photos = CoreDataStack.shared.fetchPhotos()
            } label: {
                Image(systemName: "trash")
            }

            Button {
                appDelegate.openSettingsWindow()
            } label: {
                Image(systemName: "gear.circle")

            }
        }
    }
}

struct PageControl: View {
    let numberOfPages: Int
    @Binding var currentPage: Int?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { page in
                Circle()
                    .fill(page == (currentPage ?? 0) ? Color.blue : Color.gray)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct InstructionText: View {
    var body: some View {
        Text("Drag your image here")
            .frame(width: 300, height: 300)
    }
}

struct DropOverLay: View {
    @Binding var isTargeted: Bool

    var body: some View {
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
}

#Preview {
    HomeView(photos: [])
}
