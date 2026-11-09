//
//  File.swift
//  
//
//  Created by JWI on 12/11/2025.
//

import Foundation
import NSJSONSerializationForSwift

extension SLClient {
    public func handleReady(_ data: [String: Any]) {
        // Run all parsing on a background queue
        DispatchQueue.global(priority: .high).async {
            self.logger.log("Parsing READY payload")
            self.gateway?.sessionId = data["session_id"] as? String
            
            // --- Begin heavy parsing ---
            if let userData = data["user"] as? [String: Any] {
                self.clientUser = ClientUser(self, userData)
            }
            
            autoreleasepool {
                if let settingsData = data["user_settings"] as? [String: Any] {
                    self.clientUserSettings = UserSettings(self, settingsData)
                }
            }

            autoreleasepool {
                if let relationshipsArray = data["relationships"] as? [[String: Any]] {
                    var rels: [Snowflake: (Relationship, String?)] = [:]
                    for r in relationshipsArray {
                        if let id = r["id"] as? String, let type = r["type"] as? Int {
                            let userID = Snowflake(id)!
                            let relType = Relationship(rawValue: type) ?? .unknown
                            let nickname = r["nickname"] as? String
                            rels[userID] = (relType, nickname)
                        }
                    }
                    self.relationships = rels
                }
            }
    

            var users: [String: [String: Any]] = [:]
            autoreleasepool {
                if let usersArray = data["users"] as? [[String: Any]] {
                    for userJSON in usersArray {
                        if let id = userJSON["id"] as? String {
                            users[id] = userJSON
                        }
                    }
                    
                    let userObjectArray = usersArray.map { User(self, $0) }
                    self.friends = []
                    for user in userObjectArray {
                        if let userID = user.id, let relationship = self.relationships[userID], relationship.0 == .friend {
                            self.friends.append(user)
                        }
                    }
                }
            }
            
            /*self.users = Dictionary(
                users.values.compactMap { user in
                    let user = User(self, user)
                    return user.id.map { ($0, user) }
                },
                uniquingKeysWith: { _, new in new }
            )*/
            
            autoreleasepool {
                if let privateChannels = data["private_channels"] as? [[String: Any]] {
                    for channel in privateChannels {
                        guard let type = channel["type"] as? Int else { continue }

                        switch type {
                        case 1:
                            var channelJSON = channel
                            if let recipientIDs = channel["recipient_ids"] as? [String] {
                                let recipientsJSON = recipientIDs.compactMap { users[$0] }
                                channelJSON["recipients"] = recipientsJSON
                            }

                            if let dm = DM(self, channelJSON, self.relationships) {
                                self.dms[dm.id!] = dm

                            }

                        case 3:
                            var channelJSON = channel
                            if let recipientIDs = channel["recipient_ids"] as? [String] {
                                let recipientsJSON = recipientIDs.compactMap { users[$0] }
                                channelJSON["recipients"] = recipientsJSON
                            }
                            if let groupDM = GroupDM(self, channelJSON) {
                                self.dms[groupDM.id!] = groupDM
                            }

                        default: break
                        }
                    }
                }
            }

            autoreleasepool {
                if let guildsArray = data["guilds"] as? [[String: Any]] {
                    for guildData in guildsArray {
                        let guild = Guild(self, guildData)
                        self.guilds[(guild?.id)!] = guild
                    }
                }
            }
            
            autoreleasepool {
                if let merged = data["merged_presences"] as? [String: Any] {

                    var flat: [[String: Any]] = []

                    // FRIENDS
                    if let friends = merged["friends"] as? [[String: Any]] {
                        flat.append(contentsOf: friends)
                    }

                    // GUILDS
                    if let guilds = merged["guilds"] as? [Any] {
                        for item in guilds {
                            if let group = item as? [[String: Any]] {
                                flat.append(contentsOf: group)
                            }
                        }
                    }

                    // PROCESS
                    for presence in flat {

                        guard
                            let userId = presence["user_id"] as? String,
                            let statusString = presence["status"] as? String,
                            let presenceType = PresenceType(rawValue: statusString)
                        else { continue }

                        guard let userID = Snowflake(userId) else { continue }

                        self.presences[userID] = presenceType
                    }
                }
            }


            // --- End heavy parsing ---

            // Save cache on background as well
            self.saveCache()

            // Once everything is ready, return to main queue
            DispatchQueue.main.async {
                self.onReady?()
                NotificationCenter.default.post(name: .readyProcessed, object: nil)
            }
        }
    }
}
