//
//  File.swift
//
//
//  Created by JWI on 15/10/2025.
//

import Foundation

public struct GroupDM: DMChannel {
    public internal(set) weak var slClient: SLClient?
    
    public let id: Snowflake?
    public var recipients: [User]?
    public let lastMessageID: Snowflake?
    public let type = ChannelType.groupDM
    public let name: String?
    
    
    init?(_ slClient: SLClient, _ json: [String: Any], _ relationships: [Snowflake: (Relationship, String?)]? = nil) {
        self.slClient = slClient
        if let recipients = json["recipients"] as? [[String: Any]] {
            var users: [User] = []
            
            for recipient in recipients {
                let userID = Snowflake(recipient["id"] as? String)
                
                let relationshipInfo = relationships?[userID ?? Snowflake(0)] ?? (.unknown, nil)
                
                users.append(User(slClient, recipient, nickname: relationshipInfo.1, relationship: relationshipInfo.0))
            }
            self.recipients = users
        }
        
        /*if let recipientIDs = json["recipient_ids"] as? [String] {
            var users = [User]()
            let recipientIDs = recipientIDs.compactMap { Snowflake($0) }
            for recipientID in recipientIDs {
                if let user = slClient.users[recipientID] {
                    users.append(user)
                }
            }
            self.recipients = users
        }*/

        
        self.id = Snowflake(json["id"] as? String)
        
        self.name = json["name"] as? String
        
        self.lastMessageID = Snowflake(json["last_message_id"] as? String)
    }
    
    public func convertToDict() -> [String: Any] {
        return [
            "id": self.id?.description ?? "",
            "name": self.name ?? "",
            "last_message_id": self.lastMessageID?.description ?? "",
            "type": self.type.rawValue,
            "recipients": self.recipients?.compactMap { $0.convertToDict() } ?? []
        ]
    }
}
