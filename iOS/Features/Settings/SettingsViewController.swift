//
//  SettingsViewController.swift
//  Cheesery iOS
//
//  Created by Menno Spijker on 08/08/2025.
//

import UIKit

final class SettingsViewController: UIViewController {

    // Dependencies
    private let deviceConfig: DeviceConfiguration
    private let totalFloatingItemsProvider: () -> Int
    private let onReset: () -> Void

    // UI
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    init(deviceConfig: DeviceConfiguration,
         totalFloatingItemsProvider: @escaping () -> Int,
         onReset: @escaping () -> Void) {
        self.deviceConfig = deviceConfig
        self.totalFloatingItemsProvider = totalFloatingItemsProvider
        self.onReset = onReset
        super.init(nibName: nil, bundle: nil)
        self.title = Localized.settingsTitle
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Dynamic system colors for proper light/dark mode
        view.backgroundColor = .systemBackground

        // Native nav bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .separator
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .label
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        // If presented modally (no back arrow), show Close
        if navigationController?.viewControllers.first === self {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                systemItem: .close,
                primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
            )
        }

        // Scroll + stack
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])

#if DEBUG
        stack.addArrangedSubview(makeSectionTitle(Localized.deviceTitle))
        stack.addArrangedSubview(makeLabel(Localized.deviceType(deviceConfig.deviceType)))
        stack.addArrangedSubview(makeLabel(
            Localized.deviceRings(deviceConfig.maxRings, totalFloatingItemsProvider())
        ))
        stack.addArrangedSubview(makeDivider())
#endif

        stack.addArrangedSubview(makeSectionTitle(Localized.appTitle))

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        stack.addArrangedSubview(makeLabel(Localized.appVersion(version, build)))
        stack.addArrangedSubview(makeLabel(Localized.developer))
        stack.addArrangedSubview(makeMultilineLabel(Localized.appDescription))

        stack.addArrangedSubview(makeDivider())

        stack.addArrangedSubview(makeSectionTitle(Localized.gameActionsTitle))
        stack.addArrangedSubview(makeResetButton())
        stack.addArrangedSubview(makeWarningLabel(Localized.resetWarning))

        stack.addArrangedSubview(UIView()) // spacer
        stack.addArrangedSubview(makeCenterMultilineLabel(Localized.credits))
    }

    // MARK: - Builders (dynamic colors)

    private func makeSectionTitle(_ text: String) -> UIView {
        let l = UILabel()
        l.text = text
        l.font = UIFont.boldSystemFont(ofSize: 18)
        l.textColor = .label
        return l
    }

    private func makeLabel(_ text: String) -> UIView {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .label
        return l
    }

    private func makeMultilineLabel(_ text: String) -> UIView {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }

    private func makeCenterMultilineLabel(_ text: String) -> UIView {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }

    private func makeWarningLabel(_ text: String) -> UIView {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 12)
        l.textColor = .systemRed
        l.textAlignment = .center
        return l
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
        return v
    }

    private func makeResetButton() -> UIView {
        var config = UIButton.Configuration.filled()
        config.title = Localized.resetButton
        config.baseBackgroundColor = .systemRed
        config.baseForegroundColor = .white
        config.cornerStyle = .medium

        let b = UIButton(configuration: config)
        b.heightAnchor.constraint(equalToConstant: 44).isActive = true
        b.addAction(UIAction { [weak self] _ in
            self?.confirmReset()
        }, for: .touchUpInside)
        return b
    }

    private func confirmReset() {
        let alert = UIAlertController(
            title: Localized.resetConfirmationTitle,
            message: Localized.resetConfirmationMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Localized.proost, style: .cancel))
        alert.addAction(UIAlertAction(title: Localized.resetButton, style: .destructive) { [weak self] _ in
            self?.onReset()
        })
        present(alert, animated: true)
    }
}
