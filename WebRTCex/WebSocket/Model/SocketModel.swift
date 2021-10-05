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
    var user_id: String?
    let content: String?
    let link_id: Int?
    let to_userid: String?
    let category: String?
    let time: String?
    let media: String?
    let iceserver_config: IceserverConfig?
    /// 判斷接到了來電
    let used_phone: Int?
    /// 對方的 WebRTC `local SessionDescription` string
    var info: String?
    var ice_sdp: String?
    var ice_index: Int?
    var ice_mid: String?
    var logid: String?
    
    enum CodingKeys: CodingKey {
        case action, user_id, content, link_id, to_userid, category, time, media, iceserver_config,
             used_phone, info, ice_sdp, ice_index, ice_mid, logid }
    
    /* ⛔️🔰 忘記加上 CodingKeys 和 init 賦值的話，解析後該屬性的資料都是 nil 要注意 */
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        action = try? container.decodeIfPresent(String.self, forKey: .action) ?? ""
        user_id = try? container.decodeIfPresent(String.self, forKey: .user_id) ?? ""
        content = try? container.decodeIfPresent(String.self, forKey: .content) ?? ""
        link_id = try? container.decodeIfPresent(Int.self, forKey: .link_id) ?? nil
        to_userid = try? container.decodeIfPresent(String.self, forKey: .to_userid) ?? ""
        category = try? container.decodeIfPresent(String.self, forKey: .category) ?? ""
        time = try? container.decodeIfPresent(String.self, forKey: .time) ?? ""
        media = try? container.decodeIfPresent(String.self, forKey: .media) ?? ""
        iceserver_config = try? container.decodeIfPresent(IceserverConfig.self, forKey: .iceserver_config) ?? nil
        used_phone = try? container.decodeIfPresent(Int.self, forKey: .used_phone) ?? -1
        info = try? container.decodeIfPresent(String.self, forKey: .info) ?? nil
        ice_sdp = try? container.decodeIfPresent(String.self, forKey: .ice_sdp) ?? ""
        ice_index = try? container.decodeIfPresent(Int.self, forKey: .ice_index) ?? 0
        ice_mid = try? container.decodeIfPresent(String.self, forKey: .ice_mid) ?? ""
        logid = try? container.decodeIfPresent(String.self, forKey: .logid) ?? ""
    }
}

// MARK: - Socket - Bind
struct BindUserModel: Codable {
    let action: String
    let user_id: String
    let user_name: String
    let link_id: Int
    let to_userid: String
}

// MARK: - Socket - Send
struct SendMessageModel: Codable {
    let action: String
    let user_id: String
    let user_name: String
    let to_userid: String
    let content: String
    var category: String? = "private"
    var media: String? = ""
}
