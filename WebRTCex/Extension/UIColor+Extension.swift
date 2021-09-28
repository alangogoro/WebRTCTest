//
//  UIColor+Extension.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import Foundation
import UIKit

extension UIColor {
    
    convenience init(_ red : CGFloat, _ green : CGFloat, _ blue : CGFloat) {
        let red = red / 255.0
        let green = green / 255.0
        let blue = blue / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
    
}
