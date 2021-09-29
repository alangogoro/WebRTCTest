//
//  ViewController.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: - Property
    var socketManager: SocketManager?
    var linkId = 0
    var iceServers: [IceServer]?
    //var toUserId: String = ""
    //var isSocketConnected = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        connectSocket(userId: Constants.Ids.User_Id_He)
    }
    
    // MARK: - Helper
    private func connectSocket(userId: String, userName: String? = "") {
        let socketUrl = Constants.Urls.WebSocket_Test
        socketManager = SocketManager(webSocket: StarscreamSingleton(url: URL(string: socketUrl)!),
                                      userId: userId)
        
        //DispatchQueue.main.async {
        guard let socketManager = self.socketManager else { return }
        socketManager.delegate = self
        if !socketManager.isSocketConnected {
            socketManager.connect()
        }
        //}
    }
    
    private func configureUI() {
        navigationItem.title = "Real-Time Communications"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        view.backgroundColor = UIColor.systemBackground
    }

}

extension ViewController: SocketDelegate {
    
    func didConnect(_ socket: SocketManager) {
        
    }
    
    func didDisconnect(_ socket: SocketManager) {
        
    }
    
    func didLinkOn(_ socket: SocketManager, iceServers: [IceServer]) {
        self.iceServers = iceServers
    }
    
    func didBind(_ socket: SocketManager, linkId: Int) {
        debugPrint("SocketManager didBind link_id = \(linkId)")
        self.linkId = linkId
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
//            self.socketManager?.disconnect()
            
        }
        
        //connectWebRTC()
    }
    
    func didReceivcMessage(_ socket: SocketManager, messageData: ReceivedMessageModel) {
        
    }
    
}
