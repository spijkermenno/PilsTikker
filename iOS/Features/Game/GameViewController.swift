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

    // MARK: - Containers & Backgrounds

    var headerContainer: UIView!
    var contentContainer: UIView!
    var headerBackgroundView: UIImageView!
    var contentBackgroundView: UIImageView!
    var fullBackgroundView: UIImageView!   // ⬅️ added

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

    // MARK: - Background Config

    enum BackgroundStyle {
        case split(header: String, content: String) // two images
        case full(image: String)                    // one image fills entire view
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        deviceConfig = getDeviceConfiguration()
        setupRingCapacities()

        // Choose what you want at runtime:
        // setupContainers(style: .full(image: "background"))
        setupContainers(style: .full(image: "background"))

        loadProgress()
        setupUI()           // places labels in header, clicker in content
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

// MARK: - Containers

private extension GameViewController {
    func setupContainers(style: BackgroundStyle) {
        view.backgroundColor = .black

        // Always create containers; background style only affects which imageViews we add.
        headerContainer = UIView()
        contentContainer = UIView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        // If full background: add it behind both containers
        switch style {
        case .full(let imageName):
            fullBackgroundView = UIImageView(image: UIImage(named: imageName))
            fullBackgroundView.contentMode = .scaleAspectFill
            fullBackgroundView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(fullBackgroundView)
            NSLayoutConstraint.activate([
                fullBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
                fullBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                fullBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                fullBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])

        case .split:
            fullBackgroundView = nil
        }

        view.addSubview(headerContainer)
        view.addSubview(contentContainer)

        let headerHeight: CGFloat = 140 * deviceConfig.bierdopScale

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerContainer.heightAnchor.constraint(equalToConstant: headerHeight),

            contentContainer.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Add backgrounds according to style
        switch style {
        case .split(let headerImage, let contentImage):
            headerBackgroundView = UIImageView(image: UIImage(named: headerImage))
            headerBackgroundView.contentMode = .scaleAspectFill
            headerBackgroundView.translatesAutoresizingMaskIntoConstraints = false
            headerContainer.addSubview(headerBackgroundView)

            contentBackgroundView = UIImageView(image: UIImage(named: contentImage))
            contentBackgroundView.contentMode = .scaleAspectFill
            contentBackgroundView.translatesAutoresizingMaskIntoConstraints = false
            contentContainer.addSubview(contentBackgroundView)

            NSLayoutConstraint.activate([
                headerBackgroundView.topAnchor.constraint(equalTo: headerContainer.topAnchor),
                headerBackgroundView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
                headerBackgroundView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
                headerBackgroundView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),

                contentBackgroundView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
                contentBackgroundView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
                contentBackgroundView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
                contentBackgroundView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            ])

        case .full:
            headerBackgroundView = nil
            contentBackgroundView = nil
        }

        // Ensure layout so contentContainer.bounds is valid early
        view.layoutIfNeeded()
    }
}
