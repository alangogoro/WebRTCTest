//
//  SocketManager+WebRTC.swift
//  WebRTCex
//
//  Created by usr on 2021/10/1.
//

import Foundation
import WebRTC

extension SocketManager {
    
    func send(sdp rtcSdp: RTCSessionDescription, action: String, toUserId: String) {
        let offerAnswerValue = OfferAnswerModel(action: action,
                                                user_id: userId,
                                                to_userid: toUserId,
                                                info: rtcSdp.sdp)
        do {
            let encodedValue = try encoder.encode(offerAnswerValue)
            let json = try JSONSerialization.jsonObject(with: encodedValue, options: [])
            webSocket.send(json: json) { result in
                if result != nil {
                    // debugPrint("send rtcSdp result = \(String(describing: result))")
                } else {
                    // debugPrint("send XXX")
                }
            }
        }
        catch {
            // debugPrint("Warning: Could not encode sdp: \(error)")
        }
    }
    
}
