//
//  File.swift
//  
//
//  Created by JWI on 15/10/2025.
//

import Foundation



public struct DM: DMChannel {
    public internal(set) weak var slClient: SLClient?
    
    public let id: Snowflake?
    public var recipient: User?
    public let lastMessageID: Snowflake?
    public let type = ChannelType.dm
    
    
    
    init?(_ slClient: SLClient, _ json: [String: Any], _ relationships: [Snowflake: (Relationship, String?)]? = nil) {
        self.slClient = slClient
        let recipients = json["recipients"] as? [[String: Any]]
        
        if let recipients = recipients {
            let recipientJSON = recipients[0]
            let userID = Snowflake(recipientJSON["id"] as? String)
            //Construct the tuple containing the relationship type and the username if it exists, yes, the optional syntax is a bit confusing, but it's safe
            let relationshipInfo = relationships?[userID ?? Snowflake(0)] ?? (.unknown, nil)
            
            self.recipient = User(slClient, recipientJSON, nickname: relationshipInfo.1, relationship: relationshipInfo.0)
        } else {
            self.recipient = nil
        }
        
        self.id = Snowflake(json["id"] as? String)
        
        self.lastMessageID = Snowflake(json["last_message_id"] as? String)
    }
    
    public func convertToDict() -> [String: Any] {
        return [
            "id": id?.description ?? "",
            "last_message_id": lastMessageID?.description ?? "",
            "type": type.rawValue,
            "recipients": [recipient?.convertToDict()]
        ]
    }
}
