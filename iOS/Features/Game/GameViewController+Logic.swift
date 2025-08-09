//
//  GameViewController+Logic.swift
//  Cheesery iOS
//
//  Created by Menno Spijker on 07/08/2025.
//

import UIKit

extension GameViewController {

    func setupTimer() {
        gameTimer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(updateGame),
            userInfo: nil,
            repeats: true
        )
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        bierCount += 1
        updateUI()
        increaseRotationSpeed()

        imageView.layer.removeAllAnimations()
        imageView.transform = .identity

        UIView.animate(withDuration: 0.01, animations: {
            self.imageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }, completion: { _ in
            UIView.animate(withDuration: 0.01) {
                self.imageView.transform = .identity
            }
        })
    }

    @objc func updateGame() {
        let totalProduction = getTotalProductionRate()
        if totalProduction > 0 {
            let increment = totalProduction * 0.1 // 0.1 second interval
            bierCount += increment
            updateUI()
        }
    }

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

    func getTotalProductionRate() -> Double {
        shopItems.reduce(0) { total, item in
            total + (Double(item.count) * item.productionRate)
        }
    }

    func getTotalItemCount() -> Int {
        shopItems.reduce(0) { total, item in
            total + item.count
        }
    }
}
