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
                GeometryReader { geo in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 0.0, content: {
                            ForEach(0..<images.count, id: \.self) { index in
                                images[index]
                                    .resizable()
                                    .frame(width: geo.size.width, height: geo.size.height)
                            }
                        })
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                }
            } else {
                ZStack {
                    Image(systemName: "globe")
                        .resizable()
                        .scaledToFit()
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
