//
//  WebSocketManager.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import Foundation
import WebRTC

final class SocketManager {
    
    let userId: String
    private let userName: String
    let webSocket: StarscreamSingleton
    weak var delegate: SocketDelegate?
    
    private var linkId: Int?
    private var iceServers: [IceServer]?
    private(set) var isSocketConnected: Bool = false
    
    let encoder = JSONEncoder()
    
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
        do {
            let encodedValue = try encoder.encode(data)
            let json = try JSONSerialization.jsonObject(with: encodedValue, options: [])
            webSocket.send(json: json, onSuccess: { result in
                if result != nil {
                    debugPrint("Call Remote result = \(result!)")
                }
            })
        } catch {
            debugPrint("⚠️ callRemote Could not encode candidate: \(error)")
        }
    }
    
    func send(action: String, sdp rtcSdp: RTCSessionDescription, toUserId: String) {
        let offerAnswerValue = OfferAnswerModel(action: action,
                                                user_id: userId,
                                                to_userid: toUserId,
                                                info: rtcSdp.sdp)
        do {
            let encodedValue = try encoder.encode(offerAnswerValue)
            let json = try JSONSerialization.jsonObject(with: encodedValue, options: [])
            debugPrint("json = ", json)
            webSocket.send(json: json) { result in
                if result != nil {
                    debugPrint("send rtcSdp result = \(String(describing: result))")
                } else {
                    debugPrint("sent rtcSdp failed")
                }
            }
        }
        catch {
            debugPrint("⚠️ Could not encode SDP: \(error)")
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
            self.delegate?.didReceiveMessage(self, message: message[0])
        case SocketType.ping.rawValue:
            return
        case SocketType.callRemote.rawValue:
            // CallRemote will not receiveMessage
            return
        case SocketType.callRemote_callBack.rawValue:
            self.delegate?.didReceiveCall(self, message: message[0])
        case SocketType.clientOffer.rawValue:
            // TODO: 沒收到 info（來電方的 SDP）
            if let sdp = message[0].info {
                let rtcSdp = RTCSessionDescription(type: RTCSdpType.offer, sdp: sdp)
                self.delegate?.didReceiveCall(self, receivedRemoteSdp: rtcSdp)
            } else {
                debugPrint("found client_offer SDP info NIL. Message: ", message)
            }
        case SocketType.clientAnswer.rawValue:
            if let sdp = message[0].info {
                let rtcSdp = RTCSessionDescription(type: RTCSdpType.answer, sdp: sdp)
                self.delegate?.didReceiveCall(self, receivedRemoteSdp: rtcSdp)
            }
        default:
            return
        }
    }
    
    func starscream(_ webSocket: StarscreamWebSocket, didReceiveError error: Error) {
        
    }
    
}
