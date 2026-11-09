//
//  File.swift
//  
//
//  Created by JWI on 5/11/2025.
//

import Foundation

extension Gateway {
    public func addGuildMemberChunkObserver(_ observer: @escaping ([Snowflake: GuildMember]) -> Void) {
        guildMemberChunkObservers.append(observer)
    }
    
    public func addPresenceUpdateObserver(_ observer: @escaping ([Snowflake: PresenceType]) -> Void) {
        presenceUpdateObservers.append(observer)
    }

    // Call this when a chunk event arrives
    internal func handleGuildMemberChunk(_ members: [Snowflake: GuildMember]) {
        for observer in guildMemberChunkObservers {
            observer(members)
        }
    }
    
    internal func handlePresenceUpdate(_ presence: [Snowflake: PresenceType]) {
        for observer in presenceUpdateObservers {
            observer(presence)
        }
    }
    
    public func requestGuildMemberChunk(guildId: Snowflake, userIds: Set<Snowflake>, includePresences: Bool = false) {
        guard !userIds.isEmpty else { return }
        
        // Convert user IDs to array of strings
        let userIdsArray = userIds.map { "\($0.rawValue)" }
        
        // Prepare the payload data
        let data: [String: Any] = [
            "guild_id": [ "\(guildId.rawValue)" ],  // Discord expects array of guild IDs
            "user_ids": userIdsArray,
            "presences": includePresences,
            "limit": NSNull(),  // Not used in this mode
            "query": NSNull()   // Not used in this mode
        ]
        
        // Wrap in REQUEST_GUILD_MEMBERS op
        let payload = Payload(op: 8, d: data) // 8 = REQUEST_GUILD_MEMBERS
        send(payload)
        
        print("[Gateway] Requested \(userIds.count) members from guild \(guildId.rawValue)")
    }
}
