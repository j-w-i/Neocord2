//
//  File.swift
//  
//
//  Created by JWI on 22/10/2025.
//

import Foundation

public typealias EndpointInfo = (method: HTTPMethod, url: String)

extension Endpoint {
    var httpInfo: EndpointInfo {
        switch self {
        case .getDMChannels:
            return(.get, "/users/@me/channels")
        case let .getMessages(channelID):
            return(.get, "/channels/\(channelID)/messages?limit=50")
        case let .getMessagesBefore(messageID, channelID, limit):
            return (.get, "/channels/\(channelID)/messages?before=\(messageID)&limit=\(limit)")
        case .getGuilds:
            return (.get, "/users/@me/guilds")
        case .getClientUser:
            return (.get, "/users/@me")
        case let .sendMessage(channel):
            return (.post, "/channels/\(channel)/messages")
        case .getRelationships:
            return (.get, "/users/@me/relationships")
        case let .deleteMessage(channel, message):
            return (.delete, "/channels/\(channel)/messages/\(message)")
        case let .editMessage(channel, message):
            return (.patch, "/channels/\(channel)/messages/\(message)")
        case let .getGuildChannels(guild):
            return (.get, "/guilds/\(guild)/channels")
        case let .getGuild(guild):
            return (.get, "/guilds/\(guild)")
        case let .getGuildMember(guild, user):
            return (.get, "/guilds/\(guild)/members/\(user)")
        case let .getChannel(channel):
            return (.get, "/channels/\(channel)")
        case let .getUser(user):
            return (.get, "/users/\(user)")
        case let .getUserProfile(user):
            return (.get, "/users/\(user)/profile")
        case .getUserSettings:
            return (.get, "/users/@me/settings")
        case let .acknowledgeMessage(channel, message):
            return (.post, "/channels/\(channel)/messages/\(message)/ack")
        case let .createReaction(channel, message, emoji):
            return (.put, "/channels/\(channel)/messages/\(message)/reactions/\(emoji)/@me")
        case let .deleteOwnReaction(channel, message, emoji):
            return (.delete, "/channels/\(channel)/messages/\(message)/reactions/\(emoji)/0/@me")
        }
    }
}
