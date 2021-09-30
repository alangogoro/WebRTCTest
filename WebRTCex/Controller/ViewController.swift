//
//  ViewController.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import UIKit
import SnapKit
import SDWebImage

class ViewController: UIViewController {
    
    // MARK: - Property
    var socketManager: SocketManager?
    let userId = Constants.Ids.User_Id_He
    var linkId = 0
    var toUserId: String? = Constants.Ids.User_Id_She
    var iceServers: [IceServer]?
    var isConnected: Bool = false {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.makeCallIcon.image = self.isConnected ? #imageLiteral(resourceName: "call_icon") : #imageLiteral(resourceName: "unable_call_icon")
            }
        }
    }
    var isOnCall: Bool = false {
        didSet {
            onCallGif.isHidden = isOnCall ? false : true
        }
    }
    
    private var chats = [Chat]()
    private var timer: Timer?
    
    private lazy var makeCallIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = #imageLiteral(resourceName: "unable_call_icon")
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    private lazy var makeCallButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .clear
        btn.addTarget(self,
                      action: #selector(handleCall),
                      for: .touchUpInside)
        return btn
    }()
    
    private lazy var hangUpIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = #imageLiteral(resourceName: "end_call_icon")
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    private lazy var hangUpButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .clear
        btn.addTarget(self,
                      action: #selector(handleHangUp),
                      for: .touchUpInside)
        return btn
    }()
    
    private lazy var onCallGif: SDAnimatedImageView = {
        let iv = SDAnimatedImageView()
        iv.image = SDAnimatedImage(named: "on-call.gif")
        iv.isHidden = true
        return iv
    }()
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        
        connectSocket(userId: userId)
        addObservers()
        
    }
    
    @objc func didEnterBackground() {
        if socketManager != nil /* && checkIsCalling() */ {
            isConnected = false
            socketManager!.disconnect()
        }
    }
    
    @objc func willResignActive() {
        print("-- App willResignActive")
    }
    
    @objc func willEnterForeground() {
        if socketManager != nil /* && checkIsCalling() */ {
            if !socketManager!.isSocketConnected /* checkIsSocketLinkOn() */ {
                isConnected = false
                socketManager!.connect()
            }
        }
        /*
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
         */
    }
    
    @objc func willTerminate() {
        print("-- App willTerminate")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Selector
    @objc private func handleCall() {
        let callRemote = CallRemoteModel(action: SocketType.callRemote.rawValue,
                                         user_id: userId,
                                         to_userid: toUserId!,
                                         used_phone: UsedPhoneStatus.answer.rawValue,
                                         to_user_token: "")
        socketManager?.callRemote(data: callRemote)
    }
    
    @objc func handleHangUp() {
        
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
        
        view.addSubview(makeCallIcon)
        view.addSubview(makeCallButton)
        view.addSubview(hangUpIcon)
        view.addSubview(hangUpButton)
        view.addSubview(onCallGif)
        
        makeCallIcon.snp.makeConstraints {
            $0.bottom.equalTo(-screenHeight * (124/812))
            $0.right.equalTo(view.snp.centerX).offset(-screenWidth * (20/375))
            $0.height.width.equalTo(screenWidth * (72/375))
        }
        
        makeCallButton.snp.makeConstraints {
            $0.edges.equalTo(makeCallIcon)
        }
        
        hangUpIcon.snp.makeConstraints {
            $0.bottom.equalTo(-screenHeight * (124/812))
            $0.left.equalTo(view.snp.centerX).offset(screenWidth * (20/375))
            $0.height.width.equalTo(screenWidth * (72/375))
        }
        
        hangUpButton.snp.makeConstraints {
            $0.edges.equalTo(hangUpIcon)
        }
        
        onCallGif.snp.makeConstraints {
            $0.bottom.equalTo(makeCallIcon.snp.top).offset(-screenHeight * (52/812))
            $0.centerX.equalTo(view)
            $0.width.equalTo(screenWidth * (60/375))
            $0.height.equalTo(screenWidth * (60/375))
        }
    }
    
    private func sendMessages() {
        timer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            self?.send("Pokémon getto daze")
        }
    }
    
    @objc private func send(_ text: String) {
        guard let toUserId = toUserId else { return }
        let message = SendMessageModel(action: SocketType.say.rawValue,
                                       user_id: userId,
                                       user_name: "",
                                       to_userid: toUserId,
                                       content: text)
        self.socketManager?.sendMessage(message: message, onSuccess: { result in
            debugPrint("send result = ", result ?? "Failed")
            print(message)
        })
    }
    
}

// MARK: - SocketDelegate
extension ViewController: SocketDelegate {
    
    func didConnect(_ socket: SocketManager) {
        
    }
    
    func didDisconnect(_ socket: SocketManager) {
        self.isConnected = false
    }
    
    func didLinkOn(_ socket: SocketManager, iceServers: [IceServer]) {
        self.iceServers = iceServers
    }
    
    func didBind(_ socket: SocketManager, linkId: Int) {
        debugPrint("SocketManager didBind link_id = \(linkId)")
        self.linkId = linkId
        self.isConnected = true
        
//        self.sendMessages()
        
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
    
    func didReceiveCall(_ socket: SocketManager, message: ReceivedMessageModel) {
        guard let toUserId = message.to_userid else { return }
        guard let used_phone = message.used_phone else { return }
        if used_phone == 0 {
            // 來電並回傳接受
            self.toUserId = toUserId
            self.handleCall()
        } else if used_phone == 1 {
            // 去電並對方已回傳接受 ➡️ 進入 RTC 通訊
            debugPrint("SocketManager didReceive CallRemote_CallBack. From id:", toUserId)
            self.isOnCall = true
        }
    }
    
}
