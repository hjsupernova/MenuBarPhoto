//
//  Utilities.swift
//  MenuBarPhoto
//
//  Created by KHJ on 8/14/24.
//

import SwiftUI

// MARK: - Error alerts
extension View {
    func errorAlert(error: Binding<Error?>, buttonTitle: String = "OK") -> some View {
        let localizedError = LocalizedAlertError(error: error.wrappedValue)

        return alert(isPresented: .constant(localizedError != nil), error: localizedError) { _ in
            Button(buttonTitle) {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }

    }
}

struct LocalizedAlertError: LocalizedError {
    let underlyingError: LocalizedError
    var errorDescription: String? {
        underlyingError.errorDescription
    }
    var recoverySuggestion: String? {
        underlyingError.recoverySuggestion
    }

    /// if the error is not localized, it returns nil
    init?(error: Error?) {
        guard let localizedError = error as? LocalizedError else { return nil }
        underlyingError = localizedError
    }
}

// MARK: - Window Level
extension View {
    func accessHostingWindow(_ onWindow: @escaping (NSWindow?) -> Void) -> some View {
        modifier(WindowViewModifier(onWindow: onWindow))
    }

    func windowLevel(_ level: NSWindow.Level) -> some View {
        accessHostingWindow {
            $0?.level = level
        }
    }
}

private struct WindowViewModifier: ViewModifier {
    @State private var window: NSWindow?

    let onWindow: (NSWindow?) -> Void

    func body(content: Content) -> some View {
        onWindow(window)

        return content
            .bindHostingWindow($window)
    }
}

extension View {
    func bindHostingWindow(_ window: Binding<NSWindow?>) -> some View {
        background(WindowAccessor(window))
    }
}

private struct WindowAccessor: NSViewRepresentable {
    private final class WindowAccessorView: NSView {
        @Binding var windowBinding: NSWindow?

        init(binding: Binding<NSWindow?>) {
            self._windowBinding = binding
            super.init(frame: .zero)
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            windowBinding = window
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError() // swiftlint:disable:this fatal_error_message
        }
    }

    @Binding var window: NSWindow?

    init(_ window: Binding<NSWindow?>) {
        self._window = window
    }

    func makeNSView(context: Context) -> NSView {
        WindowAccessorView(binding: $window)
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

}

extension View {
    @ViewBuilder
    func frame(_ size: CGSize) -> some View {
        self
            .frame(width: size.width, height: size.height)
    }
}
