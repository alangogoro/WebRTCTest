//
//  UIColor+Extension.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import Foundation
import UIKit
import WebRTC

extension UIColor {
    convenience init(_ red : CGFloat, _ green : CGFloat, _ blue : CGFloat) {
        let red = red / 255.0
        let green = green / 255.0
        let blue = blue / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}

extension RTCIceGatheringState {
    var description: String {
        switch self {
        case .new:
            return "New"
        case .gathering:
            return "Gathering"
        case .complete:
            return "Complete"
        default:
            return "Unknown"
        }
    }
}

extension RTCIceConnectionState {
    var description: String {
        switch self {
        case .new:
            return "New"
        case .checking:
            return "Checking"
        case .connected:
            return "Connected"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .disconnected:
            return "Disconnected"
        case .closed:
            return "Closed"
        case .count:
            return "Count"
        default:
            return "Unknown"
        }
    }
}

extension RTCSignalingState {
    var description: String {
        switch self {
        case .stable:
            return "Stable"
        case .haveLocalOffer:
            return "have Local Offer"
        case .haveLocalPrAnswer:
            return "have Local PrAnswer"
        case .haveRemoteOffer:
            return "have Remote Offer"
        case .haveRemotePrAnswer:
            return "have Remote PrAnswer"
        case .closed:
            return "Closed"
        default:
            return "Closed"
        }
    }
}
