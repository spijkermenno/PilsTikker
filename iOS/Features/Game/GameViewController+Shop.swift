//
//  GameViewController+Shop.swift
//  Tap the Cap iOS
//
//  Created by Menno Spijker on 07/08/2025.
//

import UIKit

extension GameViewController {

    func setupShopUI() {
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

        // Header
        let headerFontSize = 18 * deviceConfig.shopScale
        let shopHeader = UILabel(frame: CGRect(x: 0, y: 10, width: shopWidth, height: 30 * deviceConfig.shopScale))
        shopHeader.text = "Winkel"
        shopHeader.font = UIFont.boldSystemFont(ofSize: headerFontSize)
        shopHeader.textAlignment = .center
        shopView.addSubview(shopHeader)

        // Divider
        let divider = UIView(frame: CGRect(x: 15 * deviceConfig.shopScale, y: 45, width: shopWidth - 30, height: 1))
        divider.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        shopView.addSubview(divider)

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

    func updateShopItems() {
        for (index, item) in shopItems.enumerated() {
            let tag = index + 1
            guard let itemView = shopView.viewWithTag(tag) else { continue }
            guard let priceString = itemView.accessibilityValue,
                  let price = Int(priceString) else { continue }

            let canAfford = bierCount >= Double(price)
            itemView.alpha = canAfford ? 1.0 : 0.6

            if let titleLabel = itemView.viewWithTag(100 + tag) as? UILabel {
                titleLabel.text = item.count > 0 ? "\(item.name) (\(item.count))" : item.name
            }
        }
    }

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

            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
                self.shopView.frame = CGRect(x: finalX, y: finalY, width: finalWidth, height: finalHeight)
                self.shopView.layer.cornerRadius = 15
                self.shopView.alpha = 1.0
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

        updateShopItems()
    }

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
