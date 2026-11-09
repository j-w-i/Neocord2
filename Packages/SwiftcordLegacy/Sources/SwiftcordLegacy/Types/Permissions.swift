//
//  File.swift
//  SwiftcordLegacy
//
//  Created by JWI on 11/12/2025.
//

import Foundation

public struct Permissions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let viewChannel = Permissions(rawValue: 1 << 10)
}

public extension GuildMember {
    var combinedPermissions: Permissions {
        guard let roles = self.roles else { return [] }

        var total = 0

        for role in roles {
            if let perms = role.permissions {
                total |= perms
            }
        }

        return Permissions(rawValue: total)
    }
}



