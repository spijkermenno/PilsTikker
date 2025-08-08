//
//  GameViewController+Settings.swift
//  Tap the Cap iOS
//
//  Created by Menno Spijker on 07/08/2025.
//

import UIKit

extension GameViewController {

    func setupSettingsUI() {
        // Keep the small gear in the header, but now it opens a new screen.
        let buttonSize: CGFloat = 40
        let padding: CGFloat = 16

        settingsButton = UIButton(type: .system)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.backgroundColor = UIColor.brown.withAlphaComponent(0.8)
        settingsButton.layer.cornerRadius = buttonSize / 2
        settingsButton.setImage(UIImage(systemName: "gear"), for: .normal)
        settingsButton.tintColor = .white
        settingsButton.addTarget(self, action: #selector(openSettingsScreen), for: .touchUpInside)
        headerContainer.addSubview(settingsButton)

        NSLayoutConstraint.activate([
            settingsButton.centerYAnchor.constraint(equalTo: perSecondLabel.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -padding),
            settingsButton.widthAnchor.constraint(equalToConstant: buttonSize),
            settingsButton.heightAnchor.constraint(equalToConstant: buttonSize),
        ])
    }

    @objc private func openSettingsScreen() {
        let vc = SettingsViewController(
            deviceConfig: deviceConfig,
            totalFloatingItemsProvider: { [weak self] in self?.getTotalMaxFloatingItems() ?? 0 },
            onReset: { [weak self] in
                self?.performReset()
            }
        )

        // Present modally with a navigation bar for a native “Close” button.
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func performReset() {
        // Reset game state (moved out of the old overlay implementation)
        self.bierCount = 0
        for i in 0..<self.shopItems.count {
            self.shopItems[i].count = 0
        }
        self.saveProgress()
        self.updateUI()
        self.updateFloatingItemsVisibility()

        // Dismiss settings after reset
        self.presentedViewController?.dismiss(animated: true)
    }
}
