//
//  HomeViewModel.swift
//  MenuBarPhoto
//
//  Created by KHJ on 12/9/24.
//

import Foundation

class HomeViewModel: ObservableObject {
    enum PhotoError: LocalizedError {
        case fetchFailed
        case deleteFailed

        // TODO: 현지화
        var errorDescription: String? {
            switch self {
            case .fetchFailed: return "Unable to Load Photos"
            case .deleteFailed: return "Unable to Delete Photo"
            }
        }

        // TODO: 현지화
        var recoverySuggestion: String? {
            switch self {
            case .fetchFailed: return "Please try again. If the problem persists, restart the app."
            case .deleteFailed: return "Please try deleting the photo again. If this keeps happening, restart the app."
            }
        }
    }

    @Published var photos: [Photo] = []
    @Published var error: Swift.Error?

    private let photoService: PhotoService

    init(photoService: PhotoService) {
        self.photoService = photoService
        self.reloadPhotos()
    }

    func saveDroppedPhoto(photoData: Data) {
        photoService.savePhoto(photo: photoData)
        logPhoto.debug("Photo: Save new photo")
        reloadPhotos()
    }

    func deleteCurrentPhoto(id: Photo.ID?) {
        guard let photo = photos.first(where: { photo in photo.id == id }),
              let id = photo.photoId else {
            self.error = PhotoError.deleteFailed
            return
        }

        do {
            try photoService.deletePhoto(id: id)
            logPhoto.debug("Photo: Delete one photo")
            reloadPhotos()
        } catch {
            self.error = PhotoError.deleteFailed
            logPhoto.error("Photo: Failed to delete photo")
        }
    }

    func reloadPhotos() {
        do {
            photos = try photoService.fetchPhotos()
            logPhoto.debug("Photo: Fetch saved photos")
        } catch {
            self.error = PhotoError.fetchFailed
            logPhoto.error("Photo: Failed to fetch photos")
        }
    }
}
