import UIKit

class GameViewController_: UIViewController {
    // Afbeelding en click zone
    private var imageView: UIImageView!
    private var bierCount: Double = 0
    private var bierCountLabel: UILabel!
    private var perSecondLabel: UILabel!
    
    // Shop items - NEW: Data-driven approach
    private var shopItems: [ShopItem] = [
        ShopItem(id: "bierfles", name: "Bierfles", imageName: "bierfles",
                description: "Produceert 0.1 bier/sec", basePrice: 12, productionRate: 0.1),
        ShopItem(id: "bierkrat", name: "Bierkrat", imageName: "bierkrat",
                description: "Produceert 0.3 bier/sec", basePrice: 24, productionRate: 0.3),
        ShopItem(id: "bierfust", name: "Bierfust", imageName: "bierfust",
                description: "Produceert 1.0 bier/sec", basePrice: 120, productionRate: 1.0)
    ]
    
    // Shop UI elements
    private var shopButton: UIButton!
    private var shopView: UIView!
    private var isShopOpen: Bool = false
    
    // Settings UI elements
    private var settingsButton: UIButton!
    private var settingsView: UIView!
    private var isSettingsOpen: Bool = false
    
    // Timer voor passieve inkomsten
    private var gameTimer: Timer?
    
    // Floating items animation
    private var floatingItemViews: [UIImageView] = []
    private var itemAnimationTimer: Timer?
    private var itemAngle: Double = 0.0
    private var itemRotationAngle: Double = 0.0
    private var itemRotationOffsets: [Double] = []
    private var floatingItemOrder: [String] = []
    
    // Constants for UserDefaults keys
    private let keyBierCount = "bierCount"
    private let keyLastSaveTime = "lastSaveTime"
    
    // spinning animation
    private var baseRotationSpeed: Double = 0.01
    private var currentRotationSpeed: Double = 0.01
    private var itemRotationSpeed: Double = -0.00290
    private var speedBoostTimer: Timer?
    private var clickCount: Int = 0
    
    private var baseRadius: Double = 110
    private var currentRadius: Double = 110
    
    // Subtle bounce animation properties
    private var bierdopCenterY: CGFloat = 0
    private var bounceTimer: Timer?
    private var bouncePhase: Double = 0.0
    
    // Offline earnings constants
    private let maxOfflineMinutes: Double = 30.0
    
    // Device-specific configuration
    private var deviceConfig: DeviceConfiguration!
    private var ringCapacities: [Int] = [] // Capacities for each ring
    
    // Dynamic ring properties (replace the fixed ones)
    private func getTotalMaxFloatingItems() -> Int {
        return ringCapacities.reduce(0, +)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get device configuration first
        deviceConfig = getDeviceConfiguration()
        setupRingCapacities()
        
        print("Device detected: \(deviceConfig.deviceType)")
        print("Max rings: \(deviceConfig.maxRings)")
        print("Ring capacities: \(ringCapacities)")
        
        // Set a simple background color
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
    
    private func setupRingCapacities() {
        ringCapacities = []
        
        // Start with base capacity for inner ring
        let baseCapacity = 12
        
        for ringIndex in 0..<deviceConfig.maxRings {
            let capacity: Int
            
            if ringIndex == 0 {
                // Inner ring always has base capacity
                capacity = baseCapacity
            } else {
                // Each subsequent ring has 154% capacity of the previous ring
                let previousCapacity = ringCapacities[ringIndex - 1]
                capacity = Int(Double(previousCapacity) * 1.54)
            }
            
            ringCapacities.append(capacity)
        }
        
        print("Ring capacities calculated: \(ringCapacities)")
    }
    
    // MARK: - Progress Saving & Loading
    
    private func loadProgress() {
        let defaults = UserDefaults.standard
        bierCount = defaults.double(forKey: keyBierCount)
        
        // Load each shop item count dynamically
        for i in 0..<shopItems.count {
            let count = defaults.integer(forKey: "shopItem_\(shopItems[i].id)_count")
            shopItems[i].count = count
        }
        
        // Calculate offline progress with 30-minute limit
        if let lastSaveTime = defaults.object(forKey: keyLastSaveTime) as? Date {
            let elapsedSeconds = Date().timeIntervalSince(lastSaveTime)
            let maxOfflineSeconds = maxOfflineMinutes * 60.0
            
            let totalProduction = getTotalProductionRate()
            
            // Only calculate offline earnings if elapsed time is positive and within the limit
            if elapsedSeconds >= maxOfflineSeconds && totalProduction > 0 {
                // Add offline production (capped at 30 minutes)
                let offlineProduction = totalProduction * elapsedSeconds
                bierCount += offlineProduction
                
                // Show offline earnings when significant
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
        
        // Save each shop item count dynamically
        for item in shopItems {
            defaults.set(item.count, forKey: "shopItem_\(item.id)_count")
        }
        
        defaults.set(Date(), forKey: keyLastSaveTime)
    }
    
    private func setupAutosave() {
        Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(saveProgress), userInfo: nil, repeats: true)
    }
    
    private func showOfflineEarnings(amount: Double, timeAway: Double) {
        let timeAwayText: String
        if timeAway < 1.0 {
            timeAwayText = "minder dan een minuut"
        } else if timeAway >= maxOfflineMinutes {
            timeAwayText = "\(Int(maxOfflineMinutes)) minuten (maximum)"
        } else {
            timeAwayText = "\(Int(timeAway)) minuten"
        }
        
        let alertController = UIAlertController(
            title: "Welkom terug!",
            message: "Je was \(timeAwayText) weg en je producten hebben \(String(format: "%.1f", amount)) bier geproduceerd!",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Proost! 🍻", style: .default))
        present(alertController, animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func getTotalProductionRate() -> Double {
        return shopItems.reduce(0) { total, item in
            return total + (Double(item.count) * item.productionRate)
        }
    }
    
    private func getTotalItemCount() -> Int {
        return shopItems.reduce(0) { total, item in
            return total + item.count
        }
    }
    
    // MARK: - Bounce Animation Setup
    
    private func setupBounceAnimation() {
        bounceTimer = Timer.scheduledTimer(timeInterval: 0.016, target: self, selector: #selector(updateBounceAnimation), userInfo: nil, repeats: true)
    }
    
    @objc private func updateBounceAnimation() {
        bouncePhase += 0.04
        
        let bounceHeight: CGFloat = 5.0
        let bounceOffset = sin(bouncePhase) * bounceHeight
        
        var center = imageView.center
        center.y = bierdopCenterY - bounceOffset
        imageView.center = center
    }
    
    // MARK: - Floating Items Animation Setup
    
    private let maxItemsInnerRing = 12
    private let maxItemsOuterRing = 18
    private func getMaxFloatingItems() -> Int { maxItemsInnerRing + maxItemsOuterRing }
    
    private func setupFloatingItemsAnimation() {
        let totalCapacity = getTotalMaxFloatingItems()
        
        for i in 0..<totalCapacity {
            let itemImageView = UIImageView()
            itemImageView.contentMode = .scaleAspectFit
            
            // Scale item size based on device
            let itemSize = 35 * deviceConfig.bierdopScale
            itemImageView.frame = CGRect(x: 0, y: 0, width: itemSize, height: itemSize)
            itemImageView.isHidden = true
            itemImageView.tag = i
            view.addSubview(itemImageView)
            floatingItemViews.append(itemImageView)
            
            let randomOffset = Double.random(in: 0...(5 * Double.pi))
            itemRotationOffsets.append(randomOffset)
        }
        
        itemAnimationTimer = Timer.scheduledTimer(timeInterval: 0.016, target: self, selector: #selector(updateFloatingItemPositions), userInfo: nil, repeats: true)
        
        updateFloatingItemsVisibility()
    }
    
    private func updateFloatingItemsVisibility() {
        let totalItems = getTotalItemCount()
        
        if totalItems == 0 {
            for itemView in floatingItemViews {
                itemView.isHidden = true
            }
            floatingItemOrder = []
            return
        }
        
        let totalFloatingItems = min(totalItems, getTotalMaxFloatingItems())
        
        // Create array of item types to show based on proportional distribution
        var itemsToShow: [String] = []
        
        for item in shopItems {
            if item.count > 0 {
                // Calculate how many slots this item type should get
                let idealSlots = Double(item.count) / Double(totalItems) * Double(totalFloatingItems)
                let actualSlots = min(item.count, max(1, Int(round(idealSlots))))
                
                for _ in 0..<actualSlots {
                    itemsToShow.append(item.imageName)
                }
            }
        }
        
        // Ensure we don't exceed the limit
        if itemsToShow.count > totalFloatingItems {
            itemsToShow = Array(itemsToShow.prefix(totalFloatingItems))
        }
        
        // Shuffle for randomization
        itemsToShow.shuffle()
        floatingItemOrder = itemsToShow
        
        // Apply to floating views
        for i in 0..<min(floatingItemOrder.count, floatingItemViews.count) {
            floatingItemViews[i].image = UIImage(named: floatingItemOrder[i])
            floatingItemViews[i].isHidden = false
        }
        
        // Hide remaining views
        for i in floatingItemOrder.count..<floatingItemViews.count {
            floatingItemViews[i].isHidden = true
        }
        
        regenerateRotationOffsetsForVisibleItems()
    }
    
    private func regenerateRotationOffsetsForVisibleItems() {
        for i in 0..<min(floatingItemOrder.count, floatingItemViews.count) {
            if !floatingItemViews[i].isHidden {
                itemRotationOffsets[i] = Double.random(in: 0...(2 * Double.pi))
            }
        }
    }
    
    @objc private func updateFloatingItemPositions() {
        let visibleItemsCount = floatingItemOrder.count
        
        if visibleItemsCount > 0 {
            itemAngle += currentRotationSpeed
            itemRotationAngle += itemRotationSpeed
            
            var itemIndex = 0
            
            // Position items in each ring
            for ringIndex in 0..<deviceConfig.maxRings {
                let ringRadius = CGFloat(deviceConfig.baseRadius + (Double(ringIndex) * 60.0))
                let ringCapacity = ringCapacities[ringIndex]
                
                // Calculate how many items should be in this ring
                let remainingItems = visibleItemsCount - itemIndex
                let itemsInThisRing = min(remainingItems, ringCapacity)
                
                if itemsInThisRing <= 0 { break }
                
                // Position items in this ring
                for i in 0..<itemsInThisRing {
                    let itemView = floatingItemViews[itemIndex + i]
                    
                    if !itemView.isHidden {
                        let angleOffset = (Double(i) * 2.0 * Double.pi) / Double(itemsInThisRing)
                        // Each ring rotates at slightly different speed for visual variety
                        let ringSpeedMultiplier = 1.0 + (Double(ringIndex) * 0.1)
                        let currentAngle = (itemAngle * ringSpeedMultiplier) + angleOffset
                        
                        let centerX = view.center.x
                        let centerY = bierdopCenterY
                        
                        let x = centerX + ringRadius * cos(currentAngle)
                        let y = centerY + ringRadius * sin(currentAngle)
                        
                        itemView.center = CGPoint(x: x, y: y)
                        
                        let individualRotation = itemRotationAngle + itemRotationOffsets[itemIndex + i]
                        itemView.transform = CGAffineTransform(rotationAngle: CGFloat(individualRotation))
                    }
                }
                
                itemIndex += itemsInThisRing
            }
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Bierdop with device-specific scaling
        let bierDopImage = UIImage(named: "bierdop")
        imageView = UIImageView(image: bierDopImage)
        imageView.contentMode = .scaleAspectFit
        
        let bierdopSize = 150 * deviceConfig.bierdopScale
        imageView.frame = CGRect(x: 0, y: 0, width: bierdopSize, height: bierdopSize)
        imageView.center = view.center
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)
        
        // Update base radius from device config
        baseRadius = deviceConfig.baseRadius
        currentRadius = baseRadius
        
        bierdopCenterY = imageView.center.y
        
        // Labels (scale font size on larger devices)
        let labelFontScale = deviceConfig.bierdopScale
        
        bierCountLabel = UILabel(frame: CGRect(x: 0, y: 60, width: view.bounds.width, height: 40))
        bierCountLabel.textAlignment = .center
        bierCountLabel.textColor = .brown
        bierCountLabel.font = UIFont.boldSystemFont(ofSize: 24 * labelFontScale)
        bierCountLabel.text = "Bier: 0"
        view.addSubview(bierCountLabel)
        
        perSecondLabel = UILabel(frame: CGRect(x: 0, y: 100, width: view.bounds.width, height: 30))
        perSecondLabel.textAlignment = .center
        perSecondLabel.textColor = .brown
        perSecondLabel.font = UIFont.systemFont(ofSize: 16 * labelFontScale)
        perSecondLabel.text = "0.0 bier/sec"
        view.addSubview(perSecondLabel)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        imageView.addGestureRecognizer(tapGesture)
        
        updateUI()
    }
    
    // MARK: - Shop UI Setup
    
    private func setupShopUI() {
        let buttonSize: CGFloat = 60 * deviceConfig.shopScale
        let padding: CGFloat = 20
        
        shopButton = UIButton(type: .system)
        shopButton.frame = CGRect(
            x: view.bounds.width - buttonSize - padding,
            y: view.bounds.height - buttonSize - padding,
            width: buttonSize,
            height: buttonSize
        )
        shopButton.backgroundColor = .brown
        shopButton.layer.cornerRadius = buttonSize / 2
        shopButton.setImage(UIImage(systemName: "cart"), for: .normal)
        shopButton.tintColor = .white
        shopButton.addTarget(self, action: #selector(toggleShop), for: .touchUpInside)
        view.addSubview(shopButton)
        
        // Scale shop view based on device
        let shopWidth = 250 * deviceConfig.shopScale
        let shopHeight = 400 * deviceConfig.shopScale
        
        shopView = UIView(frame: CGRect(
            x: shopButton.center.x - 25,
            y: shopButton.center.y - 25,
            width: 50,
            height: 50
        ))
        shopView.backgroundColor = UIColor(white: 0.95, alpha: 0.95)
        shopView.layer.cornerRadius = 25
        shopView.layer.shadowColor = UIColor.black.cgColor
        shopView.layer.shadowOffset = CGSize(width: 0, height: -3)
        shopView.layer.shadowOpacity = 0.3
        shopView.layer.shadowRadius = 5
        shopView.clipsToBounds = true
        shopView.alpha = 0
        view.addSubview(shopView)
        
        // Add shop header with scaled font
        let headerFontSize = 18 * deviceConfig.shopScale
        let shopHeader = UILabel(frame: CGRect(x: 0, y: 10, width: shopWidth, height: 30 * deviceConfig.shopScale))
        shopHeader.text = "Winkel"
        shopHeader.font = UIFont.boldSystemFont(ofSize: headerFontSize)
        shopHeader.textAlignment = .center
        shopView.addSubview(shopHeader)
        
        // Add divider
        let divider = UIView(frame: CGRect(x: 15 * deviceConfig.shopScale, y: 45, width: shopWidth - 30, height: 1))
        divider.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        shopView.addSubview(divider)
        
        // Create shop items dynamically
        for (index, item) in shopItems.enumerated() {
            createShopItem(
                image: UIImage(named: item.imageName),
                title: item.name,
                description: item.description,
                price: item.basePrice,
                tag: index + 1,
                position: index
            )
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func createShopItem(image: UIImage?, title: String, description: String, price: Int, tag: Int, position: Int) {
        let itemHeight: CGFloat = 80
        let padding: CGFloat = 10
        let yPosition: CGFloat = 50 + CGFloat(position) * (itemHeight + padding)
        
        let itemView = UIView(frame: CGRect(x: 10, y: yPosition, width: 230, height: itemHeight))
        itemView.backgroundColor = UIColor.white
        itemView.layer.cornerRadius = 10
        itemView.tag = tag
        shopView.addSubview(itemView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(shopItemTapped(_:)))
        itemView.addGestureRecognizer(tapGesture)
        itemView.isUserInteractionEnabled = true
        
        let imageView = UIImageView(frame: CGRect(x: 10, y: 10, width: itemHeight - 20, height: itemHeight - 20))
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        itemView.addSubview(imageView)
        
        let titleLabel = UILabel(frame: CGRect(x: itemHeight, y: 10, width: itemView.bounds.width - itemHeight - 10, height: 20))
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.tag = 100 + tag
        itemView.addSubview(titleLabel)
        
        let descLabel = UILabel(frame: CGRect(x: itemHeight, y: 30, width: itemView.bounds.width - itemHeight - 10, height: 20))
        descLabel.text = description
        descLabel.font = UIFont.systemFont(ofSize: 12)
        descLabel.textColor = .darkGray
        itemView.addSubview(descLabel)
        
        let priceLabel = UILabel(frame: CGRect(x: itemHeight, y: 50, width: itemView.bounds.width - itemHeight - 10, height: 20))
        priceLabel.text = "\(price) bier 🍺"
        priceLabel.font = UIFont.systemFont(ofSize: 14)
        priceLabel.textColor = .brown
        itemView.addSubview(priceLabel)
        
        itemView.accessibilityValue = "\(price)"
    }
    
    private func updateShopItems() {
        for (index, item) in shopItems.enumerated() {
            let tag = index + 1
            guard let itemView = shopView.viewWithTag(tag) else { continue }
            guard let priceString = itemView.accessibilityValue,
                  let price = Int(priceString) else { continue }
            
            let canAfford = bierCount >= Double(price)
            itemView.alpha = canAfford ? 1.0 : 0.6
            
            // Update the title label to show count
            if let titleLabel = itemView.viewWithTag(100 + tag) as? UILabel {
                if item.count > 0 {
                    titleLabel.text = "\(item.name) (\(item.count))"
                } else {
                    titleLabel.text = item.name
                }
            }
        }
    }
    
    // MARK: - Settings UI Setup
    
    private func setupSettingsUI() {
        let buttonSize: CGFloat = 40
        let padding: CGFloat = 20
        
        settingsButton = UIButton(type: .system)
        settingsButton.frame = CGRect(
            x: view.bounds.width - buttonSize - padding,
            y: padding + 40,
            width: buttonSize,
            height: buttonSize
        )
        settingsButton.backgroundColor = UIColor.brown.withAlphaComponent(0.8)
        settingsButton.layer.cornerRadius = buttonSize / 2
        settingsButton.setImage(UIImage(systemName: "gear"), for: .normal)
        settingsButton.tintColor = .white
        settingsButton.addTarget(self, action: #selector(toggleSettings), for: .touchUpInside)
        view.addSubview(settingsButton)
        
        settingsView = UIView(frame: view.bounds)
        settingsView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        settingsView.alpha = 0
        settingsView.isHidden = true
        view.addSubview(settingsView)
        
        setupSettingsContent()
    }
    
    private func setupSettingsContent() {
        // Settings container
        let containerView = UIView()
        containerView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        containerView.layer.cornerRadius = 20
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 5)
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowRadius = 10
        containerView.translatesAutoresizingMaskIntoConstraints = false
        settingsView.addSubview(containerView)
        
        // Center the container
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: settingsView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: settingsView.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerView.heightAnchor.constraint(equalToConstant: 500)
        ])
        
        // Close button
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .gray
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(toggleSettings), for: .touchUpInside)
        containerView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Settings title
        let titleLabel = UILabel()
        titleLabel.text = "Instellingen"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
        
        // Divider
        let divider = UIView()
        divider.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        divider.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(divider)
        
        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            divider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // Device info section
        let deviceInfoLabel = UILabel()
        deviceInfoLabel.text = "Apparaat Informatie"
        deviceInfoLabel.font = UIFont.boldSystemFont(ofSize: 18)
        deviceInfoLabel.textColor = .brown
        deviceInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(deviceInfoLabel)
        
        NSLayoutConstraint.activate([
            deviceInfoLabel.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 20),
            deviceInfoLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20)
        ])
        
        // Device type
        let deviceTypeLabel = UILabel()
        deviceTypeLabel.text = "Apparaat: \(deviceConfig.deviceType)"
        deviceTypeLabel.font = UIFont.systemFont(ofSize: 14)
        deviceTypeLabel.textColor = .darkGray
        deviceTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(deviceTypeLabel)
        
        NSLayoutConstraint.activate([
            deviceTypeLabel.topAnchor.constraint(equalTo: deviceInfoLabel.bottomAnchor, constant: 10),
            deviceTypeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20)
        ])
        
        // Rings info
        let ringsInfoLabel = UILabel()
        ringsInfoLabel.text = "Ringen: \(deviceConfig.maxRings) (capaciteit: \(getTotalMaxFloatingItems()))"
        ringsInfoLabel.font = UIFont.systemFont(ofSize: 14)
        ringsInfoLabel.textColor = .darkGray
        ringsInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(ringsInfoLabel)
        
        NSLayoutConstraint.activate([
            ringsInfoLabel.topAnchor.constraint(equalTo: deviceTypeLabel.bottomAnchor, constant: 5),
            ringsInfoLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20)
        ])
        
        // App info section
        let appInfoLabel = UILabel()
        appInfoLabel.text = "App Informatie"
        appInfoLabel.font = UIFont.boldSystemFont(ofSize: 18)
        appInfoLabel.textColor = .brown
        appInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(appInfoLabel)
        
        NSLayoutConstraint.activate([
            appInfoLabel.topAnchor.constraint(equalTo: ringsInfoLabel.bottomAnchor, constant: 20),
            appInfoLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20)
        ])
        
        // App version
        let versionLabel = UILabel()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        versionLabel.text = "Versie: \(appVersion) (\(buildNumber))"
        versionLabel.font = UIFont.systemFont(ofSize: 14)
        versionLabel.textColor = .darkGray
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(versionLabel)
        
        NSLayoutConstraint.activate([
            versionLabel.topAnchor.constraint(equalTo: appInfoLabel.bottomAnchor, constant: 10),
            versionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20)
        ])
        
        // Developer info
        let developerLabel = UILabel()
        developerLabel.text = "Ontwikkelaar: Pepper Technologies"
        developerLabel.font = UIFont.systemFont(ofSize: 14)
        developerLabel.textColor = .darkGray
        developerLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(developerLabel)
        
        NSLayoutConstraint.activate([
            developerLabel.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 5),
            developerLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20)
        ])
        
        // App description
        let descriptionLabel = UILabel()
        descriptionLabel.text = "BierClicker - Het ultieme bier verzamel spel! Klik, verzamel en bouw je bier imperium op."
        descriptionLabel.font = UIFont.systemFont(ofSize: 12)
        descriptionLabel.textColor = .gray
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: developerLabel.bottomAnchor, constant: 15),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
        
        // Game section divider
        let gameDivider = UIView()
        gameDivider.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        gameDivider.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(gameDivider)
        
        NSLayoutConstraint.activate([
            gameDivider.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            gameDivider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            gameDivider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            gameDivider.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // Game actions section
        let gameActionsLabel = UILabel()
        gameActionsLabel.text = "Spel Acties"
        gameActionsLabel.font = UIFont.boldSystemFont(ofSize: 18)
        gameActionsLabel.textColor = .brown
        gameActionsLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(gameActionsLabel)
        
        NSLayoutConstraint.activate([
            gameActionsLabel.topAnchor.constraint(equalTo: gameDivider.bottomAnchor, constant: 20),
            gameActionsLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20)
        ])
        
        // Reset game button
        let resetButton = UIButton(type: .system)
        resetButton.setTitle("🔄 Spel Resetten", for: .normal)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.backgroundColor = .red
        resetButton.layer.cornerRadius = 8
        resetButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.addTarget(self, action: #selector(resetGameFromSettings), for: .touchUpInside)
        containerView.addSubview(resetButton)
        
        NSLayoutConstraint.activate([
            resetButton.topAnchor.constraint(equalTo: gameActionsLabel.bottomAnchor, constant: 15),
            resetButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            resetButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            resetButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Warning text
        let warningLabel = UILabel()
        warningLabel.text = "⚠️ Dit wist alle voortgang permanent!"
        warningLabel.font = UIFont.systemFont(ofSize: 12)
        warningLabel.textColor = .red
        warningLabel.textAlignment = .center
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(warningLabel)
        
        NSLayoutConstraint.activate([
            warningLabel.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: 5),
            warningLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            warningLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
        
        // Credits section
        let creditsLabel = UILabel()
        creditsLabel.text = "Met dank aan alle bierliefhebbers! 🍻\n\n© 2025 Pepper Technologies\nAlle rechten voorbehouden"
        creditsLabel.font = UIFont.systemFont(ofSize: 12)
        creditsLabel.textColor = .gray
        creditsLabel.textAlignment = .center
        creditsLabel.numberOfLines = 0
        creditsLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(creditsLabel)
        
        NSLayoutConstraint.activate([
            creditsLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            creditsLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            creditsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Game Mechanics
    
    private func setupTimer() {
        gameTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateGame), userInfo: nil, repeats: true)
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        bierCount += 1
        updateUI()
        
        increaseRotationSpeed()
        
        imageView.layer.removeAllAnimations()
        imageView.transform = CGAffineTransform.identity
        
        UIView.animate(withDuration: 0.01, animations: {
            self.imageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }, completion: { _ in
            UIView.animate(withDuration: 0.01) {
                self.imageView.transform = CGAffineTransform.identity
            }
        })
    }
    
    // MARK: - Rotation Speed Boost
    private func increaseRotationSpeed() {
        let maxClickCount = Int(10.0 / 0.5)
        clickCount = min(clickCount + 1, maxClickCount)
        
        currentRotationSpeed = min(baseRotationSpeed * (1.0 + Double(clickCount) * 0.5), baseRotationSpeed * 10.0)
        currentRadius = min(baseRadius * (1.0 + Double(clickCount) * 0.025), baseRadius * 10.0)
        
        speedBoostTimer?.invalidate()
        
        speedBoostTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            self.reduceRotationSpeed()
        }
    }
    
    private func reduceRotationSpeed() {
        clickCount = max(0, clickCount - 1)
        
        currentRotationSpeed = min(baseRotationSpeed * (1.0 + Double(clickCount) * 0.5), baseRotationSpeed * 10.0)
        currentRadius = min(baseRadius * (1.0 + Double(clickCount) * 0.025), baseRadius * 10.0)
        
        if clickCount > 0 {
            speedBoostTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                self.reduceRotationSpeed()
            }
        } else {
            currentRotationSpeed = baseRotationSpeed
            currentRadius = baseRadius
            speedBoostTimer = nil
        }
    }
    
    @objc func updateGame() {
        let totalProduction = getTotalProductionRate()
        if totalProduction > 0 {
            let increment = totalProduction * 0.1 // 0.1 second interval
            bierCount += increment
            updateUI()
        }
    }
    
    private func updateUI() {
        bierCountLabel.text = "Bier: \(Int(bierCount))"
        
        let totalPerSecond = getTotalProductionRate()
        perSecondLabel.text = "\(String(format: "%.1f", totalPerSecond)) bier/sec"
        
        if isShopOpen {
            updateShopItems()
        }
    }
    
    @objc func resetGameFromSettings() {
        let alert = UIAlertController(
            title: "Spel Resetten?",
            message: "Weet je zeker dat je alle voortgang wilt wissen? Deze actie kan niet ongedaan worden gemaakt!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Annuleren", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            // Reset game data
            self.bierCount = 0
            for i in 0..<self.shopItems.count {
                self.shopItems[i].count = 0
            }
            self.saveProgress()
            self.updateUI()
            self.updateFloatingItemsVisibility()
            
            self.toggleSettings()
            
            let confirmAlert = UIAlertController(
                title: "Spel Gereset!",
                message: "Je voortgang is gewist. Veel plezier met een nieuw begin! 🍻",
                preferredStyle: .alert
            )
            confirmAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(confirmAlert, animated: true)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Settings Interactions
    
    @objc func toggleSettings() {
        isSettingsOpen = !isSettingsOpen
        
        if isSettingsOpen {
            settingsView.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.settingsView.alpha = 1.0
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.settingsView.alpha = 0.0
            } completion: { _ in
                self.settingsView.isHidden = true
            }
        }
    }
    
    // MARK: - Shop Interactions
    
    @objc func toggleShop() {
        isShopOpen = !isShopOpen
        
        let buttonSize: CGFloat = 60 * deviceConfig.shopScale
        let padding: CGFloat = 20
        
        let finalWidth: CGFloat = 250 * deviceConfig.shopScale
        let finalHeight: CGFloat = 400 * deviceConfig.shopScale
        let finalX = view.bounds.width - finalWidth - padding
        let finalY = view.bounds.height - finalHeight - padding - buttonSize - 10
        
        if isShopOpen {
            shopButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
                self.shopView.frame = CGRect(x: finalX, y: finalY, width: finalWidth, height: finalHeight)
                self.shopView.layer.cornerRadius = 15
                self.shopView.alpha = 1.0
            }, completion: nil)
        } else {
            shopButton.setImage(UIImage(systemName: "cart"), for: .normal)
            
            UIView.animate(withDuration: 0.2, animations: {
                self.shopView.frame = CGRect(
                    x: self.shopButton.center.x - 25,
                    y: self.shopButton.center.y - 25,
                    width: 50,
                    height: 50
                )
                self.shopView.layer.cornerRadius = 25
                self.shopView.alpha = 0
            })
        }
        
        updateShopItems()
    }
    
    @objc func shopItemTapped(_ gesture: UITapGestureRecognizer) {
        guard let itemView = gesture.view else { return }
        guard let priceString = itemView.accessibilityValue,
              let price = Int(priceString) else { return }
        
        let itemIndex = itemView.tag - 1 // Convert back to array index
        guard itemIndex >= 0 && itemIndex < shopItems.count else { return }
        
        var canAfford = false
        
        if bierCount >= Double(price) {
            bierCount -= Double(price)
            shopItems[itemIndex].count += 1
            canAfford = true
        }
        
        if canAfford {
            updateUI()
            saveProgress()
            updateFloatingItemsVisibility()
            
            itemView.layer.removeAllAnimations()
            itemView.transform = .identity
            itemView.backgroundColor = .white
            
            UIView.animate(withDuration: 0.05, animations: {
                itemView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                itemView.backgroundColor = UIColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 1.0)
            }, completion: { _ in
                UIView.animate(withDuration: 0.05) {
                    itemView.transform = .identity
                    itemView.backgroundColor = .white
                }
            })
        } else {
            itemView.layer.removeAllAnimations()
            itemView.backgroundColor = .white
            
            UIView.animate(withDuration: 0.2, animations: {
                itemView.backgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1.0)
            }, completion: { _ in
                UIView.animate(withDuration: 0.2) {
                    itemView.backgroundColor = .white
                }
            })
        }
        
        updateShopItems()
    }
    
    @objc func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        if isShopOpen {
            let location = gesture.location(in: view)
            if !shopView.frame.contains(location) && !shopButton.frame.contains(location) {
                toggleShop()
            }
        }
    }
    
    deinit {
        gameTimer?.invalidate()
        itemAnimationTimer?.invalidate()
        speedBoostTimer?.invalidate()
        bounceTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}
