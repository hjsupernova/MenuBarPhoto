//
//  RatingService.swift
//  MenuBarPhoto
//
//  Created by KHJ on 11/10/24.
//

import Foundation
import StoreKit

import Defaults

class RatingService {
    var shouldAskForRating: Bool {
        guard let firstLaunchDate = Defaults[.firstOpenDate] else { return false }
        let timeSinceFirstLaunch = Date().timeIntervalSince(firstLaunchDate)
        let timeUntilRate: TimeInterval = 60 * 60 * 24 * 5

        return Defaults[.accessCount] >= 7
        && Defaults[.ratingEventsCount] >= 2
        && timeSinceFirstLaunch >= timeUntilRate
        && Defaults[.lastVersionPromptedForReview] != applicationVersionProvider()
    }

    func askForRatingIfNeeded() {
        guard shouldAskForRating else { return }
        askForRating()
    }

    func askForRating() {
        Defaults[.lastVersionPromptedForReview] = applicationVersionProvider()

        SKStoreReviewController.requestReview()
    }

    func applicationVersionProvider() -> String {
        return Bundle.main.appVersion
    }
}
