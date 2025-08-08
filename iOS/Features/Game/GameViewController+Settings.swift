//
//  GameViewController+Settings.swift
//  Tap the Cap iOS
//
//  Created by Menno Spijker on 07/08/2025.
//

import UIKit

extension GameViewController {

    func setupSettingsUI() {
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
        settingsView.backgroundColor = UIColor.black.withAlphaComponent(0.75)

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(toggleSettings), for: .touchUpInside)
        settingsView.addSubview(closeButton)

        closeButton.backgroundColor = UIColor.gray
        closeButton.layer.cornerRadius = 20

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: settingsView.safeAreaLayoutGuide.topAnchor, constant: 0),
            closeButton.trailingAnchor.constraint(equalTo: settingsView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        let titleLabel = UILabel()
        titleLabel.text = Localized.settingsTitle
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: settingsView.trailingAnchor, constant: -20)
        ])

        let divider1 = UIView()
        divider1.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        divider1.translatesAutoresizingMaskIntoConstraints = false
        settingsView.addSubview(divider1)

        NSLayoutConstraint.activate([
            divider1.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            divider1.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor, constant: 20),
            divider1.trailingAnchor.constraint(equalTo: settingsView.trailingAnchor, constant: -20),
            divider1.heightAnchor.constraint(equalToConstant: 1)
        ])

#if DEBUG
        let deviceInfoLabel = UILabel()
        deviceInfoLabel.text = Localized.deviceTitle
        deviceInfoLabel.font = UIFont.boldSystemFont(ofSize: 18)
        deviceInfoLabel.textColor = .white
        deviceInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsView.addSubview(deviceInfoLabel)

        let deviceTypeLabel = UILabel()
        deviceTypeLabel.text = Localized.deviceType(deviceConfig.deviceType)
        deviceTypeLabel.font = UIFont.systemFont(ofSize: 14)
        deviceTypeLabel.textColor = .white
        deviceTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsView.addSubview(deviceTypeLabel)

        let ringsLabel = UILabel()
        ringsLabel.text = Localized.deviceRings(deviceConfig.maxRings, getTotalMaxFloatingItems())
        ringsLabel.font = UIFont.systemFont(ofSize: 14)
        ringsLabel.textColor = .white
        ringsLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsView.addSubview(ringsLabel)

        NSLayoutConstraint.activate([
            deviceInfoLabel.topAnchor.constraint(equalTo: divider1.bottomAnchor, constant: 20),
            deviceInfoLabel.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor, constant: 20),

            deviceTypeLabel.topAnchor.constraint(equalTo: deviceInfoLabel.bottomAnchor, constant: 10),
            deviceTypeLabel.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor, constant: 20),

            ringsLabel.topAnchor.constraint(equalTo: deviceTypeLabel.bottomAnchor, constant: 5),
            ringsLabel.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor, constant: 20)
        ])
#endif
        let appInfoLabel = UILabel()
        appInfoLabel.text = Localized.appTitle
        appInfoLabel.font = UIFont.boldSystemFont(ofSize: 18)
        appInfoLabel.textColor = .white
        appInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsView.addSubview(appInfoLabel)

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        let versionLabel = UILabel()
        versionLabel.text = Localized.appVersion(version, build)
        versionLabel.font = UIFont.systemFont(ofSize: 14)
        versionLabel.textColor = .white
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsView.addSubview(versionLabel)

        let devLabel = UILabel()
        devLabel.text = Localized.developer
        devLabel.font = UIFont.systemFont(ofSize: 14)
        devLabel.textColor = .white
        devLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsView.addSubview(devLabel)

        let descriptionLabel = UILabel()
        descriptionLabel.text = Localized.appDescription
        descriptionLabel.font = UIFont.systemFont(ofSize: 12)
        descriptionLabel.textColor = .white
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsView.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            appInfoLabel.topAnchor.constraint(equalTo: ringsLabel.bottomAnchor, constant: 20),
            appInfoLabel.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor, constant: 20),

            versionLabel.topAnchor.constraint(equalTo: appInfoLabel.bottomAnchor, constant: 10),
            versionLabel.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor, constant: 20),

            devLabel.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 5),
            devLabel.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor, constant: 20),

            descriptionLabel.topAnchor.constraint(equalTo: devLabel.bottomAnchor, constant: 15),
            descriptionLabel.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: settingsView.trailingAnchor, constant: -20)
        ])

        let divider2 = UIView()
        divider2.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        divider2.translatesAutoresizingMaskIntoConstraints = false
        settingsView.addSubview(divider2)

        NSLayoutConstraint.activate([
            divider2.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            divider2.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor, constant: 20),
            divider2.trailingAnchor.constraint(equalTo: settingsView.trailingAnchor, constant: -20),
            divider2.heightAnchor.constraint(equalToConstant: 1)
        ])

        let gameActionsLabel = UILabel()
        gameActionsLabel.text = Localized.gameActionsTitle
        gameActionsLabel.font = UIFont.boldSystemFont(ofSize: 18)
        gameActionsLabel.textColor = .white
        gameActionsLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsView.addSubview(gameActionsLabel)

        let resetButton = UIButton(type: .system)
        resetButton.setTitle(Localized.resetButton, for: .normal)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.backgroundColor = .red
        resetButton.layer.cornerRadius = 8
        resetButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.addTarget(self, action: #selector(resetGameFromSettings), for: .touchUpInside)
        settingsView.addSubview(resetButton)

        let warningLabel = UILabel()
        warningLabel.text = Localized.resetWarning
        warningLabel.font = UIFont.systemFont(ofSize: 12)
        warningLabel.textColor = .red
        warningLabel.textAlignment = .center
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsView.addSubview(warningLabel)

        let creditsLabel = UILabel()
        creditsLabel.text = Localized.credits
        creditsLabel.font = UIFont.systemFont(ofSize: 12)
        creditsLabel.textColor = .white
        creditsLabel.textAlignment = .center
        creditsLabel.numberOfLines = 0
        creditsLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsView.addSubview(creditsLabel)

        NSLayoutConstraint.activate([
            gameActionsLabel.topAnchor.constraint(equalTo: divider2.bottomAnchor, constant: 20),
            gameActionsLabel.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor, constant: 20),

            resetButton.topAnchor.constraint(equalTo: gameActionsLabel.bottomAnchor, constant: 15),
            resetButton.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor, constant: 20),
            resetButton.trailingAnchor.constraint(equalTo: settingsView.trailingAnchor, constant: -20),
            resetButton.heightAnchor.constraint(equalToConstant: 44),

            warningLabel.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: 5),
            warningLabel.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor, constant: 20),
            warningLabel.trailingAnchor.constraint(equalTo: settingsView.trailingAnchor, constant: -20),

            creditsLabel.bottomAnchor.constraint(equalTo: settingsView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            creditsLabel.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor, constant: 20),
            creditsLabel.trailingAnchor.constraint(equalTo: settingsView.trailingAnchor, constant: -20)
        ])
    }

    @objc func toggleSettings() {
        isSettingsOpen.toggle()

        if isSettingsOpen {
            settingsView.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.settingsView.alpha = 1.0
            }
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.settingsView.alpha = 0.0
            }, completion: { _ in
                self.settingsView.isHidden = true
            })
        }
    }

    @objc func resetGameFromSettings() {
        let alert = UIAlertController(
            title: Localized.resetConfirmationTitle,
            message: Localized.resetConfirmationMessage,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: Localized.proost, style: .default))
        alert.addAction(UIAlertAction(title: Localized.resetButton, style: .destructive) { _ in
            self.bierCount = 0
            for i in 0..<self.shopItems.count {
                self.shopItems[i].count = 0
            }
            self.saveProgress()
            self.updateUI()
            self.updateFloatingItemsVisibility()
            self.toggleSettings()
        })

        present(alert, animated: true)
    }
}
