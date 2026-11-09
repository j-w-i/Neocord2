//
//  File.swift
//  
//
//  Created by JWI on 1/11/2025.
//

import Foundation
import UIKit

public struct Role: DictionaryConvertible {
    public let color: UIColor
    public let id: Snowflake
    public let isHoisted: Bool
    public let isManaged: Bool
    public let isMentionable: Bool
    public let name: String
    public let permissions: Int?
    public let position: Int
    public let icon: String?
    
    init(_ json: [String: Any]) {
        self.color = UIColor(discordColor: json["color"] as? Int ?? 0)
        self.isHoisted = json["hoist"] as? Bool ?? false
        self.id = Snowflake(json["id"])!
        self.isManaged = json["managed"] as? Bool ?? false
        self.isMentionable = json["mentionable"] as? Bool ?? false
        self.name = json["name"] as? String ?? ""
        self.permissions = json["permissions"] as? Int
        self.position = json["position"] as? Int ?? 0
        self.icon = json["icon"] as? String
    }
    
    public func convertToDict() -> [String : Any] {
        return [
            "id": self.id.description,
            "name": self.name,
            "color": self.color.argbInt,
            "hoist": self.isHoisted,
            "managed": self.isManaged,
            "mentionable": self.isMentionable,
            "permissions": self.permissions ?? NSNull(),
            "position": self.position,
            "icon": self.icon ?? NSNull()
        ]
    }
}

