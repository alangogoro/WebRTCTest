//
//  Authorization.swift
//  WebRTCex
//
//  Created by usr on 2021/10/1.
//

import Foundation
import UIKit
import AVFoundation

class Authorization {
    
    static let shared = Authorization()
    
    func authorizationForMic(_ viewController: UIViewController) -> Bool {
        let permission = AVAudioSession.sharedInstance().recordPermission
        switch permission {
        case .undetermined:
            //first time
            var allow = false
            let requestPermission = AVAudioSession.sharedInstance()
            requestPermission.requestRecordPermission { allowed in
                if allowed {
                    allow = true
                } else {
                    DispatchQueue.main.async {
                        self.alertForAuthorize(viewController: viewController,
                                               title: "麥克風使用權限受限",
                                               message: " \n點擊『設置』，允許使用您的麥克風")
                    }
                    allow = false
                }
            }
            return allow
        case .granted:
            return true
        case .denied:
            DispatchQueue.main.async {
                self.alertForAuthorize(viewController: viewController,
                                       title: "麥克風使用權限受限",
                                       message: " \n點擊『設置』，允許使用您的麥克風")
            }
        default:
            DispatchQueue.main.async {
                self.alertForAuthorize(viewController: viewController,
                                       title: "麥克風使用權限受限",
                                       message: " \n點擊『設置』，允許使用您的麥克風")
            }
        }
        return false
    }
    
    private func alertForAuthorize(viewController: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title:"取消", style: .cancel, handler:nil)
        let settings = UIAlertAction(title:"設置", style: .default, handler: { (action) -> Void in
            let url = URL(string: UIApplication.openSettingsURLString)
            if let url = url, UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url, options: [ : ],
                                              completionHandler: { success in
                                                
                                              })
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        })
        alert.addAction(cancel)
        alert.addAction(settings)
        viewController.present(alert, animated: true, completion: nil)
    }
    
}
