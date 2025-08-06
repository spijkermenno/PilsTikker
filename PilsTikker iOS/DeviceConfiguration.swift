//
//  DeviceConfiguration.swift
//  PilsTikker iOS
//
//  Created by Menno Spijker on 06/08/2025.
//

import UIKit

// MARK: - Device-Based Configuration

struct DeviceConfiguration {
    let deviceType: String
    let maxRings: Int
    let bierdopScale: CGFloat
    let baseRadius: Double
    let itemsPerInnerRing: Int
    let itemsPerOuterRing: Int
    let shopScale: CGFloat
}

func getDeviceConfiguration() -> DeviceConfiguration {
    let screen = UIScreen.main.bounds
    let screenWidth = min(screen.width, screen.height) // Use the smaller dimension
    let screenHeight = max(screen.width, screen.height) // Use the larger dimension
    let diagonal = sqrt(screenWidth * screenWidth + screenHeight * screenHeight)
    
    switch UIDevice.current.userInterfaceIdiom {
    case .phone:
        // iPhone - small screens, limited space
        if diagonal < 600 { // iPhone SE, iPhone 8 and smaller
            return DeviceConfiguration(
                deviceType: "iPhone Small",
                maxRings: 2,
                bierdopScale: 1.0,
                baseRadius: 90,
                itemsPerInnerRing: 8,
                itemsPerOuterRing: 12,
                shopScale: 1.0
            )
        } else if diagonal < 700 { // iPhone 12, 13, 14 standard
            return DeviceConfiguration(
                deviceType: "iPhone Standard",
                maxRings: 2,
                bierdopScale: 1.0,
                baseRadius: 110,
                itemsPerInnerRing: 12,
                itemsPerOuterRing: 18,
                shopScale: 1.0
            )
        } else { // iPhone Plus/Max models
            return DeviceConfiguration(
                deviceType: "iPhone Large",
                maxRings: 3,
                bierdopScale: 1.1,
                baseRadius: 120,
                itemsPerInnerRing: 12,
                itemsPerOuterRing: 18,
                shopScale: 1.1
            )
        }
        
    case .pad:
        if diagonal < 1100 { // iPad mini
            return DeviceConfiguration(
                deviceType: "iPad Mini",
                maxRings: 3,
                bierdopScale: 1.3,
                baseRadius: 140,
                itemsPerInnerRing: 12,
                itemsPerOuterRing: 18,
                shopScale: 1.2
            )
        } else if diagonal < 1300 { // iPad Air, iPad Pro 11"
            return DeviceConfiguration(
                deviceType: "iPad Standard",
                maxRings: 4,
                bierdopScale: 1.5,
                baseRadius: 160,
                itemsPerInnerRing: 15,
                itemsPerOuterRing: 22,
                shopScale: 1.4
            )
        } else { // iPad Pro 12.9"
            return DeviceConfiguration(
                deviceType: "iPad Large",
                maxRings: 5,
                bierdopScale: 1.5,
                baseRadius: 180,
                itemsPerInnerRing: 18,
                itemsPerOuterRing: 25,
                shopScale: 1.6
            )
        }
        
    case .mac:
        return DeviceConfiguration(
            deviceType: "Mac",
            maxRings: 5,
            bierdopScale: 1.5,
            baseRadius: 200,
            itemsPerInnerRing: 20,
            itemsPerOuterRing: 28,
            shopScale: 1.8
        )
        
    default:
        return DeviceConfiguration(
            deviceType: "Unknown",
            maxRings: 2,
            bierdopScale: 1.0,
            baseRadius: 110,
            itemsPerInnerRing: 12,
            itemsPerOuterRing: 18,
            shopScale: 1.0
        )
    }
}
