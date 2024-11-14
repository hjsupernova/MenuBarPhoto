//
//  Styles.swift
//  MenuBarPhoto
//
//  Created by KHJ on 11/14/24.
//

import SwiftUI

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
