//
//  ContentView.swift
//  MenuBarPhoto
//
//  Created by KHJ on 8/13/24.
//

import SwiftUI

struct ContentView: View {
    @State private var isTargeted: Bool = false
    @State private var images: [Image] = []
    @State private var selectedIndex: Int = 0

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var data: [Data] = []

    init(data: [Data] = []) {
        self.data = data
    }

    var body: some View {
        VStack {
            if !images.isEmpty {
                GeometryReader { geometry in
                    ZStack {
                        ForEach(0..<images.count, id: \.self) { index in
                            images[index]
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .opacity(index == selectedIndex ? 1.0 : 0.0)
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                                .animation(.easeInOut, value: selectedIndex)
                        }
                        VStack {
                            Spacer()

                            HStack {
                                Button {
                                    appDelegate.openImageWindow()
                                } label: {
                                    Image(systemName: "photo")
                                }

                                Spacer()

                                Button {
                                    appDelegate.openSettingsWindow()
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                }
                                DotsIndicator(numberOfDots: images.count, selectedIndex: selectedIndex)
                                    .padding()
                            }
                        }
                    }
                    .gesture(DragGesture().onEnded { value in
                        if value.translation.width < -50 {
                            // Swipe left
                            withAnimation {
                                selectedIndex = (selectedIndex + 1) % images.count
                            }
                        } else if value.translation.width > 50 {
                            // Swipe right
                            withAnimation {
                                selectedIndex = (selectedIndex - 1 + images.count) % images.count
                            }
                        }
                    })
                }
            } else {
                ZStack {
                    Image(systemName: "globe")
                        .resizable()
                        .scaledToFit()

                    VStack {
                        Spacer()

                        HStack {
                            Spacer()

                            Button {
                                appDelegate.openImageWindow()
                            } label: {
                                Image(systemName: "photo")
                            }
                        }
                    }
                }

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
        .onDrop(of: [.image], isTargeted: $isTargeted, perform: { providers in
            guard let provider = providers.first else { return false }

            _ = provider.loadDataRepresentation(for: .image, completionHandler: { data, error in
                if error == nil, let data {
                    CoreDataStack.shared.savePhoto(data)

                    DispatchQueue.main.async {
                        if let nsImage = NSImage(data: data) {
                            images.append(Image(nsImage: nsImage))
                        }
                    }
                }
            })
            return true
        })
        .onAppear {
            print("onAppear called ")
            for data in data {
                if let nsImage = NSImage(data: data) {
                    images.append(Image(nsImage: nsImage))
                }
            }
        }
    }
}

// #Preview {
//    ContentView()
// }
struct DotsIndicator: View {
    let numberOfDots: Int
    let selectedIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfDots, id: \.self) { index in
                Circle()
                    .fill(index == selectedIndex ? Color.black : Color.gray)
                    .frame(width: 8, height: 8)
            }
        }
    }
}
