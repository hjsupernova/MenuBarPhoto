//
//  CropView.swift
//  MenuBarPhoto
//
//  Created by KHJ on 10/4/24.
//

import SwiftUI

import Kingfisher

struct CropWindow: View {
    var photo: Photo


    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            CropView(photo: photo)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background { Color.black.ignoresSafeArea() }

            VStack {
                HStack {
                    Spacer()

                    Button {
                        let renderer = ImageRenderer(content: CropView(photo: photo))
                        renderer.scale = 10

                        renderer.proposedSize = .init(CGSize(width: 300, height: 300))

                        if let data = renderer.nsImage?.pngData {
                            photo.croppedPhotoData = data

                            CoreDataStack.shared.save()
                        }

                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                }

                Spacer()
            }
        }
    }
}

struct CropView: View {
    let cropSize = CGSize(width: 300, height: 300)
    var photo: Photo

    // Gestures
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 0
    @State private var offset: CGSize = .zero
    @State private var lastSToredOffset: CGSize = .zero

    @GestureState private var isInteracting: Bool = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            if let image = photo.photoData {
                KFImage(source: .provider(RawImageDataProvider(data: image, cacheKey: photo.photoId?.uuidString ?? UUID().uuidString)))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay {
                        GeometryReader { geo in
                            let rect = geo.frame(in: .named("CROPVIEW"))
                            Color.clear
                                .onChange(of: isInteracting) { oldValue, newValue in

                                    if !newValue {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if rect.minX > 0 {
                                                offset.width = (offset.width - rect.minX)

                                            }

                                            if rect.minY > 0 {
                                                offset.height = (offset.height - rect.minY)

                                            }

                                            if rect.maxX < size.width {
                                                offset.width = (rect.minX - offset.width)

                                            }

                                            if rect.maxY < size.height {
                                                offset.height = (rect.minY - offset.height)

                                            }
                                        }

                                        lastSToredOffset = offset
                                    }
                                }
                        }
                    }
                    .frame(size)
            }
        }
        .scaleEffect(scale)
        .offset(offset)
        .coordinateSpace(name: "CROPVIEW")
        .gesture(
            DragGesture()
                .updating($isInteracting, body: { _, out, _ in
                    out = true
                })
                .onChanged { value in
                    let translation = value.translation
                    offset = CGSize(
                        width: translation.width + lastSToredOffset.width,
                        height: translation.height + lastSToredOffset.height
                    )
                }
        )
        .gesture(
            MagnifyGesture()
                .updating($isInteracting, body: { _, out, _ in
                    out = true
                })
                .onChanged({ value in
                    let updatedScale = value.magnification + lastScale
                    /// 스케일은 1 보다 작을 수 없다.
                    scale = (updatedScale < 1 ? 1 : updatedScale)
                })
                .onEnded({ value in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if scale < 1 {
                            scale = 1
                            lastScale = 0
                        } else {
                            lastScale = scale - 1
                        }
                    }
                })
        )
        .frame(cropSize)
    }
}
//#Preview {
//    CropWindow(photo: Photo()
//    .frame(width: 300, height: 300)
//}


