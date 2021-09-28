//
//  Data + Extension.swift
//  WebRTCex
//
//  Created by usr on 2021/9/28.
//

import Foundation

extension Data {
    
    func parseToType<T: Decodable>(_ source: T) -> T? {
        var list = [Any?]()
        do {
            let decodedData = try JSONDecoder().decode(source.self as! T.Type, from: self)
            list.append(decodedData)
            return decodedData
        } catch {
            return nil
        }
    }
    
}
