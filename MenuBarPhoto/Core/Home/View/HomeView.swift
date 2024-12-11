//
//  HomeView.swift
//  MenuBarPhoto
//
//  Created by KHJ on 8/13/24.
//

import SwiftUI

import Defaults
import Kingfisher

struct HomeView: View {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var homeVM = HomeViewModel(photoService: PhotoService(ratingUtility: RatingUtility()))

    @State private var isTargeted: Bool = false
    @State private var isHovering = false
    @State private var scrolledID: Photo.ID?

    var body: some View {
        Group {
            if !homeVM.photos.isEmpty {
                PhotoScrollView(scrolledID: $scrolledID, isHovering: $isHovering)
            } else {
                InstructionText()
            }
        }
        .overlay(DropOverLay(isTargeted: $isTargeted))
        .animation(.default, value: isTargeted)
        .onDrop(of: [.image], isTargeted: $isTargeted) { providers in
            guard homeVM.photos.count < 5 else { return false }
            guard let provider = providers.first else { return false }

            _ = provider.loadDataRepresentation(for: .image, completionHandler: { data, error in

                if error == nil, let data {
                    DispatchQueue.main.async {
                        homeVM.saveDroppedPhoto(photoData: data)
                    }
                } else {
                    // error or no data / handle needed
                }
            })
            return true
        }
        .onChange(of: homeVM.photos, updateScrollPosition)
        .onHover { hovering in
            isHovering = hovering
        }
        .onAppear {
            scrolledID = homeVM.photos.first?.id
        }
        .errorAlert(error: $homeVM.error)
        .environmentObject(homeVM)
        .environmentObject(appDelegate)
    }

    private func updateScrollPosition(oldPhotos: [Photo], newPhotos: [Photo]) {
        if newPhotos.count > oldPhotos.count {
            scrolledID = newPhotos.last?.id
        } else {
            let deletedPhoto = oldPhotos.first { !newPhotos.contains($0) }

            if let deletedIndex = oldPhotos.firstIndex(where: { $0.id == deletedPhoto?.id }) {
                // If there are photos to the right, select the next one
                if deletedIndex < newPhotos.count {
                    scrolledID = newPhotos[deletedIndex].id
                } else if !newPhotos.isEmpty {
                    scrolledID = newPhotos.last?.id
                } else {
                    scrolledID = nil
                }
            }
        }

    }
}

struct InstructionText: View {
    @EnvironmentObject private var appDelegate: AppDelegate

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()

                    Button {
                        appDelegate.openSettingsWindow()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(ActionButtonStyle())
                }
                Spacer()
            }
            .padding(8)

            VStack(spacing: 12) {
                Image(systemName: "photo.badge.arrow.down")
                    .font(.system(size: 32))
                    .foregroundColor(.gray)

                Text("Drag & Drop your image")
                    .font(.system(size: 15, weight: .regular))  // System default size for macOS
                    .foregroundColor(.gray)

            }
        }
        .frame(width: 300, height: 300)
    }
}

struct DropOverLay: View {
    @EnvironmentObject var homeVM: HomeViewModel

    @Binding var isTargeted: Bool

    var body: some View {
        if isTargeted {
            if homeVM.photos.count < 5 {
                ZStack {
                    Color.black.opacity(0.7)

                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                        Text("Drop your image here")
                    }
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 250)
                    .multilineTextAlignment(.center)
                }
            } else {
                ZStack {
                    Color.black.opacity(0.7)

                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)

                        Text("Image limit reached")
                            .font(.title)
                            .fontWeight(.heavy)

                        Text("(Maximum 5 images)")
                            .font(.title2)
                            .fontWeight(.medium)
                            .opacity(0.8)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: 250)
                    .multilineTextAlignment(.center)
                }
            }

        }
    }
}

#Preview {
    HomeView()
}
