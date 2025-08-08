//
//  GradientView.swift
//  Tap the Cap iOS
//
//  Created by Menno Spijker on 07/08/2025.
//

import UIKit

class GradientView: UIView {

    private var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Configure the existing gradient layer
        gradientLayer.frame = bounds
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.5).cgColor, // bottom (opaque)
            UIColor.clear.cgColor                         // top (transparent)
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0) // bottom
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)   // top
    }
}
