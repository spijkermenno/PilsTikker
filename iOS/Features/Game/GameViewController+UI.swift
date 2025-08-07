//
//  GameViewController+UI.swift
//  Tap the Cap iOS
//
//  Created by Menno Spijker on 07/08/2025.
//

import UIKit

extension GameViewController {

    func setupUI() {
        // Bierdop with device-specific scaling
        let bierDopImage = UIImage(named: "bierdop")
                
        imageView = UIImageView(image: bierDopImage)
        imageView.contentMode = .scaleAspectFit
        
        let bierdopSize = 150 * deviceConfig.bierdopScale
        imageView.frame = CGRect(x: 0, y: 0, width: bierdopSize, height: bierdopSize)
        imageView.center = view.center
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)

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

        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        imageView.addGestureRecognizer(tapGesture)

        updateUI()
    }

    func updateUI() {
        bierCountLabel.text = "Bier: \(Int(bierCount))"
        let totalPerSecond = getTotalProductionRate()
        perSecondLabel.text = "\(String(format: "%.1f", totalPerSecond)) bier/sec"

        if isShopOpen {
            updateShopItems()
        }
    }
}
