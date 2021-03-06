//
//  ViewController.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import UIKit
import SnapKit
import SDWebImage
import WebRTC

class ViewController: UIViewController {
    
    // MARK: - Property
    var socketManager: SocketManager?
    var webRTC: WebRTCSingleton?
    let userId = Constants.Ids.User_Id_He
    var linkId = 0
    var toUserId: String? = Constants.Ids.User_Id_She
    var iceServers: [IceServer]?
    var isConnected: Bool = false {
        didSet { DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.makeCallIcon.image = self.isConnected ? #imageLiteral(resourceName: "call_icon") : #imageLiteral(resourceName: "unable_call_icon") } }
    }
    var isOnCall: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.onCallGif.isHidden = self.isOnCall ? false : true
                UIView.animate(withDuration: 0.7) {
                    self.amplifyIcon.alpha = self.isOnCall ? 1 : 0
                    self.amplifyIcon.isHidden = self.isOnCall ? false : true
                    self.bottomStackView.layoutSubviews()
                }
            }
        }
    }
    private var localCandidates = 0 {
        didSet {
            DispatchQueue.main.async {
                self.localCandidatesLabel.text = "Local candidates: \(self.localCandidates)" }
        }
    }
    private var remoteCandidates = 0 {
        didSet {
            DispatchQueue.main.async {
                self.remoteCandidatesLabel.text = "Remote candidates: \(self.remoteCandidates)"
            }
        }
    }
    private var isSpeakerOn: Bool = false
    
    private var chats = [Chat]()
    private var timer: Timer?
    
    private lazy var topStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [localCandidatesLabel,
                                                remoteCandidatesLabel])
        sv.backgroundColor = .clear
        sv.axis = .vertical
        sv.alignment = .fill
        sv.distribution = .fillEqually
        sv.spacing = 12
        return sv
    }()

    private lazy var localCandidatesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .white
        label.textAlignment = .left
        label.text = "Local candidates: \(remoteCandidates)"
        return label
    }()
    
    private lazy var remoteCandidatesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .white
        label.textAlignment = .left
        label.text = "Remote candidates: \(remoteCandidates)"
        return label
    }()
    
    private lazy var stateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "????????????"
        return label
    }()
    
    private lazy var onCallGif: SDAnimatedImageView = {
        let iv = SDAnimatedImageView()
        iv.image = SDAnimatedImage(named: "on-call.gif")
        return iv
    }()
    
    private lazy var bottomStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [amplifyIcon, makeCallIcon, hangUpIcon])
        sv.backgroundColor = .clear
        sv.axis = .horizontal
        sv.alignment = .center
        sv.distribution = .fillEqually
        sv.spacing = screenWidth * (40/375)
        return sv
    }()
    
    private lazy var amplifyIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = #imageLiteral(resourceName: "speaker_off")
        iv.contentMode = .scaleAspectFill
        iv.alpha = 0
        return iv
    }()
    
    private lazy var amplifyButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .clear
        btn.addTarget(self,
                      action: #selector(handleAmplify),
                      for: .touchUpInside)
        return btn
    }()
    
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
            stateLabel.text = "WebSocket ????????????"
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
                stateLabel.text = "WebSocket ?????????"
            }
        }
    }
    
    @objc func willTerminate() {
        print("-- App willTerminate")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Selector
    @objc private func handleCall() {
        guard Authorization.shared.authorizationForMic(self) else { return }
        
        guard let toUserId = toUserId else { return }
        let callRemote = CallRemoteModel(action: SocketType.callRemote.rawValue,
                                         user_id: userId,
                                         to_userid: toUserId,
                                         used_phone: UsedPhoneStatus.answer.rawValue)
        socketManager?.callRemote(data: callRemote)
        
        guard let iceServers = iceServers else { return }
        webRTC = WebRTCSingleton(iceServers: iceServers)
        webRTC?.delegate = self
        
        stateLabel.text = "????????? ??????"
        //isOnCall = true
    }
    
    @objc func handleHangUp() {
        guard let toUserId = toUserId else { return }
        if isOnCall { // ??????
            let data = CallRemoteModel(action: SocketType.cancelPhone.rawValue,
                                       user_id: userId,
                                       to_userid: toUserId,
                                       used_phone: UsedPhoneStatus.reject.rawValue,
                                       time: 0)
            
            socketManager?.endCall(data: data, onSuccess: { result in
                if let _ = result {
                    //DispatchQueue.main.async {
                    self.webRTC?.disconnect()
                    self.stateLabel.text = "???????????? ???"
                    //}
                }
            })
            //isOnCall = false
        } else {      // ??????
            let data = CallRemoteModel(action: SocketType.callRemote.rawValue,
                                       user_id: userId,
                                       to_userid: toUserId,
                                       used_phone: UsedPhoneStatus.reject.rawValue)
            socketManager?.callRemote(data: data)
            stateLabel.text = "???????????? ???"
        }
    }
    
    @objc func handleAmplify() {
        defer {
            DispatchQueue.main.async {
                self.amplifyIcon.image = self.isSpeakerOn ? #imageLiteral(resourceName: "speaker_on") : #imageLiteral(resourceName: "speaker_off")
            }
        }
        
        switch isSpeakerOn {
        case true:
            webRTC?.speakerOff()
            isSpeakerOn = false
        case false:
            webRTC?.speakerOn()
            isSpeakerOn = true
        }
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
        stateLabel.text = "WebSocket ?????????"
    }
    
    private func addObservers() {
        // App ????????????????????????
        NotificationCenter.default
                          .addObserver(self,
                                       selector: #selector(didEnterBackground),
                                       name: UIApplication.didEnterBackgroundNotification,
                                       object: nil)
        // App ???????????????
        NotificationCenter.default
                          .addObserver(self,
                                       selector: #selector(willResignActive),
                                       name: UIApplication.willResignActiveNotification,
                                       object: nil)
        // App ????????????
        NotificationCenter.default
                          .addObserver(self,
                                       selector: #selector(willEnterForeground),
                                       name: UIApplication.willEnterForegroundNotification,
                                       object: nil)
        // App ????????????
        NotificationCenter.default
                          .addObserver(self,
                                       selector: #selector(willTerminate),
                                       name: UIApplication.willTerminateNotification,
                                       object: nil)
    }
    
    private func configureUI() {
        navigationItem.title = "Real-Time Communications"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        view.backgroundColor = .black
        
        view.addSubview(topStackView)
        view.addSubview(onCallGif)
        view.addSubview(bottomStackView)
        view.addSubview(stateLabel)
        view.addSubview(amplifyButton)
        view.addSubview(makeCallButton)
        view.addSubview(hangUpButton)
        
        topStackView.snp.makeConstraints {
            $0.bottom.equalTo(view.snp.centerY).offset(-screenHeight * (144/812))
            $0.centerX.equalToSuperview()
        }
        
        stateLabel.snp.makeConstraints {
            $0.top.equalTo(topStackView.snp.bottom).offset(screenHeight * (48/812))
            $0.centerX.equalTo(view)
        }
        
        onCallGif.isHidden = true
        onCallGif.snp.makeConstraints {
            $0.top.equalTo(view.snp.centerY)
            $0.centerX.equalTo(view)
            $0.width.equalTo(screenWidth * (60/375))
            $0.height.equalTo(screenWidth * (60/375))
        }
        
        bottomStackView.snp.makeConstraints {
            $0.top.equalTo(view.snp.centerY).offset(screenHeight * (156/812))
            $0.centerX.equalTo(view)
        }
        
        amplifyIcon.isHidden = true
        amplifyIcon.snp.makeConstraints {
            $0.height.width.equalTo(screenWidth * (72/375))
        }
        
        amplifyButton.snp.makeConstraints {
            $0.edges.equalTo(amplifyIcon)
        }
        
        makeCallIcon.snp.makeConstraints {
            $0.width.height.equalTo(screenWidth * (72/375))
        }
        
        makeCallButton.snp.makeConstraints {
            $0.edges.equalTo(makeCallIcon)
        }
        
        hangUpIcon.snp.makeConstraints {
            $0.height.width.equalTo(screenWidth * (72/375))
        }
        
        hangUpButton.snp.makeConstraints {
            $0.edges.equalTo(hangUpIcon)
        }
        
    }
    
    private func sendMessages() {
        timer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            self?.send("Pok??mon getto daze")
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
        DispatchQueue.main.async { self.stateLabel.text = "WebSocket ?????????" }
    }
    
    func didBind(_ socket: SocketManager, linkId: Int) {
        debugPrint("SocketManager didBind link_id = \(linkId)")
        self.linkId = linkId
        self.isConnected = true
        
        DispatchQueue.main.async { self.stateLabel.text = "WebSocket ?????????" }
        // self.sendMessages()
    }
    
    func didReceiveMessage(_ socket: SocketManager, message: ReceivedMessageModel) {
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
        
        switch used_phone {
        // ??????
        case UsedPhoneCallbackStatus.call.rawValue:
            self.toUserId = toUserId
            DispatchQueue.main.async { self.stateLabel.text = "?????? ???????????? ??????" }
            debugPrint("SocketManager didReceive CallRemote. From id:", toUserId)
        // ?????????????????????????????? ?????? ?????? RTC ??????
        case UsedPhoneCallbackStatus.answer.rawValue:
            DispatchQueue.main.async { self.stateLabel.text = "WebRTC ?????????" }
            debugPrint("SocketManager didReceive CallRemote_Callback. From id:", toUserId)
            
            self.webRTC?.offer(completion: { localSdp in
                self.socketManager?.send(action: SocketType.clientOffer.rawValue,
                                         sdp: localSdp,
                                         toUserId: toUserId)
            })
        // ???????????????????????????
        case UsedPhoneCallbackStatus.reject.rawValue:
            self.webRTC?.disconnect()
            DispatchQueue.main.async { self.stateLabel.text = "???????????? ???" }
        default:
            debugPrint("didReceiveCall used_phone = \(used_phone)")
        }
    }
    
    func didReceiveCall(_ socket: SocketManager, receivedRemoteSdp sdp: RTCSessionDescription) {
        // ?????????????????? SDP
        self.webRTC?.set(remoteSdp: sdp) { error in
            guard error == nil else {
                debugPrint("setRemote SDP error: ", error!)
                return }
            DispatchQueue.main.async { self.stateLabel.text = "WebRTC ????????????" }
            
            switch sdp.type {
            case .offer:
                self.webRTC?.answer(completion: { localSdp in
                    self.socketManager?.send(action: SocketType.clientAnswer.rawValue,
                                             sdp: localSdp,
                                             toUserId: self.toUserId!)
                })
                debugPrint("???? didReceiveCall - Offer remote SDP")
            case .answer:
                debugPrint("???? didReceiveCall - Answer remote SDP")
                return
            default:
                return
            }
        }
    }
    
    func didReceiveCall(_ socket: SocketManager, receivedCandidate candidate: RTCIceCandidate) {
        self.remoteCandidates += 1
        self.webRTC?.set(remoteCandidate: candidate)
        debugPrint("???? didReceiveCall - received Remote Candidates: \(self.remoteCandidates)")
    }
    
    func didEndCall(_ socket: SocketManager, userId: String, toUserId: String) {
        self.webRTC?.disconnect()
        DispatchQueue.main.async { self.stateLabel.text = "????????? ???\nWebRTC ????????????" }
        //self.isOnCall = false
    }
    
}

extension ViewController: WebRTCDelegate {
    func webRTC(_ webRTC: WebRTCSingleton, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        self.localCandidates += 1
        // debugPrint("?????? didDiscover Local Candidate")
        self.socketManager?.send(candidate: candidate, toUserId: toUserId!)
    }
    
    func webRTC(_ webRTC: WebRTCSingleton, didChangeConnectionState state: RTCIceConnectionState) {
        switch state {
        case .connected, .completed:
            self.isOnCall = true
            DispatchQueue.main.async { self.stateLabel.text = "WebRTC ?????????" }
            debugPrint("??? WebRTC Connected")
        case .failed, .disconnected, .closed:
            self.isOnCall = false
            self.localCandidates = 0
            self.remoteCandidates = 0
            DispatchQueue.main.async { self.stateLabel.text = "????????? ???\nWebRTC ????????????" }
            debugPrint("??? WebRTC Disconnected")
            
            if self.isSpeakerOn { self.handleAmplify() }
            return
        default:
            self.isOnCall = false
        }
    }
    
    func webRTC(_ webRTC: WebRTCSingleton, dataChannel: RTCDataChannel, didReceiveData data: Data) {
        
    }
    
}
