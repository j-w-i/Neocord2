//
//  File.swift
//  
//
//  Created by JWI on 23/11/2025.
//

import Foundation

public struct Embed {
    public let author: User?
    public let type: EmbedType?
    public let title: String?
    public let description: String?
    public let fields: [EmbedField]?
    
    
    public init(_ slClient: SLClient, _ json: [String: Any]) {
        if let authorJson = json["author"] as? [String: Any] {
            self.author = User(slClient, authorJson)
        } else {
            self.author = nil
        }
        self.type = EmbedType(rawValue: json["type"] as! String)
        self.title = json["title"] as? String
        self.description = json["description"] as? String
        if let fieldsJson = json["fields"] as? [[String: Any]] {
            self.fields = fieldsJson.map({ EmbedField($0) })
        } else {
            self.fields = nil
        }
    }
}


public struct EmbedField {
    public let name: String?
    public let value: String?
    public let inline: Bool?
    
    public init(_ json: [String: Any]) {
        self.name = json["name"] as? String
        self.value = json["value"] as? String
        self.inline = {
            if let inlineInt = json["inline"] as? Int {
                if inlineInt == 0 {
                    return false
                } else if inlineInt == 1 {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }()
    }
}
