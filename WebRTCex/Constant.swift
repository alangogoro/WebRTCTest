//
//  Constant.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import Foundation
import UIKit

struct Constants {
    
    struct Urls {
        static let WebSocket_Official = "wss://chat.horofriend88.com:8185"
        static let WebSocket_Test = "wss://webrtc-voxy.cfd888.info:8186"
    }
    
    struct Ids {
        static let User_Id_He = "AO0ZV8X8RX64"
        //                      "AO0ZV8X8RX64" Girl-Me
        //                      "XVU1NP18MT86" Boy- Josh
        //                      "RDS0H0FE36NE" Girl-Zhiyang
        static let User_Id_She = "RDS0H0FE36NE"
    }
    
}

var screenWidth: CGFloat {
    return UIScreen.main.bounds.width
}

var screenHeight: CGFloat {
    return UIScreen.main.bounds.height
}
