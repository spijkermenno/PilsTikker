//
//  GameViewController+Shop.swift
//  Tap the Cap iOS
//
//  Created by Menno Spijker on 07/08/2025.
//

import UIKit

extension GameViewController: UIGestureRecognizerDelegate {

    func setupShopUI() {
        let buttonSize: CGFloat = 60 * deviceConfig.shopScale
        let padding: CGFloat = 20

        // Floating cart button
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

        // Target size when expanded
        let shopWidth = 250 * deviceConfig.shopScale
        let shopHeight = 400 * deviceConfig.shopScale

        // Collapsed seed bubble near the FAB
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

        // ===== Scrollable content via Auto Layout (no manual frames) =====
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        shopView.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: shopView.topAnchor),
            container.leadingAnchor.constraint(equalTo: shopView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: shopView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: shopView.bottomAnchor)
        ])

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.contentInsetAdjustmentBehavior = .never
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 10
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 10),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 10),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -10),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -10),
            // Important: fix width to frame layout guide so intrinsic content decides height => proper scrolling
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -20)
        ])

        // Header
        let headerFontSize = 18 * deviceConfig.shopScale
        let shopHeader = UILabel()
        shopHeader.textAlignment = .center
        shopHeader.font = .boldSystemFont(ofSize: headerFontSize)
        shopHeader.textColor = .black
        shopHeader.text = Localized.Shop.title
        content.addArrangedSubview(shopHeader)

        // Divider
        let divider = UIView()
        divider.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        content.addArrangedSubview(divider)

        // Items stack
        let itemsStack = UIStackView()
        itemsStack.axis = .vertical
        itemsStack.spacing = 10
        itemsStack.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(itemsStack)

        // Build items (Auto Layout cells)
        for (index, item) in shopItems.enumerated() {
            let v = makeShopItemView(
                image: UIImage(named: item.imageName),
                title: item.name,
                description: item.description,
                price: item.basePrice,
                tag: index + 1
            )
            itemsStack.addArrangedSubview(v)
        }

        // Background tap (don’t steal from scrolling)
        let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        backgroundTap.cancelsTouchesInView = false
        backgroundTap.delegate = self
        view.addGestureRecognizer(backgroundTap)

        // Make sure the tap waits for scroll’s pan (prevents “springy” jumps)
        backgroundTap.require(toFail: scrollView.panGestureRecognizer)

        // Store desired expanded frame for animation math (using local constants)
        // We still use the original popup animation, but the inside layout is stable.
        _ = shopWidth; _ = shopHeight
    }

    // Only recognize background taps when not touching the shopView (helps avoid accidental triggers)
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // If touch is inside shopView, ignore this background tap
        if let view = touch.view, view.isDescendant(of: shopView) { return false }
        return true
    }

    // MARK: - View Builders

    private func makeShopItemView(image: UIImage?, title: String, description: String, price: Int, tag: Int) -> UIView {
        let itemHeight: CGFloat = 80
        let padding: CGFloat = 10

        let itemView = UIView()
        itemView.translatesAutoresizingMaskIntoConstraints = false
        itemView.backgroundColor = .white
        itemView.layer.cornerRadius = 10
        itemView.tag = tag
        itemView.heightAnchor.constraint(equalToConstant: itemHeight).isActive = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(shopItemTapped(_:)))
        itemView.addGestureRecognizer(tapGesture)

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = image

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.tag = 100 + tag
        titleLabel.textColor = .black

        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.text = description
        descLabel.font = UIFont.systemFont(ofSize: 12)
        descLabel.textColor = .darkGray
        descLabel.numberOfLines = 1

        let priceLabel = UILabel()
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.text = "\(price) bier 🍺"
        priceLabel.font = UIFont.systemFont(ofSize: 14)
        priceLabel.textColor = .brown

        itemView.addSubview(imageView)
        itemView.addSubview(titleLabel)
        itemView.addSubview(descLabel)
        itemView.addSubview(priceLabel)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: padding),
            imageView.centerYAnchor.constraint(equalTo: itemView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: itemHeight - 20),
            imageView.heightAnchor.constraint(equalToConstant: itemHeight - 20),

            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -padding),
            titleLabel.topAnchor.constraint(equalTo: itemView.topAnchor, constant: 10),

            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),

            priceLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            priceLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 4)
        ])

        // Keep price for logic
        itemView.accessibilityValue = "\(price)"
        return itemView
    }

    // MARK: - State Updates

    func updateShopItems() {
        // Only mutate labels/alpha; no layout/frames/contentSize here.
        for (index, item) in shopItems.enumerated() {
            let tag = index + 1
            guard let itemView = shopView.viewWithTag(tag) else { continue }
            guard let priceString = itemView.accessibilityValue,
                  let price = Int(priceString) else { continue }

            let canAfford = bierCount >= Double(price)
            let targetAlpha: CGFloat = canAfford ? 1.0 : 0.6
            if itemView.alpha != targetAlpha { itemView.alpha = targetAlpha }

            if let titleLabel = itemView.viewWithTag(100 + tag) as? UILabel {
                let newTitle = item.count > 0 ? "\(item.name) (\(item.count))" : item.name
                if titleLabel.text != newTitle { titleLabel.text = newTitle }
            }
        }
    }

    // MARK: - Open / Close

    @objc func toggleShop() {
        isShopOpen.toggle()

        let buttonSize: CGFloat = 60 * deviceConfig.shopScale
        let padding: CGFloat = 20
        let finalWidth: CGFloat = 250 * deviceConfig.shopScale
        let finalHeight: CGFloat = 400 * deviceConfig.shopScale
        let finalX = view.bounds.width - finalWidth - padding
        let finalY = view.bounds.height - finalHeight - padding - buttonSize - 10

        if isShopOpen {
            shopButton.setImage(UIImage(systemName: "xmark"), for: .normal)

            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0,
                           options: [],
                           animations: {
                self.shopView.frame = CGRect(x: finalX, y: finalY, width: finalWidth, height: finalHeight)
                self.shopView.layer.cornerRadius = 15
                self.shopView.alpha = 1.0
            }, completion: { _ in
                // One-time refresh on open
                self.updateShopItems()
            })
        } else {
            shopButton.setImage(UIImage(systemName: "cart"), for: .normal)

            UIView.animate(withDuration: 0.2) {
                self.shopView.frame = CGRect(
                    x: self.shopButton.center.x - 25,
                    y: self.shopButton.center.y - 25,
                    width: 50,
                    height: 50
                )
                self.shopView.layer.cornerRadius = 25
                self.shopView.alpha = 0
            }
        }
    }

    // MARK: - Item tap

    @objc func shopItemTapped(_ gesture: UITapGestureRecognizer) {
        guard let itemView = gesture.view,
              let priceString = itemView.accessibilityValue,
              let price = Int(priceString) else { return }

        let itemIndex = itemView.tag - 1
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

        // Update AFTER purchase (once)
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
}
