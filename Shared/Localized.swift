//
//  Localized.swift
//  Tap the Cap
//
//  Created by Menno Spijker on 07/08/2025.
//

import Foundation

enum Localized {
    
    // MARK: - Labels
    
    static func bierCount(_ count: Int) -> String {
        String(format: NSLocalizedString("bier.label.count", comment: ""), count)
    }

    static func bierPerSecond(_ rate: Double) -> String {
        String(format: NSLocalizedString("bier.label.perSecond", comment: ""), rate)
    }

    static var noOfflineEarnings: String {
        NSLocalizedString("bier.label.noEarnings", comment: "")
    }

    static func offlineEarnings(_ timeAway: String, _ amount: Int) -> String {
        String(format: NSLocalizedString("bier.label.offlineEarnings", comment: ""), timeAway, amount)
    }

    static func offlineDuration(_ minutes: Int) -> String {
        String(format: NSLocalizedString("bier.label.minutesAway", comment: ""), minutes)
    }

    // MARK: - Buttons
    
    static var shopOpen: String {
        NSLocalizedString("button.shop.open", comment: "")
    }

    static var shopClose: String {
        NSLocalizedString("button.shop.close", comment: "")
    }

    static var proost: String {
        NSLocalizedString("button.proost", comment: "")
    }

    static var reset: String {
        NSLocalizedString("button.reset", comment: "")
    }

    static var cancel: String {
        NSLocalizedString("button.cancel", comment: "")
    }

    // MARK: - Alerts

    static var welcomeBack: String {
        NSLocalizedString("alert.welcomeBack.title", comment: "")
    }

    static var noEarningsTitle: String {
        NSLocalizedString("alert.noEarnings.title", comment: "")
    }

    static var resetTitle: String {
        NSLocalizedString("alert.reset.title", comment: "")
    }

    static var resetMessage: String {
        NSLocalizedString("alert.reset.message", comment: "")
    }

    static var resetConfirmationTitle: String {
        NSLocalizedString("alert.reset.confirm.title", comment: "")
    }

    static var resetConfirmationMessage: String {
        NSLocalizedString("alert.reset.confirm.message", comment: "")
    }

    // MARK: - Settings

    static var settingsTitle: String {
        NSLocalizedString("settings.title", comment: "")
    }

    static var deviceInfo: String {
        NSLocalizedString("settings.deviceInfo", comment: "")
    }

    static var appInfo: String {
        NSLocalizedString("settings.appInfo", comment: "")
    }

    static var gameActions: String {
        NSLocalizedString("settings.gameActions", comment: "")
    }

    static var resetWarning: String {
        NSLocalizedString("settings.resetWarning", comment: "")
    }

    static var credits: String {
        NSLocalizedString("settings.credits", comment: "")
    }

    // MARK: - Shop Items

    enum Shop {
        enum Item {
            enum bierfles {
                static let name = NSLocalizedString("shop.item.bierfles.name", comment: "Name of the beer bottle shop item")
                static let description = NSLocalizedString("shop.item.bierfles.description", comment: "Description of the beer bottle shop item")
            }
            enum bierkrat {
                static let name = NSLocalizedString("shop.item.bierkrat.name", comment: "Name of the beer crate shop item")
                static let description = NSLocalizedString("shop.item.bierkrat.description", comment: "Description of the beer crate shop item")
            }
            enum bierfust {
                static let name = NSLocalizedString("shop.item.bierfust.name", comment: "Name of the beer keg shop item")
                static let description = NSLocalizedString("shop.item.bierfust.description", comment: "Description of the beer keg shop item")
            }
        }
    }
    
    static func noEarningsTime(_ minutes: Int, _ seconds: Int) -> String {
        String(format: NSLocalizedString("bier.label.noEarnings", comment: ""), minutes, seconds)
    }
    
    static func timeAwayText(_ minutes: Int) -> String {
        String(format: NSLocalizedString("bier.label.timeAwayMinutes", comment: "Used to display how long the user was away in minutes"), minutes)
    }
    
    
}
