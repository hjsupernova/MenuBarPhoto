//
//  CropImageView.swift
//
//
//  Created by Shibo Lyu on 2023/7/21.
//

import SwiftUI


struct CropImageView: View {
    enum CropError: LocalizedError {
        /// SwiftUI `ImageRenderer` returned nil when calling `nsImage` or `uiImage`.
        ///
        /// See [SwiftUI - ImageRenderer](https://developer.apple.com/documentation/swiftui/imagerenderer) for more information.
        case imageRendererReturnedNil

        var errorDescription: String? {
            switch self {
            case .imageRendererReturnedNil: NSLocalizedString("Unable to Crop Image", comment: "Alert title")
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .imageRendererReturnedNil: NSLocalizedString("Please try again with a different image format.",
                                                              comment: "Alert recovery suggestion ")
            }
        }
    }

    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1
    @State private var rotation: Angle = .zero
    @State private var error: Error?

    let viewSize: CGSize = .init(width: 400, height: 400)
    let photo: Photo
    @Binding var photos: [Photo]
    @EnvironmentObject private var appDelegate: AppDelegate
    @Environment(\.dismiss) var dismiss

    public var image: NSImage
    public var targetSize: CGSize
    public var targetScale: CGFloat = 3
    public var fulfillTargetFrame: Bool = true

    public init(
        photo: Photo,
        photos: Binding<[Photo]>,
        image: NSImage,
        targetSize: CGSize,
        targetScale: CGFloat = 3,
        fulfillTargetFrame: Bool = true
    ) {
        self.photo = photo
        self._photos = photos
        self.image = image
        self.targetSize = targetSize
        self.targetScale = targetScale
    }

    var body: some View {
        ZStack {
            UnderlyingImageView(
                offset: $offset, scale: $scale,
                rotation: $rotation,
                image: image,
                viewSize: viewSize,
                targetSize: targetSize, fulfillTargetFrame: fulfillTargetFrame
            )

            CutHoleView(targetSize: targetSize)

            ControlView(rotation: $rotation, viewSize: viewSize) {
                do {
                    let image = try crop()
                    photo.croppedPhotoData = image.pngData

                    DispatchQueue.global().async {
                        CoreDataStack.shared.save()
                    }

                    // TODO: PhotoService를 사용해야함. or ViewModel
                    photos = try CoreDataStack.shared.fetchPhotos()

                    dismiss()
                } catch {
                    // TODO: Error handled needed
                    self.error = CropError.imageRendererReturnedNil
                    dismiss()
                }
            }
        }
        .frame(width: viewSize.width, height: viewSize.height)
        .errorAlert(error: $error)
    }

    @MainActor
    func crop() throws -> NSImage {
        let snapshotView = UnderlyingImageView(
            offset: $offset,
            scale: $scale,
            rotation: $rotation,
            image: image,
            viewSize: viewSize,
            targetSize: targetSize,
            fulfillTargetFrame: fulfillTargetFrame
        )
        .frame(width: targetSize.width, height: targetSize.height)
        .environmentObject(appDelegate)

        let renderer = ImageRenderer(content: snapshotView)
        renderer.scale = targetScale

        if let image = renderer.nsImage {
            return image
        } else {
            throw CropError.imageRendererReturnedNil
        }
    }
}


// MARK: - CutHole

struct CutHoleView: View {
    var targetSize: CGSize
    var strokeWidth: CGFloat = 1

    var strokeShape: some View {
        Rectangle()
            .strokeBorder(style: .init(lineWidth: 1))
    }

    var stroke: some View {
        strokeShape
            .frame(
                width: targetSize.width + strokeWidth * 2 ,
                height: targetSize.height + strokeWidth * 2
            )
            .foregroundStyle(.white)
    }

    var body: some View {
        CutHoleShape(size: targetSize)
            .fill(style: FillStyle(eoFill: true))
            .foregroundStyle(.black.opacity(0.6))
            .allowsHitTesting(false)
            .overlay(strokeWidth > 0 ? stroke : nil)
    }
}

struct CutHoleShape: Shape {
    var size: CGSize

    func path(in rect: CGRect) -> Path {
        let path = CGMutablePath()
        path.move(to: rect.origin)
        path.addLine(to: .init(x: rect.maxX, y: rect.minY))
        path.addLine(to: .init(x: rect.maxX, y: rect.maxY))
        path.addLine(to: .init(x: rect.minX, y: rect.maxY))
        path.addLine(to: rect.origin)
        path.closeSubpath()


        let newRect = CGRect(origin: .init(
            x: rect.midX - size.width / 2.0,
            y: rect.midY - size.height / 2.0
        ), size: size)

        // Draw the inner rectangle
        path.move(to: newRect.origin)

        path.addLine(to: .init(x: newRect.maxX, y: newRect.minY))
        path.addLine(to: .init(x: newRect.maxX, y: newRect.maxY))
        path.addLine(to: .init(x: newRect.minX, y: newRect.maxY))
        path.addLine(to: newRect.origin)
        path.closeSubpath()

        return Path(path)
    }
}

// MARK: - Controls

struct ControlView: View {
    @Binding var rotation: Angle
    let viewSize: CGSize
    var crop: () -> Void

    var body: some View {
        VStack {
            Spacer()

            HStack {
                rotationButton

                Spacer()

                cropButton
            }
        }
        .frame(width: viewSize.width, height: viewSize.height)
    }

    var rotationButton: some View {
        Button {
            let roundedAngle = Angle.degrees(
                (rotation.degrees / 90).rounded() * 90
            )

            withAnimation(.interactiveSpring) {
                rotation = roundedAngle + .degrees(90)
            }

        } label: {
            Image(systemName: "rotate.right")
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(.white)
                )
        }
        .buttonStyle(.plain)
        .padding()
    }

    var cropButton: some View {
        Button {
            crop()
        } label: {
            Image(systemName: "checkmark")
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 28, height: 28)
                .background(
                    Circle().fill(.white)
                )
        }
        .buttonStyle(.plain)
        .padding()

    }
}
