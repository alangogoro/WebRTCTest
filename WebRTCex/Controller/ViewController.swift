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
    let userId = Constants.Ids.User_Id_He
    var linkId = 0
    var toUserId: String? = Constants.Ids.User_Id_She
    var iceServers: [IceServer]?
    //var isSocketConnected = false
    
    private var chats = [Chat]()
    
    private var timer: Timer?
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        
        connectSocket(userId: userId)
        addObservers()
        
    }
    
    @objc func didEnterBackground() {
        if socketManager != nil /* && checkIsCalling() */ {
            socketManager!.disconnect()
        }
    }
    
    @objc func willResignActive() {
        print("-- App willResignActive")
    }
    
    @objc func willEnterForeground() {
        if socketManager != nil /* && checkIsCalling() */ {
            if !socketManager!.isSocketConnected /* checkIsSocketLinkOn() */ {
                socketManager!.connect()
            }
        }
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
    }
    
    @objc func willTerminate() {
        print("-- App willTerminate")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    private func addObservers() {
        // App 進入後台（背景）
        NotificationCenter.default
                          .addObserver(self,
                                       selector: #selector(didEnterBackground),
                                       name: UIApplication.didEnterBackgroundNotification,
                                       object: nil)
        // App 將失去焦點
        NotificationCenter.default
                          .addObserver(self,
                                       selector: #selector(willResignActive),
                                       name: UIApplication.willResignActiveNotification,
                                       object: nil)
        // App 回到前台
        NotificationCenter.default
                          .addObserver(self,
                                       selector: #selector(willEnterForeground),
                                       name: UIApplication.willEnterForegroundNotification,
                                       object: nil)
        // App 即將關閉
        NotificationCenter.default
                          .addObserver(self,
                                       selector: #selector(willTerminate),
                                       name: UIApplication.willTerminateNotification,
                                       object: nil)
    }
    
    private func configureUI() {
        navigationItem.title = "Real-Time Communications"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        view.backgroundColor = UIColor.systemBackground
    }
    
    private func sendMessages() {
        timer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            self?.send("")
        }
    }
    
    @objc private func send(_ text: String) {
        guard let toUserId = toUserId else { return }
        let messageModel = SendMessageModel(action: SocketType.say.rawValue,
                                            user_id: userId,
                                            user_name: "",
                                            to_userid: toUserId,
                                            content: text)
        self.socketManager?.sendMessage(message: messageModel, onSuccess: { result in
            // debugPrint("send result = ", result ?? "Failed")
        })
    }
    
}

// MARK: - SocketDelegate
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
        
        self.sendMessages()
//        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
//            self.socketManager?.disconnect()
//        }
        
        //connectWebRTC()
    }
    
    func didReceivcMessage(_ socket: SocketManager, message: ReceivedMessageModel) {
        guard let id = message.to_userid else { return }
        guard let time = message.time else { return }
        guard let text = message.content else { return }
        
        if id == self.userId {
            self.chats.append(Chat(text: text,
                                   time: time,
                                   placePosition: .right))
            //self.reloadChatsToBottom()
        } else {
            self.chats.append(Chat(text: text,
                                   time: time,
                                   placePosition: .left))
            //self.reloadChatsToBottom()
        }
        debugPrint("SocketManager didReceive Message:", text, time)
    }
    
}
