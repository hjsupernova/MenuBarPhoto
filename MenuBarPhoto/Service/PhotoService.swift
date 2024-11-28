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

    init(ratingUtility: RatingUtility = RatingUtility()) {
        self.ratingUtility = ratingUtility
    }

    func addDroppedPhoto(providers: [NSItemProvider],
                         currentPhotoCount: Int,
                         completion: @escaping ([Photo]) -> Void) -> Bool {
        guard currentPhotoCount < 5 else { return false }
        guard let provider = providers.first else { return false }

        _ = provider.loadDataRepresentation(for: .image, completionHandler: { data, error in

            if error == nil, let data {
                CoreDataStack.shared.savePhoto(data)

                let newPhotos = CoreDataStack.shared.fetchPhotos()

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    completion(newPhotos)

                    self.ratingUtility.didPerformSignificantEvent()
                    self.ratingUtility.askForRatingIfNeeded()
                }
            }
        })
        return true
    }
}
