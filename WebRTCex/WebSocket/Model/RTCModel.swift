//
//  RTCModel.swift
//  WebRTCex
//
//  Created by usr on 2021/9/29.
//

import Foundation

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
    let to_user_token: String // 對方的 device token（使用於退背時推播來電）
    var connection_mode: String? = "0" // 0→不玩遊戲 1→遊戲
    //var time: Int? // cancel_phone 使用
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
