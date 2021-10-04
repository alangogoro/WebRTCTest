//
//  WebRTCManager.swift
//  WebRTCex
//
//  Created by usr on 2021/9/30.
//

import Foundation
import WebRTC

final class WebRTCSingleton: NSObject, GoogleWebRTC {
    
    // MARK: - Property
    /** The `RTCPeerConnectionFactory` is in charge of creating new RTCPeerConnection instances.
     * A new RTCPeerConnection should be created every new call, but the factory is shared. */
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        // videoEncoderFactory.preferredCodec = getSupportedVideoEncoder(factory: videoEncoderFactory) Grey
        videoEncoderFactory.preferredCodec = RTCVideoCodecInfo(name: kRTCVp8CodecName)
        
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    
    /// 核心组件：連線狀態及操作
    private let peerConnection: RTCPeerConnection
    weak var delegate: WebRTCDelegate?
    
    private let rtcAudioSession = RTCAudioSession.sharedInstance()
    private let audioQueue = DispatchQueue(label: "audio")
    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                                   kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]
    
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    
    // private var localDataChannel: RTCDataChannel?//強制寫死
    private var remoteDataChannel: RTCDataChannel?
    
    // private var remoteAudioTrack: RTCAudioTrack?
    // private var localAudioTrack: RTCAudioTrack?
    
    //private var localTextDataChannel: RTCDataChannel?
    //private var remoteTextDataChannel: RTCDataChannel?
    
    
    // MARK: - Initializer
    @available(*, unavailable)
    override init() {
        fatalError("WebRTC: init is unavailable")
    }
    
    required init(iceServers: [IceServer]) {
        let config = RTCConfiguration()
        
        if iceServers.count > 0 {
            iceServers.forEach { server in
                if let urlName = server.username, urlName != "" {
                    let urlString = server.urls!
                    let credential = server.credential!
                    config.iceServers.append(RTCIceServer(urlStrings: [urlString],
                                                          username: urlName,
                                                          credential: credential))
                } else {
                    let urlString = server.urls
                    config.iceServers.append(RTCIceServer(urlStrings: [urlString!]))
                }
            }
        }
        
        // Unified plan is more superior than planB
        config.sdpSemantics = .unifiedPlan
        // gatherContinually will let WebRTC to listen to any network changes and
        // send any new candidates to the other client
        config.continualGatheringPolicy = .gatherContinually
        
        // 控制MediaStream的内容(媒体类型、分辨率、帧率)
        let constraints =
            RTCMediaConstraints(mandatoryConstraints: nil,
                                optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue])
        self.peerConnection = WebRTCSingleton.factory
            .peerConnection(with: config, constraints: constraints, delegate: nil)
        
        super.init()
        self.createMediaSenders()
        self.configureAudioSession_Grey()
        self.peerConnection.delegate = self
    }
    
    // MARK: Signaling
    /// 获取本地 SDP (Session Description Protocol) 用来发送给 socket 服务器
    func offer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(mandatoryConstraints: mediaConstrains,
                                             optionalConstraints: nil)
        peerConnection.offer(for: constrains) { (sdp, error) in
            guard let sdp = sdp else { return }
            guard error == nil else {
                debugPrint("offer sdp error = ", error!)
                return
            }
            self.peerConnection.setLocalDescription(sdp, completionHandler: { error in
                completion(sdp)
            })
        }
    }
    
    /// 回复 sockdet 服务器 SDP (Session Description Protocol) answer
    func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
                                             optionalConstraints: nil)
        self.peerConnection.answer(for: constrains) { (sdp, error) in
            guard let sdp = sdp else { return }
            debugPrint("Answer Local SDP = ", sdp)
            //设置本地 sdp
            self.peerConnection.setLocalDescription(sdp, completionHandler: { error in
                //发送出去 sdp
                completion(sdp)
            })
        }
    }
    
    func disconnect() {
        self.peerConnection.close()
    }
    
    /// 设置远程 SDP
    func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> ()) {
        self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
    }
    
    /// 添加远程 Candidate
    func set(remoteCandidate: RTCIceCandidate) {
        self.peerConnection.add(remoteCandidate)
    }
    
    // MARK: Media
    func startCaptureLocalVideo(renderer: RTCVideoRenderer) {
        guard let capturer = self.videoCapturer as? RTCCameraVideoCapturer else { return }
        
        guard
            // 获取前置摄像头 front 后置取 back
            let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }),
            // choose highest res
            let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted { (format1, format2) -> Bool in
                let width1 = CMVideoFormatDescriptionGetDimensions(format1.formatDescription).width
                let width2 = CMVideoFormatDescriptionGetDimensions(format2.formatDescription).width
                return width1 < width2
            }).last,
            
            // choose highest fps
            let fps = (format.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last) else { return }
        
        capturer.startCapture(with: frontCamera,
                              format: format,
                              fps: Int(fps.maxFrameRate))
        
        self.localVideoTrack?.add(renderer)
    }
    
    //Figure out that the CPU load is too high
    func startCaptureLocalVideo_Grey(cameraPositon: AVCaptureDevice.Position, renderer: RTCVideoRenderer) {
        let videoWidth =  640
        let videoHeight = 480//640*16/9
        var fps = 30
        
        if let capturer = self.videoCapturer as? RTCCameraVideoCapturer {
            
            var targetDevice: AVCaptureDevice?
            var targetFormat: AVCaptureDevice.Format?
            
            // find target device
            let devicies = RTCCameraVideoCapturer.captureDevices()
            devicies.forEach { (device) in
                if device.position ==  cameraPositon {
                    targetDevice = device
                }
            }

            // find target format
            let formats = RTCCameraVideoCapturer.supportedFormats(for: targetDevice!)
            formats.forEach { (format) in
                let fpsR = (format.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last)
                fps = Int(fpsR?.maxFrameRate ?? 30)
                
//                debugPrint(#line, fps)
                
                for _ in format.videoSupportedFrameRateRanges {
                    let description = format.formatDescription as CMFormatDescription
                    let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                    
                    if dimensions.width == videoWidth && dimensions.height == videoHeight {
                        targetFormat = format
                    } else if dimensions.width == videoWidth {
                        targetFormat = format
                    }
                }
            }
            //Int(fps.maxFrameRate)
            capturer.startCapture(with: targetDevice!, format: targetFormat!, fps: fps)
            
            self.localVideoTrack?.remove(renderer)
            self.localVideoTrack?.add(renderer)
            
        } else if let capturer = self.videoCapturer as? RTCFileVideoCapturer {
            print(#line, "setup file video capturer")
            if let _ = Bundle.main.path( forResource: "sample.mp4", ofType: nil ) {
                capturer.startCapturing(fromFileNamed: "sample.mp4") { (err) in
                    print(err)
                }
            } else {
                print("file did not faund")
            }
        }
    }
    
    func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        self.remoteVideoTrack?.add(renderer)
    }
    
    // MARK: - Audio
    private func configureAudioSession() {
        self.rtcAudioSession.lockForConfiguration()
        do {
            try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
            try self.rtcAudioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
        } catch let error {
            debugPrint("Error changeing AVAudioSession category: \(error)")
        }
        self.rtcAudioSession.unlockForConfiguration()
    }
    
    // 設置音頻
    private func configureAudioSession_Grey() {
        self.rtcAudioSession.lockForConfiguration()
        do {
            try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue,
                                                 with: [.defaultToSpeaker,
                                                        .allowBluetoothA2DP,
                                                        .allowAirPlay,
                                                        .allowBluetooth,
                                                        .duckOthers])
            try self.rtcAudioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
        } catch let error {
            debugPrint("Error changeing AVAudioSession category: \(error)")
        }
        self.rtcAudioSession.unlockForConfiguration()
    }
    
    private func createMediaSenders() {
        let streamId = "stream"
        
        // Audio
        let audioTrack = self.createAudioTrack()
        self.peerConnection.add(audioTrack, streamIds: [streamId])
        
        // Video
//        let videoTrack = self.createVideoTrack()
//        self.localVideoTrack = videoTrack
//        self.peerConnection.add(videoTrack, streamIds: [streamId])
//        self.remoteVideoTrack = self.peerConnection.transceivers
//            .first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
        
        // Data
//        if let dataChannel = createDataChannel() {
//            dataChannel.delegate = self
//            self.localDataChannel = dataChannel
//        }
    }
    
    //func createDataChannelSenders() {}
    
    /// 创建音频 track
    private func createAudioTrack() -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = WebRTCSingleton.factory.audioSource(with: audioConstrains)
        let audioTrack = WebRTCSingleton.factory.audioTrack(with: audioSource, trackId: "audio0")
        return audioTrack
    }
    
    /// 创建视频track
    private func createVideoTrack() -> RTCVideoTrack {
        let videoSource = WebRTCSingleton.factory.videoSource()
        
        #if TARGET_OS_SIMULATOR
        self.videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
        #else
        self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        #endif
        
        let videoTrack = WebRTCSingleton.factory.videoTrack(with: videoSource, trackId: "video0")
        return videoTrack
    }
    
    // MARK: Data Channels
    private func createDataChannel() -> RTCDataChannel? {
        let config = RTCDataChannelConfiguration()
        /* config.isOrdered = true
        config.isNegotiated = true
        config.channelId = 0 */
        guard let dataChannel = self.peerConnection.dataChannel(forLabel: "WebRTCData", configuration: config) else {
            debugPrint("Warning: Couldn't create data channel.")
            return nil
        }
        return dataChannel
    }
    
    func sendData(_ data: Data) {
        let buffer = RTCDataBuffer(data: data, isBinary: true)
        self.remoteDataChannel?.sendData(buffer)
        /*
        if channelId == 0 {
            self.remoteDataChannel?.sendData(buffer)
        } else {
            self.remoteTextDataChannel?.sendData(buffer)
        }
        */
    }
    
}


// MARK: - RTCPeerConnectionDelegate
extension WebRTCSingleton: RTCPeerConnectionDelegate {
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        debugPrint("peerConnection new connection state: \(newState.rawValue)")
        self.delegate?.webRTC(self, didChangeConnectionState: newState)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        debugPrint("peerConnection new gathering state: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.delegate?.webRTC(self, didDiscoverLocalCandidate: candidate)//ip...
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        debugPrint("peerConnection did remove candidate(s)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        debugPrint("peerConnection did open data channel id = \(dataChannel.channelId)")
        self.remoteDataChannel = dataChannel
        /*
        if dataChannel.channelId == 0 {
            self.remoteDataChannel = dataChannel
        } else if dataChannel.channelId == 1 {
            self.remoteTextDataChannel = dataChannel
        }
         */
    }
    
}

// MARK: - Audio Control
extension WebRTCSingleton {
    
    func muteAudio() {
        self.setAudioEnabled(false)
    }
    
    func unmuteAudio() {
        self.setAudioEnabled(true)
    }
    
    func openVideo() {
        self.setVideoEnabled(true)
    }
    
    func closeVideo() {
        self.setVideoEnabled(false)
    }
    
    private func setAudioEnabled(_ isEnabled: Bool) {
        let audioTracks = self.peerConnection.transceivers.compactMap { return $0.sender.track as? RTCAudioTrack }
        audioTracks.forEach { $0.isEnabled = isEnabled }
    }
    
    private func setVideoEnabled(_ isEnabled: Bool) {
        let videoTracks = self.peerConnection.transceivers.compactMap { return $0.sender.track as? RTCVideoTrack }
        videoTracks.forEach { $0.isEnabled = isEnabled }
    }
    
    /// Fallback to the default playing device: headphones/bluetooth/ear speaker
    func speakerOff() {
        self.audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
                try self.rtcAudioSession.overrideOutputAudioPort(.none)
                // try self.rtcAudioSession.setActive(false) Grey
            } catch let error {
                debugPrint("Error setting AVAudioSession category: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    /// Force speaker
    func speakerOn() {
        self.audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
                try self.rtcAudioSession.overrideOutputAudioPort(.speaker)
                try self.rtcAudioSession.setActive(true)
            } catch let error {
                debugPrint("Couldn't force audio to speaker: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
}

// MARK: - RTCDataChannelDelegate
extension WebRTCSingleton: RTCDataChannelDelegate {
    
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        debugPrint("dataChannel did change state: \(dataChannel.readyState)")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        self.delegate?.webRTC(self, dataChannel: dataChannel, didReceiveData: buffer.data)
    }
    
}
