//
//  File.swift
//  
//
//  Created by JWI on 8/11/2025.
//

import Foundation

public class UserSettings {
    public var guildFolders: [GuildFolder]?
    
    public init(_ slClient: SLClient, _ json: [String: Any]) {
        if let guildFolderStrings = json["guild_folders"] as? [[String: Any]] {
            self.guildFolders = guildFolderStrings.map({ GuildFolder(slClient, $0) })
        }
    }
}
