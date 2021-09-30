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
    
    private let encoder = JSONEncoder()
    
    private var pingTimer = Timer()
    private var pingInterval = TimeInterval(Double(13))
    
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
    
    func sendMessage(message: SendMessageModel, onSuccess: @escaping (String?) -> Void) {
        let sendValue = message
        do {
            let encodedValue = try encoder.encode(sendValue)
            let json = try JSONSerialization.jsonObject(with: encodedValue, options: [])
            webSocket.send(json: json) { result in
                if result != nil {
                    onSuccess("sent Succcess")
                }
            }
        } catch {
            debugPrint("⚠️ SendText could not encode candidate: \(error)")
        }
    }
    
    private func startPing() {
        DispatchQueue.main.async {
            self.pingTimer =
                Timer.scheduledTimer(timeInterval: self.pingInterval, target: self,
                                     selector: #selector(self.ping), userInfo: nil,
                                     repeats: true)
        }
    }
    
    private func stopPing() {
        pingTimer.invalidate()
    }
    
    @objc private func ping() {
        let sendValue: [String: String] = ["action": "ping",
                                           "link_id": "\(linkId!)"]
        do {
            let encodedValue = try encoder.encode(sendValue)
            let json = try JSONSerialization.jsonObject(with: encodedValue, options: [])
            webSocket.send(json: json) { result in
                if result != nil {
                    //
                }
            }
        } catch {
            debugPrint("⚠️ Ping could not encode candidate: \(error)")
        }
    }
    
    func callRemote(data: CallRemoteModel) {
        let data_ = ["action": "call_remote",
                     "user_id": "AO0ZV8X8RX64",
                     "user_img": "", //Optional("img/profile_0.jpg"),
                     "user_name": "",//Optional("訪客1"),
                     "to_userid": "XVU1NP18MT86",
                     "used_phone": 1,
                     "media_type": 1,//Optional(1),
                     "user_voice_fee": 1,//Optional(1),
                     "user_text_fee": 1,//Optional(1),
                     "user_video_fee": 1,//Optional(1),
                     "user_age": 1,//Optional(18),
                     "to_user_os_type": 2,//Optional(2),
                     "to_user_token": "",
                     "connection_mode": "0"] as [String: Any] //Optional("0")]
        do {
            let encodedValue = try encoder.encode(data)
            let json = try JSONSerialization.jsonObject(with: encodedValue, options: [])
            webSocket.send(json: json, onSuccess: { result in
                if result != nil {
                    debugPrint("Call Remote result = \(result!)")
                }
                print(data)
            })
        } catch {
            debugPrint("Warning: callRemote Could not encode candidate: \(error)")
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
            debugPrint("[WEBSOCKET] Trying to Reconnect to Signal server...")
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
            self.delegate?.didReceivcMessage(self, message: message[0])
        case SocketType.ping.rawValue:
            return
        case SocketType.callRemote.rawValue:
            // CallRemote will not receiveMessage
            return
        case SocketType.callRemote_callBack.rawValue:
            debugPrint("SocketManager didReceiveMessage - callRemote_callBack !!")
            // self.delegate?.didReceiveCall(self, messageData: message[0])
            break
        default:
            return
        }
    }
    
    func starscream(_ webSocket: StarscreamWebSocket, didReceiveError error: Error) {
        
    }
    
}
