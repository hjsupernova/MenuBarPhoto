//
//  RatingUtility.swift
//  MenuBarPhoto
//
//  Created by KHJ on 11/10/24.
//

import Foundation
import StoreKit

import Defaults

class RatingUtility {
    var isDebuggingEnabled: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }

    var shouldAskForRating: Bool {
        guard !isDebuggingEnabled else { return true }
        guard let firstLaunchDate = Defaults[.firstOpenDate] else { return false }
        let timeSinceFirstLaunch = Date().timeIntervalSince(firstLaunchDate)
        let timeUntilRate: TimeInterval = 60 * 60 * 24 * 3

        return Defaults[.accessCount] >= 3
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

    func didPerformSignificantEvent() {
        Defaults[.ratingEventsCount] += 1
        logRating.debug("Rating event count increased to \(Defaults[.ratingEventsCount])")
    }
}
