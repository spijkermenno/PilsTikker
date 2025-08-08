//
//  GameViewController+Animation.swift
//  Tap the Cap iOS
//
//  Created by Menno Spijker on 07/08/2025.
//

import UIKit

extension GameViewController {

    func setupFloatingItemsAnimation() {
        let totalCapacity = getTotalMaxFloatingItems()

        for i in 0..<totalCapacity {
            let itemImageView = UIImageView()
            itemImageView.contentMode = .scaleAspectFit

            let itemSize = 35 * deviceConfig.bierdopScale
            itemImageView.frame = CGRect(x: 0, y: 0, width: itemSize, height: itemSize)
            itemImageView.isHidden = true
            itemImageView.tag = i
            contentContainer.addSubview(itemImageView)

            floatingItemViews.append(itemImageView)

            let randomOffset = Double.random(in: 0...(5 * Double.pi))
            itemRotationOffsets.append(randomOffset)
        }

        itemAnimationTimer = Timer.scheduledTimer(
            timeInterval: 0.016,
            target: self,
            selector: #selector(updateFloatingItemPositions),
            userInfo: nil,
            repeats: true
        )

        updateFloatingItemsVisibility()
    }

    @objc private func updateFloatingItemPositions() {
        let visibleItemsCount = floatingItemOrder.count
        guard visibleItemsCount > 0 else { return }

        itemAngle += currentRotationSpeed
        itemRotationAngle += itemRotationSpeed

        var itemIndex = 0

        for ringIndex in 0..<deviceConfig.maxRings {
            let ringRadius = CGFloat(deviceConfig.baseRadius + (Double(ringIndex) * 60.0))
            let ringCapacity = ringCapacities[ringIndex]

            let remainingItems = visibleItemsCount - itemIndex
            let itemsInThisRing = min(remainingItems, ringCapacity)
            if itemsInThisRing <= 0 { break }

            for i in 0..<itemsInThisRing {
                let itemView = floatingItemViews[itemIndex + i]
                guard !itemView.isHidden else { continue }

                let angleOffset = (Double(i) * 2.0 * Double.pi) / Double(itemsInThisRing)
                let ringSpeedMultiplier = 1.0 + (Double(ringIndex) * 0.1)
                let currentAngle = (itemAngle * ringSpeedMultiplier) + angleOffset

                let centerX = contentContainer.bounds.midX
                let centerY = bierdopCenterY

                let x = centerX + ringRadius * cos(currentAngle)
                let y = centerY + ringRadius * sin(currentAngle)

                itemView.center = CGPoint(x: x, y: y)

                let individualRotation = itemRotationAngle + itemRotationOffsets[itemIndex + i]
                itemView.transform = CGAffineTransform(rotationAngle: CGFloat(individualRotation))
            }

            itemIndex += itemsInThisRing
        }
    }

    func updateFloatingItemsVisibility() {
        let totalItems = getTotalItemCount()

        if totalItems == 0 {
            floatingItemViews.forEach { $0.isHidden = true }
            floatingItemOrder = []
            return
        }

        let totalFloatingItems = min(totalItems, getTotalMaxFloatingItems())
        var itemsToShow: [String] = []

        for item in shopItems where item.count > 0 {
            let idealSlots = Double(item.count) / Double(totalItems) * Double(totalFloatingItems)
            let actualSlots = min(item.count, max(1, Int(round(idealSlots))))
            itemsToShow += Array(repeating: item.imageName, count: actualSlots)
        }

        if itemsToShow.count > totalFloatingItems {
            itemsToShow = Array(itemsToShow.prefix(totalFloatingItems))
        }

        itemsToShow.shuffle()
        floatingItemOrder = itemsToShow

        for i in 0..<floatingItemOrder.count {
            floatingItemViews[i].image = UIImage(named: floatingItemOrder[i])
            floatingItemViews[i].isHidden = false
        }

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

    func setupBounceAnimation() {
        bounceTimer = Timer.scheduledTimer(
            timeInterval: 0.016,
            target: self,
            selector: #selector(updateBounceAnimation),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func updateBounceAnimation() {
        bouncePhase += 0.04
        let bounceHeight: CGFloat = 5.0
        let bounceOffset = sin(bouncePhase) * bounceHeight

        var center = imageView.center
        center.y = bierdopCenterY - bounceOffset
        imageView.center = center
    }

    func setupRingCapacities() {
        ringCapacities = []
        let baseCapacity = 12

        for ringIndex in 0..<deviceConfig.maxRings {
            let capacity: Int
            if ringIndex == 0 {
                capacity = baseCapacity
            } else {
                let previousCapacity = ringCapacities[ringIndex - 1]
                capacity = Int(Double(previousCapacity) * 1.54)
            }
            ringCapacities.append(capacity)
        }

        print("Ring capacities calculated: \(ringCapacities)")
    }

    func getTotalMaxFloatingItems() -> Int {
        ringCapacities.reduce(0, +)
    }
}
