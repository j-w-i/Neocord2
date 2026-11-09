//
//  File.swift
//  
//
//  Created by JWI on 15/10/2025.
//

import Foundation

public enum Endpoint {
    case getDMChannels
    case getMessages(Snowflake)
    case getMessagesBefore(message: Snowflake, channel: Snowflake, limit: Int)
    case getGuilds
    case getClientUser
    case sendMessage(Snowflake)
    case getRelationships
    case deleteMessage(channel: Snowflake, message: Snowflake)
    case editMessage(channel: Snowflake, message: Snowflake)
    case getGuildChannels(guild: Snowflake)
    case getChannel(channel: Snowflake)
    case getGuild(guild: Snowflake)
    case getGuildMember(guild: Snowflake, user: Snowflake)
    case getUser(user: Snowflake)
    case getUserProfile(user: Snowflake)
    case getUserSettings
    case acknowledgeMessage(channel: Snowflake, message: Snowflake)
    case createReaction(channel: Snowflake, message: Snowflake, emoji: String)
    case deleteOwnReaction(channel: Snowflake, message: Snowflake, emoji: String)
}

public enum OP: Int {
    case dispatch = 0
    case heartbeat = 1
    case identify = 2
    case presenceUpdate = 3
    case voiceStateUpdate = 4
    case resume = 6
    case reconnect = 7
    case requestGuildMembers = 8
    case invalidSession = 9
    case hello = 10
    case heartbeatACK = 11
    case guildSubscription = 14
}



public enum Intents: Int {
    case guilds = 1
    case guildMembers = 2
    case guildBans = 4
    case guildEmojisAndStickers = 8
    case guildIntegrations = 16
    case guildWebhooks = 32
    case guildInvites = 64
    case guildVoiceStates = 128
    case guildPresences = 256
    case guildMessages = 512
    case guildMessageReactions = 1024
    case guildMessageTyping = 2048
    case directMessages = 4096
    case directMessagesReactions = 8192
    case directMessagesTyping = 16384
    case messageContent = 32768
    case guildScheduledEvents = 65536
}

public enum HTTPMethod: String {
    case get = "GET",
         post = "POST",
         put = "PUT",
         patch = "PATCH",
         delete = "DELETE"
}

public enum Event: String {
    case ready = "READY"
    case guildCreate = "GUILD_CREATE"
    case messageCreate = "MESSAGE_CREATE"
    case messageDelete = "MESSAGE_DELETE"
    case messageUpdate = "MESSAGE_UPDATE"
    case guildMemberListUpdate = "GUILD_MEMBER_LIST_UPDATE"
    case guildMembersChunk = "GUILD_MEMBERS_CHUNK"
    case threadListSync = "THREAD_LIST_SYNC"
    case typingStart = "TYPING_START"
    case presenceUpdate = "PRESENCE_UPDATE"
    case messageReactionAdd = "MESSAGE_REACTION_ADD"
    case messageReactionRemove = "MESSAGE_REACTION_REMOVE"
}


public enum Relationship: Int, Codable {
    case friend = 1
    case blocked = 2
    case pendingIncoming = 3
    case pendingOutgoing = 4
    case unknown = 0
    case implicit = 5
}

public enum PresenceType: String {
    case offline = "offline"
    case dnd = "dnd"
    case online = "online"
    case idle = "idle"
}

public enum EmbedType: String {
    case rich = "rich"
    case image = "image"
}

public enum MessageType: Int {
    case `default` = 0
    case recipientAdd = 1
    case recipientRemove = 2
    case call = 3
    case userJoin = 7
    case reply = 19
}


