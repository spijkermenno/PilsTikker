import UIKit

class GameViewController: UIViewController {
    // Afbeelding en click zone
    private var imageView: UIImageView!
    private var bierCount: Double = 0
    private var bierCountLabel: UILabel!
    private var perSecondLabel: UILabel!
    
    // Winkel items
    private var bierFlesCount: Int = 0
    private var kratCount: Int = 0
    private var bierFustCount: Int = 0
    
    // Shop UI elements
    private var shopButton: UIButton!
    private var shopView: UIView!
    private var isShopOpen: Bool = false
    
    // Timer voor passieve inkomsten
    private var gameTimer: Timer?
    
    // Floating items animation
    private var floatingItemViews: [UIImageView] = []
    private var itemAnimationTimer: Timer?
    private var itemAngle: Double = 0.0
    private var floatingItemOrder: [String] = [] // Store randomized order
    
    // Constants for UserDefaults keys
    private let keyBierCount = "bierCount"
    private let keyBierFlesCount = "bierFlesCount"
    private let keyKratCount = "kratCount"
    private let keyBierFustCount = "bierFustCount"
    private let keyLastSaveTime = "lastSaveTime"
    
    // spinning animation
    private var baseRotationSpeed: Double = 0.01
    private var currentRotationSpeed: Double = 0.01
    private var speedBoostTimer: Timer?
    private var clickCount: Int = 0
    
    private var baseRadius: Double = 110
    private var currentRadius: Double = 110
    
    // Offline earnings constants
    private let maxOfflineMinutes: Double = 30.0 // Maximum 30 minutes of offline earnings
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set a simple background color
        view.backgroundColor = UIColor(red: 0.76, green: 0.65, blue: 0.48, alpha: 1.0)
        
        loadProgress()
        setupUI()
        setupFloatingItemsAnimation()
        setupShopUI()
        setupTimer()
        
        // Set up autosave
        setupAutosave()
        
        // Save when app goes to background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveProgress),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    // MARK: - Progress Saving & Loading
    
    private func loadProgress() {
        let defaults = UserDefaults.standard
        bierCount = defaults.double(forKey: keyBierCount)
        bierFlesCount = defaults.integer(forKey: keyBierFlesCount)
        kratCount = defaults.integer(forKey: keyKratCount)
        bierFustCount = defaults.integer(forKey: keyBierFustCount)
        
        // Calculate offline progress with 30-minute limit
        if let lastSaveTime = defaults.object(forKey: keyLastSaveTime) as? Date {
            let elapsedSeconds = Date().timeIntervalSince(lastSaveTime)
            let maxOfflineSeconds = maxOfflineMinutes * 60.0 // Convert to seconds
            
            // Only calculate offline earnings if elapsed time is positive and within the limit
            if elapsedSeconds > 0 && elapsedSeconds >= maxOfflineSeconds && (bierFlesCount > 0 || kratCount > 0 || bierFustCount > 0) {
                // Add offline production (capped at 30 minutes)
                let offlineProduction = (Double(bierFlesCount) * 0.1 +
                                       Double(kratCount) * 0.3 +
                                       Double(bierFustCount) * 1.0) * elapsedSeconds
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
        defaults.set(bierFlesCount, forKey: keyBierFlesCount)
        defaults.set(kratCount, forKey: keyKratCount)
        defaults.set(bierFustCount, forKey: keyBierFustCount)
        defaults.set(Date(), forKey: keyLastSaveTime)
    }
    
    private func setupAutosave() {
        // Autosave every 30 seconds
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
    
    // MARK: - Floating Items Animation Setup
    
    private func setupFloatingItemsAnimation() {
        // Create maximum 12 floating item views
        for i in 0..<12 {
            let itemImageView = UIImageView()
            itemImageView.contentMode = .scaleAspectFit
            itemImageView.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
            itemImageView.isHidden = true // Initially hidden
            itemImageView.tag = i // For identification
            view.addSubview(itemImageView)
            floatingItemViews.append(itemImageView)
        }
        
        // Start the animation timer
        itemAnimationTimer = Timer.scheduledTimer(timeInterval: 0.016, target: self, selector: #selector(updateFloatingItemPositions), userInfo: nil, repeats: true) // ~60 FPS
        
        // Initial update to show/hide items based on current counts
        updateFloatingItemsVisibility()
    }
    
    private func updateFloatingItemsVisibility() {
        let totalItems = bierFlesCount + kratCount + bierFustCount
        let maxFloatingItems = 12
        
        if totalItems == 0 {
            // Hide all items
            for itemView in floatingItemViews {
                itemView.isHidden = true
            }
            floatingItemOrder = [] // Clear the order
            return
        }
        
        // Calculate percentage-based distribution, but never exceed actual owned amounts
        let totalFloatingItems = min(totalItems, maxFloatingItems)
        
        // Calculate ideal slots based on percentage
        let idealBottleSlots = Double(bierFlesCount) / Double(totalItems) * Double(totalFloatingItems)
        let idealCrateSlots = Double(kratCount) / Double(totalItems) * Double(totalFloatingItems)
        let idealKegSlots = Double(bierFustCount) / Double(totalItems) * Double(totalFloatingItems)
        
        // Round to integers, but never exceed actual owned amounts
        var bottleSlots = min(bierFlesCount, Int(round(idealBottleSlots)))
        var crateSlots = min(kratCount, Int(round(idealCrateSlots)))
        var kegSlots = min(bierFustCount, Int(round(idealKegSlots)))
        
        // Ensure we don't exceed the total floating limit
        let currentTotal = bottleSlots + crateSlots + kegSlots
        
        // If we're over the limit, reduce proportionally
        if currentTotal > totalFloatingItems {
            let reductionFactor = Double(totalFloatingItems) / Double(currentTotal)
            bottleSlots = min(bierFlesCount, Int(Double(bottleSlots) * reductionFactor))
            crateSlots = min(kratCount, Int(Double(crateSlots) * reductionFactor))
            kegSlots = min(bierFustCount, Int(Double(kegSlots) * reductionFactor))
        }
        
        // If we're under the limit, try to add more items proportionally
        let finalTotal = bottleSlots + crateSlots + kegSlots
        var remaining = totalFloatingItems - finalTotal
        
        // Distribute remaining slots to items that have more owned than currently shown
        while remaining > 0 {
            var added = false
            
            // Try to add bottles first if we have more than shown
            if remaining > 0 && bottleSlots < bierFlesCount && bierFlesCount > 0 {
                bottleSlots += 1
                remaining -= 1
                added = true
            }
            
            // Try to add crates if we have more than shown
            if remaining > 0 && crateSlots < kratCount && kratCount > 0 {
                crateSlots += 1
                remaining -= 1
                added = true
            }
            
            // Try to add kegs if we have more than shown
            if remaining > 0 && kegSlots < bierFustCount && bierFustCount > 0 {
                kegSlots += 1
                remaining -= 1
                added = true
            }
            
            // If we couldn't add any more items, break to avoid infinite loop
            if !added {
                break
            }
        }
        
        print("DEBUG: Total items: \(totalItems), Bottles: \(bierFlesCount), Crates: \(kratCount), Kegs: \(bierFustCount)")
        print("DEBUG: Floating - Bottles: \(bottleSlots)/\(bierFlesCount), Crates: \(crateSlots)/\(kratCount), Kegs: \(kegSlots)/\(bierFustCount)")
        
        // Create array of item types to randomize
        var itemsToShow: [String] = []
        
        // Add bottles
        for _ in 0..<bottleSlots {
            itemsToShow.append("bierfles")
        }
        
        // Add crates
        for _ in 0..<crateSlots {
            itemsToShow.append("bierkrat")
        }
        
        // Add kegs
        for _ in 0..<kegSlots {
            itemsToShow.append("bierfust")
        }
        
        // Shuffle the array to randomize order
        itemsToShow.shuffle()
        
        // Store the randomized order
        floatingItemOrder = itemsToShow
        
        // Apply the randomized items to the floating views
        for i in 0..<min(floatingItemOrder.count, floatingItemViews.count) {
            floatingItemViews[i].image = UIImage(named: floatingItemOrder[i])
            floatingItemViews[i].isHidden = false
        }
        
        // Hide remaining item views
        for i in floatingItemOrder.count..<floatingItemViews.count {
            floatingItemViews[i].isHidden = true
        }
    }
    
    @objc private func updateFloatingItemPositions() {
        let visibleItemsCount = floatingItemOrder.count
        
        if visibleItemsCount > 0 {
            // Update angle for circular motion using current rotation speed
            itemAngle += currentRotationSpeed
            
            // Calculate positions for each visible item (using the randomized order)
            for i in 0..<min(visibleItemsCount, floatingItemViews.count) {
                let itemView = floatingItemViews[i]
                
                if !itemView.isHidden {
                    // Calculate angle offset for this specific item position
                    let angleOffset = (Double(i) * 2.0 * Double.pi) / Double(visibleItemsCount)
                    let currentAngle = itemAngle + angleOffset
                    
                    // Calculate circular position around bierdop
                    let radius: CGFloat = currentRadius // Distance from center of bierdop
                    let centerX = imageView.center.x
                    let centerY = imageView.center.y
                    
                    let x = centerX + radius * cos(currentAngle)
                    let y = centerY + radius * sin(currentAngle)
                    
                    // Update item position
                    itemView.center = CGPoint(x: x, y: y)
                    
                    // Optional: Add slight rotation to each item for more dynamic effect
                    itemView.transform = CGAffineTransform(rotationAngle: CGFloat(currentAngle * 0.5))
                }
            }
        }
    }
    // MARK: - UI Setup
    
    private func setupUI() {
        // Bierdop afbeelding toevoegen (resized to 150px)
        let bierDopImage = UIImage(named: "bierdop")
        imageView = UIImageView(image: bierDopImage)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
        imageView.center = view.center
        imageView.isUserInteractionEnabled = true // Belangrijk voor touch handling
        view.addSubview(imageView)
        
        // Bier count label (no decimals)
        bierCountLabel = UILabel(frame: CGRect(x: 0, y: 60, width: view.bounds.width, height: 40))
        bierCountLabel.textAlignment = .center
        bierCountLabel.textColor = .brown
        bierCountLabel.font = UIFont.boldSystemFont(ofSize: 24)
        bierCountLabel.text = "Bier: 0"
        view.addSubview(bierCountLabel)
        
        // Per second label (new, replaces the detailed items label)
        perSecondLabel = UILabel(frame: CGRect(x: 0, y: 100, width: view.bounds.width, height: 30))
        perSecondLabel.textAlignment = .center
        perSecondLabel.textColor = .brown
        perSecondLabel.font = UIFont.systemFont(ofSize: 16)
        perSecondLabel.text = "0.0 bier/sec"
        view.addSubview(perSecondLabel)
        
        // Tap gesture toevoegen
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        imageView.addGestureRecognizer(tapGesture)
        
        // Reset knop toevoegen (for testing)
        let resetButton = UIButton(type: .system)
        resetButton.frame = CGRect(x: 10, y: 30, width: 60, height: 30)
        resetButton.setTitle("Reset", for: .normal)
        resetButton.setTitleColor(.red, for: .normal)
        resetButton.addTarget(self, action: #selector(resetGame), for: .touchUpInside)
        view.addSubview(resetButton)
        
        updateUI()
    }
    
    private func setupShopUI() {
        // Create shop button in bottom right corner
        let buttonSize: CGFloat = 60
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
        
        // Create shop view positioned at the button location (initially small and hidden)
        shopView = UIView(frame: CGRect(
            x: shopButton.center.x - 25, // Center on button horizontally
            y: shopButton.center.y - 25, // Center on button vertically
            width: 50, // Start very small
            height: 50
        ))
        shopView.backgroundColor = UIColor(white: 0.95, alpha: 0.95)
        shopView.layer.cornerRadius = 25 // Half of initial size for circular start
        shopView.layer.shadowColor = UIColor.black.cgColor
        shopView.layer.shadowOffset = CGSize(width: 0, height: -3)
        shopView.layer.shadowOpacity = 0.3
        shopView.layer.shadowRadius = 5
        shopView.clipsToBounds = true // Important for the expand animation
        shopView.alpha = 0 // Start invisible
        view.addSubview(shopView)
        
        // Add shop header
        let shopHeader = UILabel(frame: CGRect(x: 0, y: 10, width: 250, height: 30))
        shopHeader.text = "Winkel"
        shopHeader.font = UIFont.boldSystemFont(ofSize: 18)
        shopHeader.textAlignment = .center
        shopView.addSubview(shopHeader)
        
        // Add a divider
        let divider = UIView(frame: CGRect(x: 15, y: 45, width: 220, height: 1))
        divider.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        shopView.addSubview(divider)
        
        // Add bierfles item to the shop (new)
        createShopItem(
            image: UIImage(named: "bierfles"),
            title: "Bierfles",
            description: "Produceert 0.1 bier/sec",
            price: 12,
            tag: 1,
            position: 0
        )
        
        // Add bierkrat item to the shop (updated rate)
        createShopItem(
            image: UIImage(named: "bierkrat"),
            title: "Bierkrat",
            description: "Produceert 0.3 bier/sec",
            price: 24,
            tag: 2,
            position: 1
        )
        
        // Add bierfust item to the shop (new)
        createShopItem(
            image: UIImage(named: "bierfust"),
            title: "Bierfust",
            description: "Produceert 1.0 bier/sec",
            price: 120,
            tag: 3,
            position: 2
        )
        
        // Close shop when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func createShopItem(image: UIImage?, title: String, description: String, price: Int, tag: Int, position: Int) {
        let itemHeight: CGFloat = 80
        let padding: CGFloat = 10
        let yPosition: CGFloat = 50 + CGFloat(position) * (itemHeight + padding)
        
        // Item container (fixed width for expanded shop size)
        let itemView = UIView(frame: CGRect(x: 10, y: yPosition, width: 230, height: itemHeight))
        itemView.backgroundColor = UIColor.white
        itemView.layer.cornerRadius = 10
        itemView.tag = tag
        shopView.addSubview(itemView)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(shopItemTapped(_:)))
        itemView.addGestureRecognizer(tapGesture)
        itemView.isUserInteractionEnabled = true
        
        // Item image
        let imageView = UIImageView(frame: CGRect(x: 10, y: 10, width: itemHeight - 20, height: itemHeight - 20))
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        itemView.addSubview(imageView)
        
        // Item title
        let titleLabel = UILabel(frame: CGRect(x: itemHeight, y: 10, width: itemView.bounds.width - itemHeight - 10, height: 20))
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        itemView.addSubview(titleLabel)
        
        // Item description
        let descLabel = UILabel(frame: CGRect(x: itemHeight, y: 30, width: itemView.bounds.width - itemHeight - 10, height: 20))
        descLabel.text = description
        descLabel.font = UIFont.systemFont(ofSize: 12)
        descLabel.textColor = .darkGray
        itemView.addSubview(descLabel)
        
        // Item price
        let priceLabel = UILabel(frame: CGRect(x: itemHeight, y: 50, width: itemView.bounds.width - itemHeight - 10, height: 20))
        priceLabel.text = "\(price) bier 🍺"
        priceLabel.font = UIFont.systemFont(ofSize: 14)
        priceLabel.textColor = .brown
        itemView.addSubview(priceLabel)
        
        // Store price for later reference
        itemView.accessibilityValue = "\(price)"
    }
    
    // MARK: - Game Mechanics
    
    private func setupTimer() {
        // Timer voor passieve inkomsten
        gameTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateGame), userInfo: nil, repeats: true)
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        // Bier toevoegen (immediate action)
        bierCount += 1
        updateUI()
        
        // Increase rotation speed
        increaseRotationSpeed()
        
        // Cancel any existing animations
        imageView.layer.removeAllAnimations()
        
        // Reset transform to identity before starting new animation
        imageView.transform = CGAffineTransform.identity
        
        // Start new animation
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
        // Increment click count, but cap it to maintain max 10x speed
        let maxClickCount = Int(10.0 / 0.5) // Calculate max clicks for 10x speed (20 clicks)
        clickCount = min(clickCount + 1, maxClickCount)
        
        // Calculate new speed (50% increase per click, capped at 10x base speed)
        currentRotationSpeed = min(baseRotationSpeed * (1.0 + Double(clickCount) * 0.5), baseRotationSpeed * 10.0)
        currentRadius = min(baseRadius * (1.0 + Double(clickCount) * 0.025), baseRadius * 10.0)
        
        // Cancel existing timer
        speedBoostTimer?.invalidate()
        
        // Start new timer to reduce speed after 1 second
        speedBoostTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            self.reduceRotationSpeed()
        }
    }

    private func reduceRotationSpeed() {
        // Reduce click count by 1 (gradual slowdown)
        clickCount = max(0, clickCount - 1)
        
        // Recalculate speed (capped at 10x base speed)
        currentRotationSpeed = min(baseRotationSpeed * (1.0 + Double(clickCount) * 0.5), baseRotationSpeed * 10.0)
        currentRadius = min(baseRadius * (1.0 + Double(clickCount) * 0.025), baseRadius * 10.0)

        // If still have clicks remaining, schedule another reduction
        if clickCount > 0 {
            speedBoostTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                self.reduceRotationSpeed()
            }
        } else {
            // Reset to base speed
            currentRotationSpeed = baseRotationSpeed
            currentRadius = baseRadius
            speedBoostTimer = nil
        }
    }
    
    @objc func updateGame() {
        // Voeg passieve inkomsten toe
        if bierFlesCount > 0 || kratCount > 0 || bierFustCount > 0 {
            let increment = (Double(bierFlesCount) * 0.1 +
                           Double(kratCount) * 0.3 +
                           Double(bierFustCount) * 1.0) * 0.1 // 0.1 second interval
            bierCount += increment
            updateUI()
        }
    }
    
    private func updateUI() {
        // Update bier count without decimals
        bierCountLabel.text = "Bier: \(Int(bierCount))"
        
        // Update per second rate
        let totalPerSecond = Double(bierFlesCount) * 0.1 + Double(kratCount) * 0.3 + Double(bierFustCount) * 1.0
        perSecondLabel.text = "\(String(format: "%.1f", totalPerSecond)) bier/sec"
        
        // Update shop items if shop is open
        if isShopOpen {
            updateShopItems()
        }
    }
    
    @objc func resetGame() {
        let alert = UIAlertController(
            title: "Reset spel?",
            message: "Weet je zeker dat je alle voortgang wilt wissen?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Annuleren", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            // Reset game data
            self.bierCount = 0
            self.bierFlesCount = 0
            self.kratCount = 0
            self.bierFustCount = 0
            self.saveProgress()
            self.updateUI()
            self.updateFloatingItemsVisibility() // Update floating items visibility after reset
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Shop Interactions
    
    @objc func toggleShop() {
        isShopOpen = !isShopOpen
        
        let buttonSize: CGFloat = 60
        let padding: CGFloat = 20
        
        // Calculate final shop position and size
        let finalWidth: CGFloat = 250
        let finalHeight: CGFloat = 400
        let finalX = view.bounds.width - finalWidth - padding
        let finalY = view.bounds.height - finalHeight - padding - buttonSize - 10
        
        if isShopOpen {
            // Change button to close icon
            shopButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            
            // Animate shop expansion from button position
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
                self.shopView.frame = CGRect(x: finalX, y: finalY, width: finalWidth, height: finalHeight)
                self.shopView.layer.cornerRadius = 15
                self.shopView.alpha = 1.0
            }, completion: nil)
        } else {
            // Change button back to cart icon
            shopButton.setImage(UIImage(systemName: "cart"), for: .normal)
            
            // Animate shop collapse back to button position
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
        
        var canAfford = false
        
        switch itemView.tag {
        case 1: // Bierfles
            if bierCount >= Double(price) {
                bierCount -= Double(price)
                bierFlesCount += 1
                canAfford = true
            }
        case 2: // Bierkrat
            if bierCount >= Double(price) {
                bierCount -= Double(price)
                kratCount += 1
                canAfford = true
            }
        case 3: // Bierfust
            if bierCount >= Double(price) {
                bierCount -= Double(price)
                bierFustCount += 1
                canAfford = true
            }
        default:
            break
        }
        
        if canAfford {
            updateUI()
            saveProgress()
            updateFloatingItemsVisibility() // Update floating items when purchasing
            
            // Cancel any existing animations
            itemView.layer.removeAllAnimations()
            
            // Reset to default state before starting new animation
            itemView.transform = .identity
            itemView.backgroundColor = .white
            
            // Show animation for successful purchase
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
            // Cancel any existing animations
            itemView.layer.removeAllAnimations()
            
            // Reset to default state before starting new animation
            itemView.backgroundColor = .white
            
            // Show animation for failed purchase
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
        // Close shop when tapping outside if it's open
        if isShopOpen {
            let location = gesture.location(in: view)
            if !shopView.frame.contains(location) && !shopButton.frame.contains(location) {
                toggleShop()
            }
        }
    }
    
    private func updateShopItems() {
        // Update shop items based on available resources
        for tag in 1...3 {
            guard let item = shopView.viewWithTag(tag) else { continue }
            guard let priceString = item.accessibilityValue,
                  let price = Int(priceString) else { continue }
            
            let canAfford = bierCount >= Double(price)
            item.alpha = canAfford ? 1.0 : 0.6
        }
    }
    
    deinit {
        gameTimer?.invalidate()
        itemAnimationTimer?.invalidate()
        speedBoostTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}
