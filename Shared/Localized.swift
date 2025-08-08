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
        String(format: NSLocalizedString("bier.label.count", comment: "Label showing total beer count"), count)
    }

    static func bierPerSecond(_ rate: Double) -> String {
        String(format: NSLocalizedString("bier.label.perSecond", comment: "Label showing production per second"), rate)
    }

    static func noEarningsTime(_ minutes: Int, _ seconds: Int) -> String {
        String(format: NSLocalizedString("bier.label.noEarnings", comment: "Offline time too short"), minutes, seconds)
    }

    static func offlineEarnings(_ timeAway: String, _ amount: Int) -> String {
        String(format: NSLocalizedString("bier.label.offlineEarnings", comment: "Message showing offline beer earnings"), timeAway, amount)
    }

    static func timeAwayText(_ minutes: Int) -> String {
        String(format: NSLocalizedString("bier.label.timeAwayMinutes", comment: "Used to display how long the user was away in minutes"), minutes)
    }

    // MARK: - Buttons

    static var shopOpen: String {
        NSLocalizedString("button.shop.open", comment: "Button title: open shop")
    }

    static var shopClose: String {
        NSLocalizedString("button.shop.close", comment: "Button title: close shop")
    }

    static var proost: String {
        NSLocalizedString("button.proost", comment: "Confirmation button in the offline alert")
    }

    static func shopBuy(_ price: Int) -> String {
        String(format: NSLocalizedString("shop.item.buy", comment: "Shop item buy button"), price)
    }

    // MARK: - Alerts

    static var welcomeBack: String {
        NSLocalizedString("alert.welcomeBack.title", comment: "Title of the offline earnings alert")
    }

    static var resetConfirmationTitle: String {
        NSLocalizedString("reset.confirm.title", comment: "Reset confirmation alert title")
    }

    static var resetConfirmationMessage: String {
        NSLocalizedString("reset.confirm.message", comment: "Reset confirmation alert message")
    }

    // MARK: - Settings

    static var settingsTitle: String {
        NSLocalizedString("settings.title", comment: "Settings title")
    }

    static var deviceTitle: String {
        NSLocalizedString("settings.device.title", comment: "Device info section title")
    }

    static func deviceType(_ name: String) -> String {
        String(format: NSLocalizedString("settings.device.type", comment: "Device info: type"), name)
    }

    static func deviceRings(_ count: Int, _ capacity: Int) -> String {
        String(format: NSLocalizedString("settings.device.rings", comment: "Device info: rings and capacity"), count, capacity)
    }

    static var appTitle: String {
        NSLocalizedString("settings.app.title", comment: "App info section title")
    }

    static func appVersion(_ version: String, _ build: String) -> String {
        String(format: NSLocalizedString("settings.app.version", comment: "App info: version string"), version, build)
    }

    static var developer: String {
        NSLocalizedString("settings.app.dev", comment: "App info: developer")
    }

    static var appDescription: String {
        NSLocalizedString("settings.app.desc", comment: "App info: description")
    }

    static var gameActionsTitle: String {
        NSLocalizedString("settings.actions.title", comment: "Game actions section title")
    }

    static var resetButton: String {
        NSLocalizedString("settings.actions.reset", comment: "Reset button title")
    }

    static var resetWarning: String {
        NSLocalizedString("settings.actions.warning", comment: "Reset warning")
    }

    static var credits: String {
        NSLocalizedString("settings.credits", comment: "Credits label")
    }

    // MARK: - Shop Items

    enum Shop {
        
        static let title = NSLocalizedString("shop.title", comment: "Title of the shop screen")
        
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

    // MARK: - Splash

    static var splashDisclaimer: String {
        NSLocalizedString("splash.disclaimer", comment: "Splash screen disclaimer")
    }
}
