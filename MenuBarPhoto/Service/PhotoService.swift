//
//  PhotoService.swift
//  MenuBarPhoto
//
//  Created by KHJ on 11/21/24.
//

import Foundation

import Defaults

class PhotoService {
    let ratingUtility: RatingUtility

    init(ratingUtility: RatingUtility) {
        self.ratingUtility = ratingUtility
    }

    func fetchPhotos() throws -> [Photo] {
        return try CoreDataStack.shared.fetchPhotos()
    }

    func deletePhoto(id: UUID) throws {
        try CoreDataStack.shared.deletePhoto(id: id)
    }

    func savePhoto(photo: Data) {
        CoreDataStack.shared.savePhoto(photo)
        ratingUtility.didPerformSignificantEvent()
    }
}
