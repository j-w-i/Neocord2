//
//  File.swift
//  
//
//  Created by JWI on 15/10/2025.
//

import Foundation

/// Swiftcord Legacy client class
/// Main class for any Discord related actions
public final class SLClient {
    /// Authentication token, stored as a string
    public let token: String
    public let session: URLSession
    public let sessionConfig: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = additionalHeaders
        return config
    }()
    
    /// Gateway object, used for realtime websocket communication with Discord, backed by SocketRocket
    public var gateway: Gateway?
    
    /// The ClientUser object associated with the token provided
    public var clientUser: ClientUser?
    
    /// A global storage of the clientUser's DMs
    public var dms = [Snowflake: DMChannel]()
    
    /// A global storage of the clientUser's Guilds
    public var guilds = [Snowflake: Guild]()
    
    public var presences = [Snowflake: PresenceType]()
    
    public let logger = LegacyLogger(fileName: "rest logs")
    
    /// The UserSettings object associated with the clientUser
    public var clientUserSettings: UserSettings?
    
    /// A global storage of the clientUser's relationships
    public var relationships = [Snowflake: (Relationship, String?)]()
    
    /// A global storage of the clientUser's friends
    public var friends = [User]()
    
    //public var users = [Snowflake: User]()
    
    public lazy var sortedDMs: [DMChannel] = dms.values.sorted { dm1, dm2 in
        let id1 = dm1.lastMessageID?.rawValue ?? 0
        let id2 = dm2.lastMessageID?.rawValue ?? 0
        return id1 > id2
    }
    
    public var onReady: (() -> Void)?

    /// Initialise the SLClient object with a token, beginning the Gateway connection to Discord and fetching the clientUser object
    public init(token: String) {
        self.token = token
        
        self.session = URLSession(configuration: self.sessionConfig)
        
        self.getClientUser() { user, error in
            
        }
    }
    
    /// Directly open a Gateway connection, destorying any previous one
    public func connect() {
        if let gateway = gateway {
            gateway.stop()

        }
        self.gateway = Gateway(self, token: self.token)
        self.gateway?.start()
        
    }
    
    /// End the current Gateway connection, and destroy the Gateway object associated with it
    public func disconnect() {
        if let gateway = gateway {
            gateway.stop()
        }
        
        self.gateway = nil
    }
    
    /// Fetch a User object from a UserID (Snowflake)
    public func getUser(withID userID: Snowflake, completion: @escaping (User, Error?) -> ()) {
        self.request(.getUser(user: userID)) { data, error in
            guard let userData = data as? [String: Any] else { return }
            let user = User(self, userData)
            completion(user, nil)
        }
    }
    
    /// Fetch a UserProfile object from a UserID (Snowflake)
    public func getUserProfile(withID userID: Snowflake, completion: @escaping (User, UserProfile, Error?) -> ()) {
        self.request(.getUserProfile(user: userID)) { data, error in
            guard let jsonData = data as? [String: Any] else { return }
            guard let userData = jsonData["user"] as? [String: Any] else { return }
            let user = User(self, userData)
            guard let profileData = jsonData["user_profile"] as? [String: Any] else { return }
            let userProfile = UserProfile(self, profileData)
            print(userProfile)
            completion(user, userProfile, nil)
        }
    }
    
    
    public func getClientUser(completion: @escaping (ClientUser, Error?) -> ()) {
        self.request(.getClientUser) { data, error in
            if let data = data {
                let clientUser = data as? [String: Any]
                guard let clientUser = clientUser else { return }
                
                self.clientUser = ClientUser(self, clientUser)
                completion(self.clientUser ?? ClientUser(self, clientUser), nil)
            }
        }
    }
    
    ///Function to get the current users relationships, returns a dictionary that has a UserID lookup and a tuple containing the relationship status and nickname (if applicable)
    public func getRelationships(completion: @escaping ([Snowflake: (Relationship, String?)], Error?) -> ()) {
        self.request(.getRelationships) { data, error in
            guard let relationshipsArray = data as? [[String: Any]] else { return }
            
            //Relationships are a dictionary composed of a userID to lookup, a relationship type, and a nickname if the nickname exists
            var relationships: [Snowflake: (Relationship, String?)] = [:]
            
            for relationship in relationshipsArray {
                if let id = relationship["id"] as? String, let typeInt = relationship["type"] as? Int {
                    let type = Relationship(rawValue: typeInt) ?? .unknown
                    let userID = Snowflake(id)!
                    let nickname = relationship["nickname"] as? String
                    relationships[userID] = (type, nickname)
                }
            }
            self.relationships = relationships
            completion(relationships, nil)
        }
    }
    
    public func getClientUserSettings(completion: @escaping (UserSettings, Error?) -> ()) {
        self.request(.getUserSettings) { settings, error in
            guard let settingsJson = settings as? [String: Any] else { return }
            let userSettings = UserSettings(self, settingsJson)
            self.clientUserSettings = userSettings
            completion(userSettings, nil)
        }
    }
    
    public func create(reaction: Reaction, in channel: Snowflake, on message: Snowflake , completion: @escaping ((Error?) -> ())) {
        guard let emoji = reaction.emoji else { return }
        var emojiString: String
        if let emojiID = emoji.id?.description, let emojiName = emoji.name {
            emojiString = "\(emojiName):\(emojiID)"
        } else if let emojiName = emoji.name {
            emojiString = (emojiName as NSString).addingPercentEscapes(using: String.Encoding.utf8.rawValue) ?? emojiName
        } else {
            emojiString = ""
        }
        self.request(.createReaction(channel: channel, message: message, emoji: emojiString)) { _, _ in
            completion(nil)
        }
    }
    
    public func delete(ownReaction: Reaction, in channel: Snowflake, on message: Snowflake , completion: @escaping ((Error?) -> ())) {
        guard let emoji = ownReaction.emoji else { return }
        var emojiString: String
        if let emojiID = emoji.id?.description, let emojiName = emoji.name {
            emojiString = "\(emojiName):\(emojiID)"
        } else if let emojiName = emoji.name {
            emojiString = (emojiName as NSString).addingPercentEscapes(using: String.Encoding.utf8.rawValue) ?? emojiName
        } else {
            emojiString = ""
        }
        self.request(.deleteOwnReaction(channel: channel, message: message, emoji: emojiString)) { _, _ in
            completion(nil)
        }
    }
}




