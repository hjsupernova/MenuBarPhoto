//
//  DefaultControlsView.swift
//
//
//  Created by Shibo Lyu on 2023/8/10.
//

import SwiftUI

/// The default controls view used when creating ``CropImageView`` using ``CropImageView/init(image:targetSize:targetScale:fulfillTargetFrame:onCrop:)``.
///
/// It provides basic controls to crop, reset to default cropping & rotation, and rotate the image.
public struct DefaultControlsView: View {
    @Binding var offset: CGSize
    @Binding var scale: CGFloat
    @Binding var rotation: Angle
    var crop: () async -> Void

    @State private var isRotating = false

    var rotateButton: some View {
        Button {
            let roundedAngle = Angle.degrees((rotation.degrees / 90).rounded() * 90)
            withAnimation(.interactiveSpring()) {
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
        #if !os(visionOS)
        .buttonStyle(.plain)
        #endif
        .padding()
        .disabled(isRotating)
        .onChange(of: rotation) { _ in
            isRotating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isRotating = false
            }
        }
    }

    var resetButton: some View {
        Button("Reset") {
            withAnimation {
                offset = .zero
                scale = 1
                rotation = .zero
            }
        }
    }

    var cropButton: some View {
        Button { Task {
            await crop()
        } } label: {
            Image(systemName: "checkmark")
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 28, height: 28)
                .background(
                    Circle().fill(.white)
//                    RoundedRectangle(cornerRadius: 5, style: .continuous)
//                        .fill(.white)
                )
        }
        #if !os(visionOS)
        .buttonStyle(.plain)
        #endif
        .padding()
    }

    public var body: some View {
        VStack {
            Spacer()
            HStack {
                rotateButton
//                Spacer()
//                if #available(iOS 15.0, macOS 13.0, *) {
//                    resetButton
//                        .buttonStyle(.bordered)
//                        .buttonBorderShape(.roundedRectangle)
//                } else {
//                    resetButton
//                }
                Spacer()
                cropButton
            }
        }
    }
}
