//
//  File.swift
//  
//
//  Created by JWI on 1/11/2025.
//

import Foundation

extension SLClient {
    public func getUserGuilds(completion: @escaping ([Snowflake: Guild], Error?) -> ()) {
        self.request(.getGuilds) { data, error in
            let guildArray = data as? [[String: Any]]
            
            guard let guildArray = guildArray else { return }
            
            for guild in guildArray {
                
                let guild = Guild(self, guild)
                guard let guild = guild else {
                    return
                }
                
                self.guilds[guild.id!] = guild
            }
            
            completion(self.guilds, nil)
        }
    }
    
    
    public func getGuildMember(_ guild: Guild, _ user: User, completion: @escaping (GuildMember?, Error?) -> ()) {
        guard let guildMemberID = user.id else { return }
        let guildMembers = guild.members
        // Check if the member already exists
        if let existingMember = guildMembers[guildMemberID] {
            completion(existingMember, nil)
            return
        }
        
        // Otherwise, fetch from API
        guard let guildID = guild.id else { return }
        
        self.request(.getGuildMember(guild: guildID, user: guildMemberID)) { data, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let memberData = data as? [String: Any] else {
                completion(nil, nil)
                return
            }
            
            let guildMember = GuildMember(self, memberData, guild)
            // Add to guild dictionary
            guild.members[guildMemberID] = guildMember
            completion(guildMember, nil)
        }
    }
    
    
    
    public func getFullGuild(_ guild: Guild, completion: @escaping ([Snowflake: Guild], Error?) -> ()) {
        if let guildID = guild.id, let guild = self.guilds[guildID], guild.fullGuild {
            completion([guildID: guild], nil)
        }
        
        self.request(.getGuild(guild: guild.id!)) { data, error in
            let guildData = data as? [String: Any]
            guard let guildData = guildData else { return }
            let guild = Guild(self, guildData)
            let guildID = guild?.id
            guard let guild = guild, let guildID = guildID else { return }
            guild.fullGuild = true
            let guildDict: [Snowflake: Guild] = [guildID: guild]
            self.guilds.merge(guildDict) { _, new in new }
            completion(guildDict, nil)
        }
    }
    
    public func subscribeToChannel(_ guild: Guild, _ channel: GuildChannel) {
        self.gateway?.subscribeToGuildChannel(guildId: guild.id!, channelId: channel.id!)
    }
    
    public func getGuildChannels(for guildId: Snowflake, completion: @escaping ([GuildChannel], Error?) -> ()) {
        if let channels = self.guilds[guildId]?.channels.values.map({ $0 }), !channels.isEmpty {
            print("found full channel cache, \(channels.count)")
            completion(channels, nil)
            return
        }
        
        
        self.request(.getGuildChannels(guild: guildId)) { data, error in
            guard let channelArray = data as? [[String: Any]] else {
                completion([], error)
                return
            }
            
            var channels: [GuildChannel] = []
            
            // Ensure the guild exists and its channels dictionary is initialized
            guard let guild = self.guilds[guildId] else {
                completion([], error)
                return
            }
            
            // First pass: create categories and add them to guild.channels
            for channelData in channelArray {
                switch ChannelType(rawValue: channelData["type"] as? Int ?? 0) {
                case .guildCategory:
                    let category = GuildCategory(self, channelData)
                    channels.append(category)
                    guild.channels[category.id!] = category
                    category.channels = [:] // initialize child channels dictionary
                default: break
                }
            }
            
            // Second pass: create text channels and assign to parent categories if possible
            for channelData in channelArray {
                switch ChannelType(rawValue: channelData["type"] as? Int ?? 0) {
                case .guildText:
                    let textChannel = GuildText(self, channelData)
                    channels.append(textChannel)
                    guild.channels[textChannel.id!] = textChannel
                    
                    // Assign to parent category if exists
                    if let parentID = textChannel.parentID,
                       let parentCategory = guild.channels[parentID] as? GuildCategory {
                        parentCategory.channels[textChannel.id!] = textChannel
                    }
                case .guildForum:
                    let guildForum = GuildForum(self, channelData)
                    channels.append(guildForum)
                    guild.channels[guildForum.id!] = guildForum
                    
                    // Assign to parent category if exists
                    if let parentID = guildForum.parentID,
                       let parentCategory = guild.channels[parentID] as? GuildCategory {
                        parentCategory.channels[guildForum.id!] = guildForum
                    }
                default: break
                }
            }
            completion(channels, nil)
        }
    }
    
    
    public func getGuildChannels(for guild: Guild, completion: @escaping ([GuildChannel], Error?) -> ()) {
        guard let guildID = guild.id else { return }
        self.getGuildChannels(for: guildID) { channels, error in
            completion(channels, nil)
        }
    }
}

extension SLClient {
    public func getForumThreads(for forum: GuildForum, completion: @escaping ([GuildThread]) -> ()) {
        completion(Array(forum.threads.values))
    }
}

