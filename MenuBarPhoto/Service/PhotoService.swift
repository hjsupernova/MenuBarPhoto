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

    func fetchPhotos() -> [Photo] {
        CoreDataStack.shared.fetchPhotos()
    }

    func savePhoto(photo: Data) {
        CoreDataStack.shared.savePhoto(photo)
        ratingUtility.didPerformSignificantEvent()
        ratingUtility.askForRatingIfNeeded()
    }
}
