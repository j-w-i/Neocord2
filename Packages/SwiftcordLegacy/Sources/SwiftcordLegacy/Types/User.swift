//
//  File.swift
//  
//
//  Created by JWI on 15/10/2025.
//

import Foundation
import UIKit


public class User: Equatable, CustomStringConvertible, DictionaryConvertible {
    public static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
    
    public let id: Snowflake?
    public let username: String?
    public let displayname: String?
    public let discriminator: String?
    public var avatar: UIImage?
    public let avatarString: String?
    public let nickname: String?
    public let relationship: Relationship?
    public var bio: String?
    public var mfaEnabled: Bool
    public var avatarDecorationHash: String?
    
    public init(_ slClient: SLClient, _ json: [String: Any], nickname: String? = nil, relationship: Relationship = .unknown) {
        self.id = Snowflake(json["id"] as? String)
        self.username = json["username"] as? String
        self.displayname = json["global_name"] as? String
        self.discriminator = json["discriminator"] as? String
        self.avatarString = json["avatar"] as? String
        self.mfaEnabled = json["mfa_enabled"] as? Bool ?? false
        self.bio = json["bio"] as? String
        self.avatar = nil
        if let nicknameString = json["nick"] as? String, nickname == nil {
            self.nickname = nicknameString
        } else {
            self.nickname = nickname
        }
        self.relationship = relationship
        if let avatarDecorationJson = json["avatar_decoration_data"] as? [String: Any] {
            self.avatarDecorationHash = avatarDecorationJson["asset"] as? String
        }
    }
    
    public var description: String {
        return """
            User(
                id: \(id?.description ?? "nil"),
                username: \(username ?? "nil"),
                displayname: \(displayname ?? "nil"),
                discriminator: \(discriminator ?? "nil"),
                nickname: \(nickname ?? "nil"),
                mfaEnabled: \(mfaEnabled)
            )
            """
    }
    
    public func convertToDict() -> [String : Any] {
        return [
            "id": self.id?.description ?? "",
            "username": self.username ?? "",
            "global_name": self.displayname ?? NSNull(),
            "discriminator": self.discriminator ?? "",
            "nickname": self.nickname ?? NSNull(),
            "relationship": self.relationship?.rawValue ?? 0,
            "avatar": self.avatarString ?? NSNull()
        ]
    }
}

public struct UserProfile {
    public var pronouns: String?
    public var themeColors: [UIColor]
    public var bannerHash: String?
    public var profileBadges: [ProfileBadge]?
    public var legacyUsername: String?
    public var mutualFriends: [User]?
    public var mutualGuilds: [Guild]?
    
    public init(_ slClient: SLClient, _ json: [String: Any]) {
        self.pronouns = json["pronouns"] as? String
        if let colorInts = json["theme_colors"] as? [Int] {
            self.themeColors = colorInts.map { UIColor(discordColor: $0) }  
        } else {
            self.themeColors = []
        }
        self.bannerHash = json["banner"] as? String
        self.profileBadges = (json["badges"] as? [[String: Any]])?.compactMap { ProfileBadge($0) }
        self.legacyUsername = json["legacy_username"] as? String
    }
}

public struct ProfileBadge {
    public var id: String?
    public var description: String?
    public var icon: String?
    public var link: String?
    
    public init(_ json: [String: Any]) {
        self.id = json["id"] as? String
        self.description = json["description"] as? String
        self.icon = json["icon"] as? String
        self.link = json["link"] as? String
    }
}

public class ClientUser: User {
    public var email: String?
    public var phone: String?
    
    
    public init(_ slClient: SLClient, _ json: [String: Any]) {
        self.phone = json["phone"] as? String
        self.email = json["email"] as? String
        super.init(slClient, json)
    }
}

public class PlaceholderUser: User {
    
    public init(_ slClient: SLClient) {
        let json: [String: Any] = ["id": 0, "username": "unknown"]
        super.init(slClient, json)
    }
}


public struct GuildMember: CustomStringConvertible, DictionaryConvertible {
    public var user: User
    public var guildNickname: String?
    public var roles: [Role]?
    public var guild: Guild?
    
    public var topRole: Role? {
        return roles?.max(by: { $0.position < $1.position })
    }
    
    public var topRoleColor: Role? {
        guard let guild = self.guild else { return nil }
        return roles?
            .compactMap { role in
                // Only use roles that actually exist in the member's guild
                guild.roles[role.id].flatMap { $0.color != UIColor.black ? $0 : nil }
            }
            .max(by: { $0.position < $1.position })
    }


    
    public init(_ slClient: SLClient, _ json: [String: Any], _ guild: Guild) {
        if let userData = json["user"] as? [String: Any] {
            self.user = User(slClient, userData)
        } else {
            self.user = PlaceholderUser(slClient)
        }
        
        self.guildNickname = json["nick"] as? String
        self.roles = []
        self.guild = guild
        if let roleStrings = json["roles"] as? [String] {
            for roleIDString in roleStrings {
                if let roleID = Snowflake(roleIDString),
                   let guild = self.guild,
                   let role = guild.roles[roleID] {
                    if self.roles == nil {
                        self.roles = []
                    }
                    self.roles?.append(role)
                }
            }
            self.roles = self.roles?.sorted(by: { $0.position > $1.position })
        }

    }
    
    public var description: String {
        return """
            GuildMember(
                user: \(user)
                guildNickname: \(guildNickname)
            )
        """
    }
    
    public func convertToDict() -> [String : Any] {
        return [
            "id": self.user.id?.description,
            "nickname": self.guildNickname ?? NSNull()
        ]
    }
}

