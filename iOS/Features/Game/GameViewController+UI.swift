//
//  GameViewController+UI.swift
//  Cheesery iOS
//
//  Created by Menno Spijker on 07/08/2025.
//

import UIKit

extension GameViewController {

    func setupUI() {
        // Clicker (content area)
        let bierDopImage = UIImage(named: "bierdop")
        imageView = UIImageView(image: bierDopImage)
        imageView.contentMode = .scaleAspectFit

        let bierdopSize = 150 * deviceConfig.bierdopScale
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        contentContainer.addSubview(imageView)

        // Ensure header has a layout so we can read its height
        view.layoutIfNeeded()
        let headerHeight = headerContainer.bounds.height

        // Center X to the full view; center Y to the full view WITH header offset,
        // so visual center is corrected by half the header height.
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: headerHeight / 2),
            imageView.widthAnchor.constraint(equalToConstant: bierdopSize),
            imageView.heightAnchor.constraint(equalToConstant: bierdopSize),
        ])

        baseRadius = deviceConfig.baseRadius
        currentRadius = baseRadius

        // Resolve frames to compute accurate center for animations
        view.layoutIfNeeded()
        bierdopCenterY = imageView.center.y

        // Labels in header
        let labelFontScale = deviceConfig.bierdopScale

        bierCountLabel = UILabel()
        bierCountLabel.textAlignment = .center
        bierCountLabel.textColor = .brown
        bierCountLabel.font = UIFont.boldSystemFont(ofSize: 24 * labelFontScale)
        bierCountLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(bierCountLabel)

        perSecondLabel = UILabel()
        perSecondLabel.textAlignment = .center
        perSecondLabel.textColor = .brown
        perSecondLabel.font = UIFont.systemFont(ofSize: 16 * labelFontScale)
        perSecondLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(perSecondLabel)

        NSLayoutConstraint.activate([
            bierCountLabel.topAnchor.constraint(equalTo: headerContainer.safeAreaLayoutGuide.topAnchor, constant: 8),
            bierCountLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            bierCountLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),

            perSecondLabel.topAnchor.constraint(equalTo: bierCountLabel.bottomAnchor, constant: 4),
            perSecondLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            perSecondLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        imageView.addGestureRecognizer(tapGesture)

        updateUI()
    }

    func updateUI() {
        bierCountLabel.text = Localized.bierCount(Int(bierCount))
        let totalPerSecond = getTotalProductionRate()
        perSecondLabel.text = Localized.bierPerSecond(totalPerSecond)

        if isShopOpen {
            updateShopItems()
        }
    }
}
