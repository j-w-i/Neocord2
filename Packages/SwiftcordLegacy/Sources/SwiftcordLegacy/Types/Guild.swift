import Foundation

public class Guild: DictionaryConvertible, CustomStringConvertible {
    public let id: Snowflake?
    public let name: String?
    public let icon: String?
    public let slClient: SLClient?
    public var members = [Snowflake: GuildMember]()
    public var roles = [Snowflake: Role]()
    public var channels = [Snowflake: GuildChannel]()
    public var fullGuild: Bool = false

    public init?(_ slClient: SLClient, _ json: [String: Any]) {
        self.slClient = slClient
        self.id = Snowflake(json["id"] as! String)
        self.name = json["name"] as? String
        self.icon = json["icon"] as? String
        if let roleArray = json["roles"] as? [[String: Any]] {
            for roleJson in roleArray {
                let role = Role(roleJson)
                self.roles[role.id] = role
            }
        }
        
        if let channelArray = json["channels"] as? [[String: Any]] {

            // First pass: create categories
            for channelJson in channelArray {
                guard let typeInt = channelJson["type"] as? Int,
                      let type = ChannelType(rawValue: typeInt) else { continue }

                switch type {
                case .guildCategory:
                    var category = GuildCategory(slClient, channelJson)
                    category.guild = self
                    self.channels[category.id!] = category
                    category.channels = [:]     // ensure child dictionary exists
                default:
                    break
                }
            }

            // Second pass: create non-category channels and attach them to parents
            for channelJson in channelArray {
                guard let typeInt = channelJson["type"] as? Int,
                      let type = ChannelType(rawValue: typeInt) else { continue }

                switch type {

                case .guildText, .guildNews:
                    var channel = GuildText(slClient, channelJson)
                    channel.guild = self
                    self.channels[channel.id!] = channel

                    if let parentID = channel.parentID, let parent = self.channels[parentID] as? GuildCategory {
                        parent.channels[channel.id!] = channel
                    }

                case .guildForum:
                    let forum = GuildForum(slClient, channelJson)
                    forum.guild = self
                    self.channels[forum.id!] = forum

                    if let parentID = forum.parentID, let parent = self.channels[parentID] as? GuildCategory {
                        parent.channels[forum.id!] = forum
                    }

                case .guildCategory:
                    break

                default:
                    break
                }
            }
        }

    }
    public var description: String {
            return "Guild(id: \(id?.description ?? "nil"), name: \(name ?? "nil"), icon: \(icon ?? "nil"), roles: \(roles.count), members: \(members.count), channels: \(channels.count), fullGuild: \(fullGuild))"
        }
    
    public func convertToDict() -> [String: Any] {
        return [
            "id": self.id?.description ?? "",
            "name": self.name ?? "",
            "icon": self.icon ?? NSNull(),
            //"roles": self.roles.values.map { $0.convertToDict() }
            //"members": self.members.values.map { $0.convertToDict() },
            //"channels": self.channels.values.map { $0.convertToDict() }
        ]
    }
}
