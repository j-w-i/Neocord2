//
//  File.swift
//  
//
//  Created by JWI on 15/10/2025.
//

import Foundation

public protocol DiscordMessage {
    var id: Snowflake? { get }
    var author: User? { get }
    var content: String? { get set }
    var attachments: [Attachment] { get }
    var channelID: Snowflake? { get }
    var timestamp: Date? { get }
    var edited: Bool { get }
    var embeds: [Embed]? { get }
    var mentions: [User] { get set }
    var type: MessageType { get }
    var reactions: [Reaction] { get set }
}

public struct Message: DiscordMessage {
    public let id: Snowflake?
    public let author: User?
    public var content: String?
    public let attachments: [Attachment]
    public let channelID: Snowflake?
    public let timestamp: Date?
    public let edited: Bool
    public let replyMessage: ReplyMessage?
    public let embeds: [Embed]?
    public var mentions = [User]()
    public var reactions = [Reaction]()
    public var type: MessageType
    public var call: MessageCall?
    
    public init(_ slClient: SLClient, _ json: [String: Any]) {
        self.type = MessageType(rawValue: json["type"] as? Int ?? 0) ?? .default
        self.id = Snowflake(json["id"])
        
        if let authorJson = json["author"] as? [String: Any] {
            self.author = User(slClient, authorJson)
        } else {
            self.author = nil
        }
        

        self.channelID = Snowflake(json["channel_id"])
        self.content = json["content"] as? String
        self.timestamp = (json["timestamp"] as? String)?.date
        
        self.edited = !(json["edited_timestamp"] is NSNull)
        
        if let call = json["call"] as? [String: Any] {
            self.call = MessageCall(call)
        }
        
        if let replyJson = json["referenced_message"] as? [String: Any] {
            self.replyMessage = ReplyMessage(slClient, replyJson)
        } else {
            self.replyMessage = nil
        }
        
        if let attachmentsJson = json["attachments"] as? [[String: Any]] {
            self.attachments = attachmentsJson.map { Attachment($0) }
        } else {
            self.attachments = []
        }
        
        if let embedsJson = json["embeds"] as? [[String: Any]] {
            self.embeds = embedsJson.map( { Embed(slClient, $0) } )
        } else {
            self.embeds = nil
        }
        
        if let mentions = json["mentions"] as? [[String: Any]] {
            self.mentions = mentions.map { User(slClient, $0) }
        }
        
        if let reactions = json["reactions"] as? [[String: Any]] {
            self.reactions = reactions.map { Reaction($0) }
        }
    }
}

public struct ReplyMessage: DiscordMessage {
    public let id: Snowflake?
    public let author: User?
    public var content: String?
    public let attachments: [Attachment]
    public let channelID: Snowflake?
    public let timestamp: Date?
    public let edited: Bool
    public let embeds: [Embed]?
    public var mentions = [User]()
    public var type: MessageType
    public var reactions = [Reaction]()
    
    public init(_ slClient: SLClient, _ json: [String: Any]) {
        self.id = Snowflake(json["id"])
        
        if let authorJson = json["author"] as? [String: Any] {
            self.author = User(slClient, authorJson)
        } else {
            self.author = nil
        }
        

        self.channelID = Snowflake(json["channel_id"])
        self.content = json["content"] as? String
        self.timestamp = (json["timestamp"] as? String)?.date
        
        self.edited = !(json["edited_timestamp"] is NSNull)
        
        if let attachmentsJson = json["attachments"] as? [[String: Any]] {
            self.attachments = attachmentsJson.map { Attachment($0) }
        } else {
            self.attachments = []
        }
        
        if let embedsJson = json["embeds"] as? [[String: Any]] {
            self.embeds = embedsJson.map( { Embed(slClient, $0) } )
        } else {
            self.embeds = nil
        }
        
        if let mentions = json["mentions"] as? [[String: Any]] {
            self.mentions = mentions.map { User(slClient, $0) }
        }
        self.type = MessageType(rawValue: json["type"] as? Int ?? 0) ?? .default
    }
}

public struct Reaction {
    public var count: Int?
    public var me: Bool?
    public var emoji: Emoji?
    public var messageID: Snowflake?
    public var userID: Snowflake?
    
    public init(_ json: [String: Any]) {
        self.count = json["count"] as? Int
        self.me = json["me"] as? Bool
        if let emojiJson = json["emoji"] as? [String: Any] {
            self.emoji = Emoji(emojiJson)
        }
        self.messageID = Snowflake(json["message_id"] as? String)
        self.userID = Snowflake(json["user_id"] as? String)
    }
}

public struct Emoji: Equatable {
    public var id: Snowflake?
    public var name: String?
    
    public init(_ json: [String: Any]) {
        self.id = Snowflake(json["id"] as? String)
        self.name = json["name"] as? String
    }
}

public struct MessageCall {
    public var participants: [Snowflake]?
    public var endedTimestamp: Date?
    
    public init(_ json: [String: Any]) {
        self.participants = (json["participants"] as? [String])?.compactMap({ Snowflake($0) })
    }
}
