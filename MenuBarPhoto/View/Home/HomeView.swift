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

    @State private var isTargeted: Bool = false
    @State private var isHovering = false
    @State private var photos: [Photo]
    @State private var scrolledID: Photo.ID?

    let photoService = PhotoService()

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
        .overlay(DropOverLay(isTargeted: $isTargeted, photos: $photos))
        .animation(.default, value: isTargeted)
        .onDrop(of: [.image], isTargeted: $isTargeted) { providers in
            photoService.addDroppedPhoto(providers: providers, currentPhotoCount: photos.count) { newPhotos in
                self.photos = newPhotos
            }
        }
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
    @Binding var isTargeted: Bool
    @Binding var photos: [Photo]

    var body: some View {
        if isTargeted {
            if photos.count < 5 {
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
    HomeView(photos: [])
}
