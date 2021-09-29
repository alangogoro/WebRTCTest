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
            debugPrint("[WEBSOCKET] bindUser value is not a valid JSON object. \(json)")
            return
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            webSocket.write(data: data) {
                onSuccess("Success")
            }
        } catch let error {
            debugPrint("[WEBSOCKET] bindUser error when serializing JSON: \(error)")
        }
    }
    
    func send(json: Any, onSuccess: @escaping (String?) -> ()) {
        guard JSONSerialization.isValidJSONObject(json) else {
            debugPrint("[WEBSOCKET] send value is not a valid JSON object. \(json)")
            return
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            webSocket.write(data: data) {
                onSuccess("Success")
            }
        } catch let error {
            debugPrint("[WEBSOCKET] send error when serializing JSON: \(error)")
        }
    }
    
}

extension StarscreamSingleton: WebSocketDelegate {
    
    func didReceive(event: WebSocketEvent,
                    client: WebSocket) {
        switch event {
        case .connected(_):
            // debugPrint("Starscream is connected: \(_)")
            self.delegate?.didConnect(self)
        case .disconnected(let reason, let code):
            debugPrint("Starscream is disconnected: \(reason) with code: \(code)")
            self.delegate?.didDisconnect(self)
            
        case .text(let text):
            if let data = text.data(using: String.Encoding.utf8) {
                guard let message =
                        data.parseToReceivedMessageModel() else {
                    debugPrint("Starscream didReceive text, but failed parsing JSON: ", text)
                    return
                }
                self.delegate?.starscream(self, didReceiveMessage: message)
            }
            
        case .binary(let data):
            debugPrint("Starscream received data: \(data)")
            break
        case .ping(_):
            break
        case .pong(_):
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
