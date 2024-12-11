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

        var errorDescription: String? {
            switch self {
            case .fetchFailed: return NSLocalizedString("Unable to Load Photos", comment: "Alert title")
            case .deleteFailed: return NSLocalizedString("Unable to Delete Photo", comment: "Alert title")
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .fetchFailed: return NSLocalizedString("Please try again. If the problem persists, restart the app.",
                                                        comment: "Alert recovery suggestion")
            case .deleteFailed: return NSLocalizedString("Please try again. If the problem persists, restart the app.",
                                                         comment: "Alert recovery suggestion")
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
