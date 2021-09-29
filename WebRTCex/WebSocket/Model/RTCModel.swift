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
