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
    @State private var scrolledID: Photo.ID?

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
        .onChange(of: photos) { oldValue, newValue in
            if newValue.count > oldValue.count {
                scrolledID = newValue.last?.id
            } else {
                let deletedPhoto = oldValue.first { !newValue.contains($0) }

                if let deletedIndex = oldValue.firstIndex(where: { $0.id == deletedPhoto?.id }) {
                    // If there are photos to the right, select the next one
                    if deletedIndex < newValue.count {
                        scrolledID = newValue[deletedIndex].id
                    } else if !newValue.isEmpty {
                        scrolledID = newValue.last?.id
                    } else {
                        scrolledID = nil
                    }
                }
            }
        }
        .onAppear {
            scrolledID = photos.first?.id
        }
        .environmentObject(appDelegate)
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
    @Binding var scrolledID: Photo.ID?
    @Binding var isHovering: Bool

    var body: some View {
        ZStack {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0.0) {
                    ForEach(photos, id: \.self.id) { photo in
                        if let data = photo.croppedPhotoData ?? photo.photoData {
                            KFImage(source: .provider(RawImageDataProvider(data: data, cacheKey: data.hashValue.description)))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 300, height: 300)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrolledID)
            .scrollTargetBehavior(.viewAligned)

            if isHovering {
                Group {
                    VStack {
                        HStack {
                            Spacer()

                            PhotoActionButtons(photos: $photos, scrolledID: $scrolledID)
                        }

                        Spacer()

                        PageControl(photos: $photos, scrolledID: $scrolledID)

                    }

                    PhotoMoveButton(scrolledID: $scrolledID, photos: $photos)
                }
                .padding(8)
            }
        }

        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct PhotoActionButtons: View {
    @EnvironmentObject private var appDelegate: AppDelegate
    @Binding var photos: [Photo]
    @Binding var scrolledID: Photo.ID?

    var body: some View {
        HStack {
            Button {
                guard let photo = photos.first(where: { $0.id == scrolledID }) else { return }
                guard let image = photo.photoData?.toNSImage() else { return }

                let contentRootView = CropImageView(image: image,
                                                    targetSize: CGSize(width: 300, height: 300),
                                                    targetScale: 10,
                                                    fulfillTargetFrame: true) { result in
                        switch result {
                        case .success(let image):
                            photo.croppedPhotoData = image.pngData

                            CoreDataStack.shared.save()

                            DispatchQueue.main.async {
                                photos = CoreDataStack.shared.fetchPhotos()
                            }
                        case .failure(let error):
                            print("Error: Cannot crop the image")
                        }

                }

                let contentView = NSHostingView(rootView: contentRootView)
                appDelegate.openCropWindow(contentView: contentView)
            } label: {
                Image(systemName: "scissors")
            }

            Button {
                guard let photo = photos.first(where: { $0.id == scrolledID }) else { return }

                CoreDataStack.shared.deletePhoto(id: photo.photoId)

                photos = CoreDataStack.shared.fetchPhotos()
            } label: {
                Image(systemName: "trash")
            }
        }
    }
}

struct PhotoMoveButton: View {
    @Binding var scrolledID: Photo.ID?
    @Binding var photos: [Photo]

    var body: some View {
        HStack {
            Button(action: moveToPreviousPhoto) {
                Image(systemName: "chevron.left.circle.fill")
            }
            .disabled(!canMoveToPrevious)

            Spacer()

            Button(action: moveToNextPhoto) {
                Image(systemName: "chevron.right.circle.fill")
            }
            .disabled(!canMoveToNext)
        }
    }

    private var currentIndex: Int? {
        photos.firstIndex(where: { $0.id == scrolledID })
    }

    private var canMoveToPrevious: Bool {
        guard let currentIndex = currentIndex else { return false }
        return currentIndex > 0
    }

    private var canMoveToNext: Bool {
        guard let currentIndex = currentIndex else { return false }
        return currentIndex < photos.count - 1
    }

    private func moveToPreviousPhoto() {
        guard let currentIndex = currentIndex, currentIndex > 0 else { return }
        scrolledID = photos[currentIndex - 1].id
    }

    private func moveToNextPhoto() {
        guard let currentIndex = currentIndex, currentIndex < photos.count - 1 else { return }
        scrolledID = photos[currentIndex + 1].id
    }
}

struct PageControl: View {
    @Binding var photos: [Photo]
    @Binding var scrolledID: Photo.ID?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(photos, id: \.self) { photo in
                Circle()
                    .fill(photo.id == scrolledID ? Color.blue : Color.gray)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct InstructionText: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.arrow.down")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("Drag & Drop your image")
                .font(.system(size: 15, weight: .regular))  // System default size for macOS
                .foregroundColor(.secondary)

        }
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
