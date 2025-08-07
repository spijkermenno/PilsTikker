//
//  GameViewController.swift
//  Tap The Cap
//
//  Created by Menno Spijker on 07/08/2025.
//

import UIKit

public final class GameViewController: UIViewController {

    // MARK: - Game State

    var bierCount: Double = 0
    var clickCount: Int = 0
    var isShopOpen: Bool = false
    var isSettingsOpen: Bool = false

    // MARK: - UI Elements

    var imageView: UIImageView!
    var bierCountLabel: UILabel!
    var perSecondLabel: UILabel!
    var shopButton: UIButton!
    var shopView: UIView!
    var settingsButton: UIButton!
    var settingsView: UIView!
    var floatingItemViews: [UIImageView] = []

    // MARK: - Shop

    var shopItems: [ShopItem] = [
        ShopItem(
            id: "bierfles",
            name: Localized.Shop.Item.bierfles.name,
            imageName: "bierfles",
            description: Localized.Shop.Item.bierfles.description,
            basePrice: 12,
            productionRate: 0.1
        ),
        ShopItem(
            id: "bierkrat",
            name: Localized.Shop.Item.bierkrat.name,
            imageName: "bierkrat",
            description: Localized.Shop.Item.bierkrat.description,
            basePrice: 24,
            productionRate: 0.3
        ),
        ShopItem(
            id: "bierfust",
            name: Localized.Shop.Item.bierfust.name,
            imageName: "bierfust",
            description: Localized.Shop.Item.bierfust.description,
            basePrice: 120,
            productionRate: 1.0
        )
    ]

    // MARK: - Animation & Timers

    var gameTimer: Timer?
    var itemAnimationTimer: Timer?
    var bounceTimer: Timer?
    var speedBoostTimer: Timer?

    // MARK: - Animation State

    var itemAngle: Double = 0.0
    var itemRotationAngle: Double = 0.0
    var itemRotationOffsets: [Double] = []
    var floatingItemOrder: [String] = []

    var baseRotationSpeed: Double = 0.01
    var currentRotationSpeed: Double = 0.01
    var itemRotationSpeed: Double = -0.00290

    var baseRadius: Double = 110
    var currentRadius: Double = 110
    var bierdopCenterY: CGFloat = 0
    
    // MARK: - Bounce State

    var bouncePhase: Double = 0.0

    // MARK: - Device Configuration

    var deviceConfig: DeviceConfiguration!
    var ringCapacities: [Int] = []

    // MARK: - Constants

    let keyBierCount = "bierCount"
    let keyLastSaveTime = "lastSaveTime"
    let maxOfflineMinutes: Double = 30.0

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        deviceConfig = getDeviceConfiguration()
        setupRingCapacities()
        view.backgroundColor = UIColor(red: 0.76, green: 0.65, blue: 0.48, alpha: 1.0)

        loadProgress()
        setupUI()
        setupFloatingItemsAnimation()
        setupShopUI()
        setupSettingsUI()
        setupTimer()
        setupBounceAnimation()
        setupAutosave()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveProgress),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    deinit {
        gameTimer?.invalidate()
        itemAnimationTimer?.invalidate()
        bounceTimer?.invalidate()
        speedBoostTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}
