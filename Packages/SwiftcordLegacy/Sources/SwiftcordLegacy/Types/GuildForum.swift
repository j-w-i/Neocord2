//
//  File.swift
//  
//
//  Created by JWI on 5/11/2025.
//

import Foundation

public class GuildForum: GuildChannel {
    public var lastMessageID: Snowflake?
    public var guild: Guild?
    public var name: String?
    public var slClient: SLClient?
    public var id: Snowflake?
    public var type: ChannelType
    public var parentID: Snowflake?
    public var position: Int?

    public var threads = [Snowflake: GuildThread]()
    
    public var category: GuildCategory? {
        guard let parentID = parentID else { return nil }
        return guild?.channels[parentID] as? GuildCategory
    }

    public init(_ slClient: SLClient, _ json: [String: Any]) {
        self.type = .guildForum
        self.slClient = slClient
        self.id = Snowflake(json["id"] as? String)
        self.name = json["name"] as? String
        self.parentID = Snowflake(json["parent_id"] as? String)
        self.position = json["position"] as? Int
        self.lastMessageID = Snowflake(json["last_message_id"] as? String)

        if let guildId = Snowflake(json["guild_id"]),
           let guild = slClient.guilds[guildId] {
            self.guild = guild
        }
    }
    
    public func convertToDict() -> [String: Any] {
        return [
            "id": self.id?.description,
            "name": self.name ?? "",
            "type": self.type.rawValue,
            "parent_id": self.parentID?.rawValue ?? NSNull(),
            "position": self.position ?? NSNull(),
            "last_message_id": self.lastMessageID?.rawValue ?? NSNull()
        ]
    }
}


