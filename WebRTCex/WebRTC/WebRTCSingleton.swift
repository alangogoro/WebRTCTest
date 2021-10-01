//
//  WebRTCManager.swift
//  WebRTCex
//
//  Created by usr on 2021/9/30.
//

import Foundation
import WebRTC

protocol WebRTCDelegate: AnyObject {
    func webRTCClient(_ webRTC: WebRTCSingleton, didDiscoverLocalCandidate candidate: RTCIceCandidate)
    func webRTCClient(_ webRTC: WebRTCSingleton, didChangeConnectionState state: RTCIceConnectionState)
    func webRTCClient(_ webRTC: WebRTCSingleton, dataChannel: RTCDataChannel, didReceiveData data: Data)
}

final class WebRTCSingleton: NSObject {
    
    // MARK: - Property
    /** The `RTCPeerConnectionFactory` is in charge of creating new RTCPeerConnection instances.
     * A new RTCPeerConnection should be created every new call, but the factory is shared. */
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
//        videoEncoderFactory.preferredCodec = getSupportedVideoEncoder(factory: videoEncoderFactory)
        videoEncoderFactory.preferredCodec = RTCVideoCodecInfo(name: kRTCVp8CodecName)
        
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    
    weak var delegate: WebRTCDelegate?
    private let peerConnection: RTCPeerConnection//連線狀態及操作
    
    private let rtcAudioSession = RTCAudioSession.sharedInstance()
    private let audioQueue = DispatchQueue(label: "audio")
    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                                   kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]
    // private var videoCapturer: RTCVideoCapturer?
    // private var localVideoTrack: RTCVideoTrack?
    // private var remoteVideoTrack: RTCVideoTrack?
    
    // private var localDataChannel: RTCDataChannel?//強制寫死
    // private var remoteDataChannel: RTCDataChannel?
    
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
        }}
        
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
        self.configureAudioSession()
        self.peerConnection.delegate = self
    }
    
    // MARK: Signaling
    func offer() {}
    func answer() {}
    func cancel() {
        self.peerConnection.close()
    }
    func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> ()) {
        self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
    }
    
    func set(remoteCandidate: RTCIceCandidate) {
        self.peerConnection.add(remoteCandidate)
    }
    
    // MARK: Media
    /*
    func startCaptureLocalVideo(renderer: RTCVideoRenderer) {
        guard let capturer = self.videoCapturer as? RTCCameraVideoCapturer else { return }
        
        guard let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }),
              // choose highest res
              let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted { (f1, f2) -> Bool in
                let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
                let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
                return width1 < width2
              }).last,
              // choose highest fps
              let fps = (format.videoSupportedFrameRateRanges
                            .sorted { return $0.maxFrameRate < $1.maxFrameRate }.last) else { return }

        capturer.startCapture(with: frontCamera,
                              format: format,
                              fps: Int(fps.maxFrameRate))
        
        // self.localVideoTrack?.add(renderer)
    }
    */
    
    func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        // self.remoteVideoTrack?.add(renderer)
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
    
    private func createAudioTrack() -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = WebRTCSingleton.factory.audioSource(with: audioConstrains)
        let audioTrack = WebRTCSingleton.factory.audioTrack(with: audioSource, trackId: "audio0")
        return audioTrack
    }
    
    // private func createVideoTrack() -> RTCVideoTrack {}
    
    // MARK: Data Channels
    private func createDataChannel() -> RTCDataChannel? {
        let config = RTCDataChannelConfiguration()
        // config.isOrdered = true
        // config.isNegotiated = true
        // config.channelId = 0
        guard let dataChannel = self.peerConnection.dataChannel(forLabel: "WebRTCData", configuration: config) else {
            debugPrint("Warning: Couldn't create data channel.")
            return nil
        }
        return dataChannel
    }
    
    func sendData(_ data: Data) {
        let buffer = RTCDataBuffer(data: data, isBinary: true)
        // self.remoteDataChannel?.sendData(buffer)
        // set more DataChannels...
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
        self.delegate?.webRTCClient(self, didChangeConnectionState: newState)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        debugPrint("peerConnection new gathering state: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.delegate?.webRTCClient(self, didDiscoverLocalCandidate: candidate)//ip...
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        debugPrint("peerConnection did remove candidate(s)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        debugPrint("peerConnection did open data channel id = \(dataChannel.channelId)")
        // self.remoteDataChannel = dataChannel
        // set more DatChannels...
    }
    
}
