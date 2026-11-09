//
//  File.swift
//  
//
//  Created by JWI on 8/11/2025.
//

import Foundation
import UIKit

public class GuildFolder {
    public var id: Int?
    public var name: String?
    public var guildIDs: [Snowflake]?
    public var opened: Bool?
    public var color: UIColor?
    
    public init(_ slClient: SLClient, _ json: [String: Any]) {
        self.id = json["id"] as? Int
        self.name = json["name"] as? String
        
        if let guildIDStrings = (json["guild_ids"] as? [String]) {
            self.guildIDs = guildIDStrings.map { Snowflake($0)! }
        }
        if let colorInt = json["color"] as? Int {
            self.color = UIColor(discordColor: colorInt)
        }
        
    }
    
    
}
