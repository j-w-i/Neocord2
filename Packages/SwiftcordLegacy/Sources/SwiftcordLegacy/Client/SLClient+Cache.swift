import Foundation
import UIKit
import NSJSONSerializationForSwift

// MARK: - UIColor ARGB Conversion
public extension UIColor {
    var argbInt: Int {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let ai = Int(a * 255) << 24
        let ri = Int(r * 255) << 16
        let gi = Int(g * 255) << 8
        let bi = Int(b * 255)
        
        return ai | ri | gi | bi
    }
    
    convenience init(argbInt: Int) {
        let a = CGFloat((argbInt >> 24) & 0xFF) / 255
        let r = CGFloat((argbInt >> 16) & 0xFF) / 255
        let g = CGFloat((argbInt >> 8) & 0xFF) / 255
        let b = CGFloat(argbInt & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}


// MARK: - Cache Manager
public class CacheManager {

    private let fileName: String
    private static let cacheQueue = DispatchQueue(label: "com.slclient.cacheQueue")

    public init(fileName: String = "SLClientCache.json") {
        self.fileName = fileName
    }

    private var filePath: String {
        let dirs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let dir = dirs.first!
        return dir + "/" + fileName
    }

    // MARK: - Save
    public func save(client: SLClient) {
        Self.cacheQueue.async {
            var cacheDict: [String: Any] = [:]

            // Snapshot copies to avoid concurrent mutation
            let dmsCopy = client.dms
            let guildsCopy = client.guilds
            let relCopy = client.relationships
            let settingsCopy = client.clientUserSettings

            // DMs
            var dmDict: [String: [String: Any]] = [:]
            for (id, dmChannel) in dmsCopy {
                if dmChannel.type == .dm, let dm = dmChannel as? DM {
                    dmDict[id.description] = dm.convertToDict()
                } else if dmChannel.type == .groupDM, let gdm = dmChannel as? GroupDM {
                    dmDict[id.description] = gdm.convertToDict()
                }
            }
            cacheDict["dms"] = dmDict

            // Guilds
            var guildDict: [String: [String: Any]] = [:]
            for (id, guild) in guildsCopy {
                guildDict[id.description] = guild.convertToDict()
            }
            cacheDict["guilds"] = guildDict

            // Relationships
            var relDict: [String: [String: Any]] = [:]
            for (id, (rel, nickname)) in relCopy {
                relDict[id.description] = [
                    "type": rel.rawValue,
                    "nickname": nickname ?? NSNull()
                ]
            }
            cacheDict["relationships"] = relDict

            // User settings
            if let settings = settingsCopy {
                var foldersArray: [[String: Any]] = []
                if let guildFolders = settings.guildFolders {
                    for folder in guildFolders {
                        let folderDict: [String: Any] = [
                            "id": folder.id ?? 0,
                            "name": folder.name ?? "",
                            "guild_ids": folder.guildIDs?.map { $0.description } ?? [],
                            "opened": folder.opened ?? false,
                            "color": folder.color?.argbInt ?? NSNull()
                        ]
                        foldersArray.append(folderDict)
                    }
                }
                cacheDict["userSettings"] = [
                    "guild_folders": foldersArray
                ]
            }

            // Write to disk safely
            do {
                try autoreleasepool {
                    let data = try JSONSerialization.data(withJSONObject: cacheDict, options: [])
                    let nsData = data as NSData
                    try nsData.write(to: URL(fileURLWithPath: self.filePath), options: .atomic)
                }
                client.logger.log("Cache saved successfully.")
            } catch {
                client.logger.log("Error saving cache: \(error)")
            }
        }
    }

    // MARK: - Load
    public func load(client: SLClient, completion: @escaping () -> Void) {
        Self.cacheQueue.async {
            guard FileManager.default.fileExists(atPath: self.filePath),
                  let jsonString = try? String(contentsOfFile: self.filePath, encoding: .utf8),
                  let json = JSONHelper.parseJSON(jsonString) else {
                DispatchQueue.main.async {
                    client.logger.log("No cache found.")
                    completion()
                }
                return
            }
            // Relationships
            if let cachedRelationships = json["relationships"] as? [String: [String: Any]] {
                var rels: [Snowflake: (Relationship, String?)] = [:]
                for (id, dict) in cachedRelationships {
                    if let typeRaw = dict["type"] as? Int {
                        let relType = Relationship(rawValue: typeRaw) ?? .unknown
                        let nickname = dict["nickname"] as? String
                        rels[Snowflake(id)!] = (relType, nickname)
                    }
                }
                client.relationships = rels
            }

            // User Settings
            if let settingsJSON = json["userSettings"] as? [String: Any] {
                client.clientUserSettings = UserSettings(client, settingsJSON)
            }

            // Guilds
            if let cachedGuilds = json["guilds"] as? [String: [String: Any]] {
                for (id, guildJSON) in cachedGuilds {
                    let guild = Guild(client, guildJSON)
                    client.guilds[Snowflake(id)!] = guild
                }
            }

            // DMs
            if let cachedDMs = json["dms"] as? [String: [String: Any]] {
                for (id, dmJSON) in cachedDMs {
                    guard let recipients = dmJSON["recipients"] as? [[String: Any]], !recipients.isEmpty else {
                        print("Skipping DM \(id) with no recipients")
                        continue
                    }

                    if dmJSON["type"] as! Int != 3, let dm = DM(client, dmJSON, client.relationships) {
                        client.dms[Snowflake(id)!] = dm
                    } else if let gdm = GroupDM(client, dmJSON, client.relationships) {
                        client.dms[Snowflake(id)!] = gdm
                    } else {
                        print("failed to load dm \(id)")
                    }
                }
            }

            DispatchQueue.main.async {
                client.logger.log("Cache loaded successfully.")
                completion()
            }
        }
    }

    // MARK: - Clear
    public func clearCache() {
        Self.cacheQueue.async {
            let path = self.filePath
            if FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                    print("Cache cleared successfully.")
                } catch {
                    print("Failed to clear cache: \(error)")
                }
            } else {
                print("No cache file found to clear.")
            }
        }
    }
}


// MARK: - SLClient Extension
extension SLClient {
    public var cacheManager: CacheManager {
        return CacheManager()
    }

    public func saveCache() {
        self.cacheManager.save(client: self)
    }

    public func loadCache(_ completion: @escaping () -> ()) {
        self.cacheManager.load(client: self, completion: completion)
    }

    public func clearCache() {
        cacheManager.clearCache()
    }
}
