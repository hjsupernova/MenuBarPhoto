//
//  HomeViewModel.swift
//  MenuBarPhoto
//
//  Created by KHJ on 12/9/24.
//

import Foundation

class HomeViewModel: ObservableObject {
    @Published var photos: [Photo]

    private let photoService: PhotoService

    init(photoService: PhotoService) {
        self.photoService = photoService
        photos = photoService.fetchPhotos()
    }

    func saveDroppedPhoto(photoData: Data) {
        photoService.savePhoto(photo: photoData)
        reloadPhotos()
    }

    func deleteCurrentPhoto(id: Photo.ID?) {
        guard let photo = photos.first(where: { photo in
            photo.id == id
        }) else { return }

        CoreDataStack.shared.deletePhoto(id: photo.photoId)

        reloadPhotos()
    }

    func reloadPhotos() {
        photos = photoService.fetchPhotos()
    }
}
