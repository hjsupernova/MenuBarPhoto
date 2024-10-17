//
//  HomeView.swift
//  MenuBarPhoto
//
//  Created by KHJ on 8/13/24.
//

import SwiftUI

struct HomeView: View {
    @State private var isTargeted: Bool = false
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var photos: [Photo]
    @State private var isHovering = false
    @State private var scrolledID: Int?

    init(photos: [Photo]) {
        self._photos = State(initialValue: photos)
    }
    var body: some View {
        VStack {
            if !photos.isEmpty {
                GeometryReader { geo in
                        ZStack {
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

                                                        Spacer()
                                                    }
                                                }
                                            }
                                            .id(index)
                                        }
                                    }
                                })
                                .scrollTargetLayout()
                            }
                            .scrollPosition(id: $scrolledID)
                            .scrollTargetBehavior(.viewAligned)

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
            } else {
                Text("Drag your image here")
                    .frame(width: 300, height: 300)
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

#Preview {
//    HomeView(photos: CoreDataStack.shared.samplePhotos)
    HomeView(photos: [])
}
