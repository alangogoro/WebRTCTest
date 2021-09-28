//
//  StarscreamSingleton.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import Foundation
import Starscream

class StarscreamSingleton: StarscreamWebSocket {
    
    private let webSocket: WebSocket
    var delegate: StarscreamDelegate?
    
    init(url: URL) {
        let request = URLRequest(url: url)
        self.webSocket = WebSocket(request: request)
        self.webSocket.delegate = self
    }
    
    func connect() {
        debugPrint("Starscream connected")
        webSocket.connect()
    }
    
    func disconnect() {
        webSocket.disconnect()
    }
    
    func bindUser(json: Any, onSuccess: @escaping (String?) -> ()) {
        guard JSONSerialization.isValidJSONObject(json) else {
            debugPrint("[WEBSOCKET] bindUser value is not a valid JSON object.\n\(json)")
            return
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            webSocket.write(data: data) {
                onSuccess("Success")
            }
        } catch let error {
            debugPrint("[WEBSOCKET] bindUser error when serializing JSON:\n\(error)")
        }
    }
    
    func send(json: Any, onSuccess: @escaping (String?) -> ()) {
        guard JSONSerialization.isValidJSONObject(json) else {
            debugPrint("[WEBSOCKET] send Value is not a valid JSON object.\n\(json)")
            return
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            webSocket.write(data: data) {
                onSuccess("Success")
            }
        } catch let error {
            debugPrint("[WEBSOCKET] send error when serializing JSON:\n\(error)")
        }
    }
    
}

extension StarscreamSingleton: WebSocketDelegate {
    
    func didReceive(event: WebSocketEvent,
                    client: WebSocket) {
        switch event {
        case .connected(let headers):
            debugPrint("Starscream is connected: \(headers)")
            self.delegate?.didConnect(self)
        case .disconnected(let reason, let code):
            debugPrint("Starscream is disconnected: \(reason) with code: \(code)")
            self.delegate?.didDisconnect(self)
            
        case .text(let text):
            if let data = text.data(using: String.Encoding.utf8) {
                guard let message: [ReceivedMessageModel] =
                        data.parseToType([ReceivedMessageModel]()) else { return }
                self.delegate?.starscream(self, didReceiveMessage: message)
            }
            
        case .binary(let data):
            debugPrint("Starscream received data: \(data)")
            break
        case .pong(_):
            break
        case .ping(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            debugPrint("Starscream cancelled")
        case .error(let error):
            debugPrint("Starscream error: \(error!.localizedDescription)")
            self.delegate?.starscream(self, didReceiveError: error!)
        }
    }
    
}
