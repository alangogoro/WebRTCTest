//
//  RTCModel.swift
//  WebRTCex
//
//  Created by usr on 2021/9/29.
//

import Foundation
import WebRTC

struct IceserverConfig: Codable {
    let iceServers: [IceServer]?
    
    enum CodingKeys: CodingKey {
        case iceServers
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        iceServers = try? container.decodeIfPresent([IceServer].self, forKey: .iceServers) ?? nil
    }
}

struct IceServer: Codable {
    let urls: String?
    let username: String?
    let credential: String?
    
    enum CodingKeys: CodingKey {
        case urls, username, credential
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        urls = try? container.decodeIfPresent(String.self, forKey: .urls) ?? ""
        username = try? container.decodeIfPresent(String.self, forKey: .username) ?? ""
        credential = try? container.decodeIfPresent(String.self, forKey: .credential) ?? ""
    }
}

// MARK: - Socket - CallRemote & Cancel Phone
struct CallRemoteModel: Codable {
    let action: String
    let user_id: String
    var user_img: String? = "img/profile_0.jpg"
    var user_name: String? = "訪客1"
    let to_userid: String
    let used_phone: Int
    var media_type: Int? = MediaType.audio.rawValue
    var user_voice_fee: Int? = 1
    var user_text_fee: Int? = 1
    var user_video_fee: Int? = 1
    var user_age: Int? = 18
    var to_user_os_type: Int? = UserOsType.iOS.rawValue
    var to_user_token: String? = ""    // 對方的 device token（使用於退背時推播來電）
    var connection_mode: String? = "0" // 0→不玩遊戲 1→遊戲
    var time: Int? = 0 // cancel_phone 使用
}

enum UsedPhoneStatus: Int {
    case reject = 0
    case answer = 1
}

enum MediaType: Int {
    case audio = 1
    case video = 2
}

enum UserOsType: Int {
    case android = 1
    case iOS = 2
}

// MARK: - WebRTC - Create Offer or Answer
struct OfferAnswerModel: Codable {
    let action: String
    let user_id: String
    var user_img: String? = "img/profile_0.jpg"
    var user_name: String? = "訪客1"
    let to_userid: String
    let info: String
}

// MARK: - WebRTC - Candidate
struct CandidateModel: Codable {
    var action: String
    var user_id: String
    var user_img: String? = "img/profile_0.jpg"
    var user_name: String? = "訪客1"
    var to_userid: String?
    var ice_sdp: String
    var ice_index: Int
    var ice_mid: String
}

// MARK: - WebRTC -
enum Message {
    case sdp(SessionDescription)
    case candidate(IceCandidate)
}

enum CodingKeys: String, CodingKey {
    case type, payload
}

enum DecodeError: Error {
    case unknownType
}

extension Message: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case String(describing: SessionDescription.self):
            self = .sdp(try container.decode(SessionDescription.self, forKey: .payload))
        case String(describing: IceCandidate.self):
            self = .candidate(try container.decode(IceCandidate.self, forKey: .payload))
        default:
            throw DecodeError.unknownType
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .sdp(let sessionDescription):
            try container.encode(sessionDescription, forKey: .payload)
            try container.encode(String(describing: SessionDescription.self), forKey: .type)
        case .candidate(let iceCandidate):
            try container.encode(iceCandidate, forKey: .payload)
            try container.encode(String(describing: IceCandidate.self), forKey: .type)
        }
    }
}

enum SdpType: String, Codable {
    case offer, prAnswer, answer
    
    var rtcSdpType: RTCSdpType {
        switch self {
        case .offer:
            return .offer
        case .answer:
            return .answer
        case .prAnswer:
            return .prAnswer
        }
    }
}

/// This struct is a swift wrapper over `RTCSessionDescription` for easy encode and decode
struct SessionDescription: Codable {
    let sdp: String
    let type: SdpType
    
    init(from rtcSessionDescription: RTCSessionDescription) {
        self.sdp = rtcSessionDescription.sdp
        
        switch rtcSessionDescription.type {
        case .offer:
            self.type = .offer
        case .prAnswer:
            self.type = .prAnswer
        case .answer:
            self.type = .answer
        default:
            fatalError("Unknown RTCSessionDescription type: \(rtcSessionDescription.type.rawValue)")
        }
    }
    
    var rtcSessionDescription: RTCSessionDescription {
        return RTCSessionDescription(type: self.type.rtcSdpType, sdp: self.sdp)
    }
}

/// This struct is a swift wrapper over `RTCIceCandidate` for easy encode and decode
struct IceCandidate: Codable {
    let sdp: String
    let sdpMlineIndex: Int32
    let sdpMid: String?
    
    init(from iceCandidate: RTCIceCandidate) {
        self.sdpMlineIndex = iceCandidate.sdpMLineIndex
        self.sdpMid = iceCandidate.sdpMid
        self.sdp = iceCandidate.sdp
    }
    
    var rtcIceCandidate: RTCIceCandidate {
        return RTCIceCandidate(sdp: self.sdp, sdpMLineIndex: self.sdpMlineIndex, sdpMid: self.sdpMid)
    }
}
