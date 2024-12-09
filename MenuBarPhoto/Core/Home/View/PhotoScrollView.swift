//
//  PhotoScrollView.swift
//  MenuBarPhoto
//
//  Created by KHJ on 11/1/24.
//

import SwiftUI

import Kingfisher

struct PhotoScrollView: View {
    @EnvironmentObject var homeVM: HomeViewModel

    @Binding var scrolledID: Photo.ID?
    @Binding var isHovering: Bool

    var body: some View {
        ZStack {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0.0) {
                    ForEach(homeVM.photos, id: \.self.id) { photo in
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

                            PhotoActionButtons(scrolledID: $scrolledID)
                        }

                        Spacer()

                        PageControl(scrolledID: $scrolledID)
                    }

                    PhotoMoveButton(scrolledID: $scrolledID)
                }
                .padding(8)
            }
        }
    }
}

struct PhotoActionButtons: View {
    @EnvironmentObject private var appDelegate: AppDelegate
    @EnvironmentObject var homeVM: HomeViewModel

    @Binding var scrolledID: Photo.ID?

    var body: some View {
        HStack {
            Button {
                guard let photo = homeVM.photos.first(where: { $0.id == scrolledID }) else { return }
                guard let image = photo.photoData?.toNSImage() else { return }

                let contentRootView = CropImageView(photo: photo,
                                                    photos: $homeVM.photos,
                                                    image: image,
                                                    targetSize: CGSize(width: 300, height: 300),
                                                    targetScale: 3,
                                                    fulfillTargetFrame: true)
                                                    .environmentObject(appDelegate)

                let contentView = NSHostingView(rootView: contentRootView)

                appDelegate.openCropWindow(contentView: contentView)
            } label: {
                Image(systemName: "scissors")
            }

            Button {
                homeVM.deleteCurrentPhoto(id: scrolledID)
            } label: {
                Image(systemName: "trash")
            }

            Button {
                appDelegate.openSettingsWindow()
            } label: {
                Image(systemName: "gearshape")
            }
        }
        .buttonStyle(ActionButtonStyle())

    }
}

struct PhotoMoveButton: View {
    @EnvironmentObject var homeVM: HomeViewModel

    @Binding var scrolledID: Photo.ID?

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
        .buttonStyle(MoveButtonStyle())
    }

    private var currentIndex: Int? {
        homeVM.photos.firstIndex(where: { $0.id == scrolledID })
    }

    private var canMoveToPrevious: Bool {
        guard let currentIndex = currentIndex else { return false }
        return currentIndex > 0
    }

    private var canMoveToNext: Bool {
        guard let currentIndex = currentIndex else { return false }
        return currentIndex < homeVM.photos.count - 1
    }

    private func moveToPreviousPhoto() {
        guard let currentIndex = currentIndex, currentIndex > 0 else { return }
        scrolledID = homeVM.photos[currentIndex - 1].id
    }

    private func moveToNextPhoto() {
        guard let currentIndex = currentIndex, currentIndex < homeVM.photos.count - 1 else { return }
        scrolledID = homeVM.photos[currentIndex + 1].id
    }
}

struct PageControl: View {
    @EnvironmentObject var homeVM: HomeViewModel

    @Binding var scrolledID: Photo.ID?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(homeVM.photos, id: \.self) { photo in
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
