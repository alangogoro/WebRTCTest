//
//  SocketDelegate.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import Foundation

/// **SocketManager** 的回傳
protocol SocketDelegate: AnyObject {
    func didConnect(_ socket: SocketManager)
    func didDisconnect(_ socket: SocketManager)
    func didLinkOn(_ socket: SocketManager, iceServers: [IceServer])
    func didBind(_ socket: SocketManager, linkId: Int)
    func didReceivcMessage(_ socket: SocketManager, message: ReceivedMessageModel)
}

/// StarscreamSingleton 必須處理的內容
protocol StarscreamWebSocket: AnyObject {
    var delegate: StarscreamDelegate? { get set }
    func connect()
    func disconnect()
    func bindUser(json: Any, onSuccess: @escaping (String?) -> ())
    func send(json: Any, onSuccess: @escaping (String?) -> ())
}

/// StarscreamSingleton 的回傳
protocol StarscreamDelegate: AnyObject {
    func didConnect(_ webSocket: StarscreamWebSocket)
    func didDisconnect(_ webSocket: StarscreamWebSocket)
    func starscream(_ webSocket: StarscreamWebSocket, didReceiveMessage message: [ReceivedMessageModel])
    func starscream(_ webSocket: StarscreamWebSocket, didReceiveError error: Error)
}
