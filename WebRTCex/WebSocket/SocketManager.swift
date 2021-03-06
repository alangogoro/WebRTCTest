//
//  WebSocketManager.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import Foundation
import WebRTC

final class SocketManager {
    
    private let userId: String
    private let userName: String
    private let webSocket: StarscreamSingleton
    weak var delegate: SocketDelegate?
    
    private var linkId: Int?
    private var iceServers: [IceServer]?
    private(set) var isSocketConnected: Bool = false
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
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
                    debugPrint("CallRemote result = \(result!)")
                }
            })
        } catch {
            debugPrint("⚠️ CallRemote could not encode candidate: \(error)")
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
            // debugPrint("json = ", json)
            webSocket.send(json: json) { result in
                if result != nil {
                    debugPrint("🟢 send rtcSdp result = \(result!))")
                } else {
                    debugPrint("sent rtcSdp failed")
                }
            }
        } catch {
            debugPrint("⚠️ Could not encode SDP: \(error)")
        }
    }
    
    func send(candidate rtcIceCandidate: RTCIceCandidate, toUserId: String) {
        let candidateValue = CandidateModel(action: SocketType.clientCandidate.rawValue,
                                            user_id: userId,
                                            // TODO: - ⛔️ 你他媽的忘了餵 to_userid
                                            to_userid: toUserId,
                                            ice_sdp: rtcIceCandidate.sdp,
                                            ice_index: Int(rtcIceCandidate.sdpMLineIndex),
                                            ice_mid: rtcIceCandidate.sdpMid!)
        do {
            let encodedValue = try encoder.encode(candidateValue)
            let json = try JSONSerialization.jsonObject(with: encodedValue, options: [])
            self.webSocket.send(json: json) { result in
                if result != nil {
                    debugPrint("🟢 send rtcIceCandidate result = \(result!))")
                } else {
                    debugPrint("sent rtcIceCandidate failed")
                }
            }
        } catch {
            debugPrint("⚠️ Could not encode Candidate: \(error)")
        }
    }
    
    func endCall(data: CallRemoteModel, onSuccess: @escaping (String?) -> Void) {
        do {
            let encodedValue = try encoder.encode(data)
            let json = try JSONSerialization.jsonObject(with: encodedValue, options: [])
            webSocket.send(json: json, onSuccess: { result in
                if result != nil {
                    debugPrint("End CallRemote result = \(result!)")
                }
            })
        } catch {
            debugPrint("⚠️ End CallRemote could not encode CallRemoteModel: \(error)")
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
            } else {
                debugPrint("found client_answer SDP info NIL. Message: ", message)
            }
        case SocketType.clientCandidate.rawValue:
            // print("sdp:\(message[0].ice_sdp!) sdpMLineIndex:\(message[0].ice_index!) sdpMid:\(message[0].ice_mid!)")
            if message[0].logid != nil { debugPrint("LOGID = \(message[0].logid!)") }
            self.delegate?
                .didReceiveCall(self,
                                receivedCandidate: RTCIceCandidate(sdp: message[0].ice_sdp!,
                                                                   sdpMLineIndex: Int32(message[0].ice_index!),
                                                                   sdpMid: message[0].ice_mid!))
        // NOTE: - didEndCall
        case SocketType.cancelPhone.rawValue:
            self.delegate?.didEndCall(self,
                                      userId: message[0].user_id!,
                                      toUserId: message[0].to_userid!)
        default:
            return
        }
    }
    
    func starscream(_ webSocket: StarscreamWebSocket, didReceiveData data: Data) {
        let message: Message
        do {
            message = try decoder.decode(Message.self, from: data)
        } catch {
            debugPrint("⚠️ Failed to Decode Message from Starscream Data")
            return
        }
        
        switch message {
        case .candidate(let iceCandidate):
            debugPrint("iceCandidate = ", iceCandidate)
            self.delegate?.didReceiveCall(self, receivedCandidate: iceCandidate.rtcIceCandidate)
        case .sdp(let sessionDescription):
            debugPrint("sessionDescription = ", sessionDescription)
            self.delegate?.didReceiveCall(self, receivedRemoteSdp: sessionDescription.rtcSessionDescription)
        }
    }
    
    func starscream(_ webSocket: StarscreamWebSocket, didReceiveError error: Error) {
        
    }
    
}
