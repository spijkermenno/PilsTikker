//
//  GameViewController+Notification.swift
//  Cheesery iOS
//
//  Created by Menno Spijker on 07/08/2025.
//

import UIKit

extension GameViewController {

    func showShopNotification(message: String, duration: TimeInterval = 5.0) {
        let horizontalPadding: CGFloat = 20
        let bottomPadding: CGFloat = 20
        let rightInnerPadding: CGFloat = shopButton.bounds.height

        let bannerHeight = shopButton.bounds.height
        let bannerWidth = contentContainer.bounds.width - 2 * horizontalPadding
        let finalX = horizontalPadding
        let finalY = contentContainer.bounds.height - bannerHeight - bottomPadding

        // Start at shopButton position (same Y as final)
        let startFrame = CGRect(
            x: shopButton.frame.origin.x,
            y: finalY,
            width: shopButton.frame.width,
            height: bannerHeight
        )

        let banner = UIView(frame: startFrame)
        banner.backgroundColor = shopButton.backgroundColor?.withAlphaComponent(0.75)
        banner.layer.cornerRadius = shopButton.layer.cornerRadius
        banner.clipsToBounds = true
        banner.alpha = 1.0

        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.numberOfLines = 2
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(label)

        contentContainer.addSubview(banner)
        contentContainer.bringSubviewToFront(banner)
        contentContainer.bringSubviewToFront(shopButton)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -rightInnerPadding),
            label.centerYAnchor.constraint(equalTo: banner.centerYAnchor)
        ])

        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.success)

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            banner.frame = CGRect(x: finalX, y: finalY, width: bannerWidth, height: bannerHeight)
        }, completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                UIView.animate(withDuration: 0.3, animations: {
                    banner.frame = startFrame
                }, completion: { _ in
                    banner.removeFromSuperview()
                })
            }
        })
    }
}
