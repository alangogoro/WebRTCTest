//
//  Data + Extension.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import Foundation

extension Data {
    
    func parseToReceivedMessageModel() -> [ReceivedMessageModel]? {
        var list = [ReceivedMessageModel]()
        do {
            let decodedData = try JSONDecoder().decode(ReceivedMessageModel.self, from: self)
            list.append(decodedData)
            return list
        } catch {
            return nil
        }
    }
    
}
