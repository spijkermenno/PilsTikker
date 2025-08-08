//
//  GameViewController+Progress.swift
//  Tap the Cap iOS
//
//  Created by Menno Spijker on 07/08/2025.
//

import UIKit

extension GameViewController {

    func loadProgress() {
        let defaults = UserDefaults.standard
        bierCount = defaults.double(forKey: keyBierCount)

        for i in 0..<shopItems.count {
            let count = defaults.integer(forKey: "shopItem_\(shopItems[i].id)_count")
            shopItems[i].count = count
        }

        if let lastSaveTime = defaults.object(forKey: keyLastSaveTime) as? Date {
            let elapsedSeconds = Date().timeIntervalSince(lastSaveTime)
            let maxOfflineSeconds = maxOfflineMinutes * 60.0
            let totalProduction = getTotalProductionRate()

            if elapsedSeconds >= 0 && totalProduction > 0 {
                let cappedSeconds = min(elapsedSeconds, maxOfflineSeconds)
                let offlineProduction = totalProduction * cappedSeconds
                bierCount += offlineProduction

                if offlineProduction >= 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        let timeAwayMinutes = elapsedSeconds / 60.0
                        self.showOfflineEarnings(amount: offlineProduction, timeAway: timeAwayMinutes)
                    }
                }
            }
        }
    }

    @objc func saveProgress() {
        let defaults = UserDefaults.standard
        defaults.set(bierCount, forKey: keyBierCount)

        for item in shopItems {
            defaults.set(item.count, forKey: "shopItem_\(item.id)_count")
        }

        defaults.set(Date(), forKey: keyLastSaveTime)
    }

    func setupAutosave() {
        Timer.scheduledTimer(
            timeInterval: 30.0,
            target: self,
            selector: #selector(saveProgress),
            userInfo: nil,
            repeats: true
        )
    }

    private func showOfflineEarnings(amount: Double, timeAway: Double) {
        let threshold: Double = 30.0 // minutes

        guard timeAway > threshold else {
            let totalSeconds = Int(timeAway * 60)
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            print(Localized.noEarningsTime(minutes, seconds))
            return
        }

        let effectiveTime = timeAway - threshold
        let productionPerMinute = amount / timeAway
        let earnedBier = productionPerMinute * effectiveTime * 0.10

        let timeAwayText = Localized.timeAwayText(Int(timeAway))
        let _ = Localized.welcomeBack
        let message = Localized.offlineEarnings(timeAwayText, Int(earnedBier))

        showShopNotification(message: message)

        bierCount += earnedBier
    }
}
