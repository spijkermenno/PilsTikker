//
//  SplashViewController.swift
//  Cheesery iOS
//
//  Created by Menno Spijker on 07/08/2025.
//

import UIKit

class SplashViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        print("[Splash] View did load")

        // Background image
        let backgroundImage = UIImage(named: "Splashscreen")
        let backgroundImageView = UIImageView(image: backgroundImage)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Container background for disclaimer
        let disclaimerContainer = UIView()
        disclaimerContainer.translatesAutoresizingMaskIntoConstraints = false
        disclaimerContainer.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(disclaimerContainer)

        // Disclaimer label
        let disclaimerLabel = UILabel()
        disclaimerLabel.translatesAutoresizingMaskIntoConstraints = false
        disclaimerLabel.text = NSLocalizedString("splash.disclaimer", comment: "Splash screen disclaimer")
        disclaimerLabel.font = UIFont.systemFont(ofSize: 18, weight: .black)
        disclaimerLabel.textColor = .white
        disclaimerLabel.numberOfLines = 0
        disclaimerLabel.textAlignment = .center
        disclaimerContainer.addSubview(disclaimerLabel)

        // Spinner
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        view.addSubview(spinner)

        // Spinner constraints (centered)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Constraints for container
        NSLayoutConstraint.activate([
            disclaimerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            disclaimerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            disclaimerContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Constraints for label inside container (padding)
        NSLayoutConstraint.activate([
            disclaimerLabel.topAnchor.constraint(equalTo: disclaimerContainer.topAnchor, constant: 32),
            disclaimerLabel.bottomAnchor.constraint(equalTo: disclaimerContainer.bottomAnchor, constant: -32),
            disclaimerLabel.leadingAnchor.constraint(equalTo: disclaimerContainer.leadingAnchor, constant: 32),
            disclaimerLabel.trailingAnchor.constraint(equalTo: disclaimerContainer.trailingAnchor, constant: -32)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        print("[Splash] View did appear")

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            print("[Splash] Launching GameViewController")
            let gameVC = GameViewController()
            gameVC.modalTransitionStyle = .crossDissolve
            gameVC.modalPresentationStyle = .fullScreen
            self.present(gameVC, animated: true)
        }
    }
}
