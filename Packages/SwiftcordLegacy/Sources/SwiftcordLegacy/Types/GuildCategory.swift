//
//  File.swift
//  
//
//  Created by JWI on 4/11/2025.
//

import Foundation

public class GuildCategory: GuildChannel, CustomStringConvertible {
    public var parentID: Snowflake?
    
    public var position: Int?
    
    public var guild: Guild?
    
    public var name: String?
    
    public var lastMessageID: Snowflake?
    
    public var slClient: SLClient?
    
    public var id: Snowflake?
    
    public var type: ChannelType
    
    public var channels = [Snowflake: GuildChannel]()
    
    
    public init(_ slClient: SLClient, _ json: [String: Any]) {
        self.type = .guildCategory
        self.slClient = slClient
        self.id = Snowflake(json["id"] as? String)
        self.name = json["name"] as? String
        self.parentID = Snowflake(json["parent_id"] as? String)
        self.position = json["position"] as? Int
    }
    
    public var description: String {
        return "\(name), \(position)"
    }
    
    public func convertToDict() -> [String : Any] {
        return [
            "id": self.id?.description ?? "",
            "type": self.type.rawValue,
            "name": self.name ?? "",
            "parent_id": self.parentID?.description ?? "",
            "channels": self.channels.values.map { $0.convertToDict() }
        ]
    }
}

extension GuildCategory: Hashable {
    public static func == (lhs: GuildCategory, rhs: GuildCategory) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
