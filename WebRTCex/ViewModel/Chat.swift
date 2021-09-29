//
//  Chat.swift
//  WebRTCex
//
//  Created by usr on 2021/9/29.
//

import Foundation

/// 聊天室訊息格式
struct Chat {
    let text: String
    let time: String
    let placePosition: ChatPosition
}

/// 聊天室由誰傳送的訊息
enum ChatPosition {
    case right
    case left
}

