//
//  SocketEnum.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import Foundation

enum SocketType: String {
    case link = "link_on"
    case bind = "bind"
    case say = "say"
    case ping = "ping"
    case callRemote = "call_remote"
    case callRemote_callBack = "call_remote_callback"
    
    case clientOffer = "client_offer"
    case clientAnswer = "client_answer"
    /*
     case ClientCandidate = "client_candidate"
     case CancelPhone = "cancel_phone"
     case ReadComplete = "read_complete"
     case CheckCalling = "check_calling"
     */
}
