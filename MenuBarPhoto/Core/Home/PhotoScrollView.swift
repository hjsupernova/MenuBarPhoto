//
//  PhotoScrollView.swift
//  MenuBarPhoto
//
//  Created by KHJ on 11/1/24.
//

import SwiftUI

import Kingfisher

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
                                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 900, height: 900)))
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 300, height: 300)
                                .clipped()
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

struct ActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .frame(width: 16, height: 16)
            .padding(4)
            .background { Color.black.opacity(0.3) }
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct MoveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .frame(width: 16, height: 16)
            .padding(4)
            .background { Color.black.opacity(0.3) }
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .opacity(!isEnabled ? 0.0 : configuration.isPressed ? 0.8 : 1.0)
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

                let contentRootView = CropImageView(photo: photo,
                                                    photos: $photos,
                                                    image: image,
                                                    targetSize: CGSize(width: 300, height: 300),
                                                    targetScale: 3,
                                                    fulfillTargetFrame: true).environmentObject(appDelegate)

                let contentView = NSHostingView(rootView: contentRootView)

                appDelegate.openCropWindow(contentView: contentView)
            } label: {
                Image(systemName: "scissors")
            }
            .buttonStyle(ActionButtonStyle())

            Button {
                guard let photo = photos.first(where: { $0.id == scrolledID }) else { return }

                CoreDataStack.shared.deletePhoto(id: photo.photoId)

                photos = CoreDataStack.shared.fetchPhotos()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(ActionButtonStyle())

            Button {
                appDelegate.openSettingsWindow()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(ActionButtonStyle())

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
            .buttonStyle(MoveButtonStyle())
            .disabled(!canMoveToPrevious)

            Spacer()

            Button(action: moveToNextPhoto) {
                Image(systemName: "chevron.right.circle.fill")
            }
            .buttonStyle(MoveButtonStyle())
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
                    .fill(photo.id == scrolledID ? Color("bunny-yello") : Color.gray)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

//#Preview {
//    PhotoScrollView()
//}
