//
//  SocketModel.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import Foundation

// MARK: - Message
struct ReceivedMessageModel: Codable {
    let action: String?
    let content: String?
    let link_id: Int?
    let to_userid: String?
    let category: String?
    let time: String?
    let media: String?
    let iceserver_config: IceserverConfig?
    
    enum CodingKeys: CodingKey {
        case action, content, link_id, to_userid, category, time, media, iceserver_config }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        action = try? container.decodeIfPresent(String.self, forKey: .action) ?? ""
        content = try? container.decodeIfPresent(String.self, forKey: .content) ?? ""
        link_id = try? container.decodeIfPresent(Int.self, forKey: .link_id) ?? nil
        to_userid = try? container.decodeIfPresent(String.self, forKey: .to_userid) ?? ""
        category = try? container.decodeIfPresent(String.self, forKey: .category) ?? ""
        time = try? container.decodeIfPresent(String.self, forKey: .time) ?? ""
        media = try? container.decodeIfPresent(String.self, forKey: .media) ?? ""
        iceserver_config = try? container.decodeIfPresent(IceserverConfig.self, forKey: .iceserver_config) ?? nil
    }
}

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

// MARK: - Socket Binding
struct BindUserModel: Codable {
    let action: String?
    let user_id: String?
    let user_name: String?
    let link_id: Int?
    let to_userid: String?
}

// MARK: - Socket Send
struct SendMessageModel: Codable {
    let action: String
    let user_id: String
    let user_name: String
    let to_userid: String
    let content: String
    let category: String
    let media: String
}
