//
//  File.swift
//  
//
//  Created by JWI on 1/11/2025.
//

import Foundation

public struct GuildText: GuildChannel {
    public var lastMessageID: Snowflake?
    
    public var guild: Guild?
    
    public var name: String?
    
    public var slClient: SLClient?
    
    public var id: Snowflake?
    
    public var type: ChannelType
    
    public var parentID: Snowflake?
    
    public var position: Int?
    
    public var category: GuildCategory? {
        guard let parentID = parentID else { return nil }
        return guild?.channels[parentID] as? GuildCategory
    }
    
    public init(_ slClient: SLClient, _ json: [String: Any]) {
        self.id = Snowflake(json["id"])
        self.slClient = slClient
        self.name = json["name"] as? String
        self.type = .guildText
        if let guildId = Snowflake(json["guild_id"]),
           let guild = slClient.guilds[guildId] {
            self.guild = guild
        }
        
        self.position = json["position"] as? Int
        self.lastMessageID = Snowflake(json["last_message_id"] as? String)
        self.parentID = Snowflake(json["parent_id"] as? String)
    }
    
    public func convertToDict() -> [String: Any] {
        return [
            "id": self.id?.description,
            "name": self.name ?? "",
            "type": self.type.rawValue,
            "parent_id": self.parentID?.description ?? NSNull(),
            "position": self.position ?? NSNull(),
            "last_message_id": self.lastMessageID?.description ?? NSNull()
        ]
    }
}


public struct GuildNews: GuildChannel {
    public var lastMessageID: Snowflake?
    
    public var guild: Guild?
    
    public var name: String?
    
    public var slClient: SLClient?
    
    public var id: Snowflake?
    
    public var type: ChannelType
    
    public var parentID: Snowflake?
    
    public var position: Int?
    
    public var category: GuildCategory? {
        guard let parentID = parentID else { return nil }
        return guild?.channels[parentID] as? GuildCategory
    }
    
    public init(_ slClient: SLClient, _ json: [String: Any]) {
        self.id = Snowflake(json["id"])
        self.slClient = slClient
        self.name = json["name"] as? String
        self.type = .guildNews
        if let guildId = Snowflake(json["guild_id"]),
           let guild = slClient.guilds[guildId] {
            self.guild = guild
        }
        
        self.position = json["position"] as? Int
        self.lastMessageID = Snowflake(json["last_message_id"] as? String)
        self.parentID = Snowflake(json["parent_id"] as? String)
    }
    
    public func convertToDict() -> [String: Any] {
        return [
            "id": self.id?.description,
            "name": self.name ?? "",
            "type": self.type.rawValue,
            "parent_id": self.parentID?.description ?? NSNull(),
            "position": self.position ?? NSNull(),
            "last_message_id": self.lastMessageID?.description ?? NSNull()
        ]
    }
}
