//
//  File.swift
//  
//
//  Created by JWI on 20/10/2025.
//

import Foundation

public protocol DictionaryConvertible {
    func convertToDict() -> [String: Any]
}

public protocol Channel: DictionaryConvertible {
    var slClient: SLClient? { get }
    var id: Snowflake? { get }
    var type: ChannelType { get }
}

public protocol TextChannel: Channel {
    var lastMessageID: Snowflake? { get }
}


public enum ChannelType: Int {
    case guildText = 0
    case dm = 1
    case guildVoice = 2
    case groupDM = 3
    case guildCategory = 4
    case guildNews = 5
    case publicThread = 11
    case privateThread = 12
    case guildForum = 15
}

public protocol DMChannel: TextChannel {
    
}

public protocol GuildChannel: TextChannel {
    var guild: Guild? { get set }
    var name: String? { get }
    var position: Int? { get }
    var parentID: Snowflake? { get }
}


