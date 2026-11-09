//
//  File.swift
//  
//
//  Created by JWI on 22/10/2025.
//

import Foundation
import NSJSONSerializationForSwift

/// The base structure of arbitrary data transported to and from Gateway
struct Payload {
    var op: Int
    var d: Any
    var t: String?
    var s: Int?
    
    init(op: Int, d: Any, t: String? = nil, s: Int? = nil) {
        self.op = op
        self.d = d
        self.t = t
        self.s = s
    }
    
    func encode() -> String {
        var dict: [String: Any] = ["op": op, "d": d]
        if let t = t { dict["t"] = t }
        if let s = s { dict["s"] = s }
        let data = try? JSONSerialization.data(withJSONObject: dict, options: [])
        return String(data: data!, encoding: .utf8) ?? ""
    }
    
    init(with jsonString: String) {
        // Use Objective-C parser
        let json = JSONHelper.parseJSON(jsonString) ?? [:]
        
        self.op = json["op"] as? Int ?? -1
        self.d = json["d"] ?? NSNull()
        self.t = json["t"] as? String
        self.s = json["s"] as? Int
    }

}
