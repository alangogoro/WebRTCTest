//
//  WebSocketManager.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import Foundation

final class SocketManager {
    
    private let userId: String
    private let userName: String
    private let webSocket: StarscreamSingleton
    weak var delegate: SocketDelegate?
    
    private var linkId: Int?
    private var iceServers: [IceServer]?
    private(set) var isSocketConnected: Bool = false
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private var pingTimer = Timer()
    
    init(webSocket: StarscreamSingleton, userId: String, userName: String? = "") {
        self.userId = userId
        self.webSocket = webSocket
        self.userName = userName ?? ""
    }
    
    func connect() {
        webSocket.delegate = self
        webSocket.connect()
    }
    
    func disconnect() {
        isSocketConnected = false
        stopPing()
        webSocket.disconnect()
    }
    
    private func bind(bindModel: BindUserModel) {
        let action = SocketType.bind.rawValue
        let bindValue = BindUserModel(action: action,
                                      user_id: bindModel.user_id, user_name: bindModel.user_name,
                                      link_id: bindModel.link_id,
                                      to_userid: bindModel.to_userid)
        do {
            let encodedValue = try self.encoder.encode(bindValue)
            let json = try JSONSerialization.jsonObject(with: encodedValue, options: [])
            webSocket.bindUser(json: json) { result in
                /* if let result = result {
                    debugPrint("bindUser result: \(result)")
                } */
            }
        } catch {
            debugPrint("⚠️ Binding could not encode candidate: \(error)")
        }

    }
    
    private func startPing() {
        DispatchQueue.main.async {
            self.pingTimer =
                Timer.scheduledTimer(timeInterval: 13, target: self,
                                     selector: #selector(self.ping), userInfo: nil,
                                     repeats: true)
        }
    }
    
    private func stopPing() {
        pingTimer.invalidate()
    }
    
    @objc private func ping() {
        let sendValue: [String: String] = ["action": "ping",
                                           "link_id": "\(String(describing: linkId))"]
        do {
            let encodedValue = try encoder.encode(sendValue)
            let json = try JSONSerialization.jsonObject(with: encodedValue, options: [])
            webSocket.send(json: json) { result in
                if result != nil {
                    //
                }
            }
        } catch {
            debugPrint("⚠️ ping could not encode candidate: \(error)")
        }
    }
    
}

extension SocketManager: StarscreamDelegate {
    
    func didConnect(_ webSocket: StarscreamWebSocket) {
        isSocketConnected = true
        delegate?.didConnect(self)
    }
    
    func didDisconnect(_ webSocket: StarscreamWebSocket) {
        isSocketConnected = false
        delegate?.didDisconnect(self)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(3)) {
            debugPrint("Trying to reconnect to signal server...")
            self.webSocket.connect()
        }
    }
    
    func starscream(_ webSocket: StarscreamWebSocket, didReceiveMessage message: [ReceivedMessageModel]) {
        guard let action = message[0].action else { return }
        switch action {
        case SocketType.link.rawValue:
            if let iceServers = message[0].iceserver_config?.iceServers {
                self.iceServers = iceServers
                // UserDefaults save isSocketLinkOn
                self.delegate?.didLinkOn(self, iceServers: iceServers)
            }
            
            guard let linkId = message[0].link_id else { return }
            self.linkId = linkId
            self.bind(bindModel: BindUserModel(action: action,
                                               user_id: self.userId, user_name: self.userName,
                                               link_id: linkId,
                                               to_userid: "-1"))
                                               //to_userid: Constants.Ids.User_Id_She))
        case SocketType.bind.rawValue:
            isSocketConnected = true
            // UserDefaults save isSocketConnect
            guard let linkId = message[0].link_id else { return }
            self.delegate?.didBind(self, linkId: linkId)
            
            startPing()
        case SocketType.say.rawValue:
            self.delegate?.didReceivcMessage(self, messageData: message[0])
        case SocketType.ping.rawValue:
            return
        default:
            return
        }
    }
    
    func starscream(_ webSocket: StarscreamWebSocket, didReceiveError error: Error) {
        
    }
    
}
