//
//  File.swift
//  
//
//  Created by JWI on 16/10/2025.
//

import Foundation
import UIKit

extension Data {
    func base64Encode() -> String {
        return base64EncodedString()
    }
}

extension SLClient {
    public func getSortedDMs(completion: @escaping ([DMChannel], Error?) -> ()) {
        self.getDMs() { dms, error in
            var sortedDMs: [DMChannel] = []
            
            for (_,dm) in dms {
                sortedDMs.append(dm)
            }
            
            sortedDMs.sort(by: {
                let id1 = $0.lastMessageID?.rawValue ?? 0
                let id2 = $1.lastMessageID?.rawValue ?? 0
                return id1 > id2
            })
            
            completion(sortedDMs, nil)
        }
    }
    
    public func send(image: UIImage, withMessage message: Message? = nil, in channel: TextChannel, completion: @escaping (Error?) -> ()) {
        // Swift imports the iOS 2 UIImageJPEGRepresentation function under this name.
        let imageData = image.jpegData(compressionQuality: 0.9)!
        self.send(imageData: imageData, withMessage: message, in: channel, completion: { error in
            
        })
    }
}

public extension UIColor {
    convenience init(discordColor value: Int) {
        let red = CGFloat((value >> 16) & 0xFF) / 255.0
        let green = CGFloat((value >> 8) & 0xFF) / 255.0
        let blue = CGFloat(value & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

public let discordSuperProperties: [String: Any] = {
    let osVersion = UIDevice.current.systemVersion
    let systemLocale = Locale.current.identifier
    let deviceVendorID: String = {
        if #available(iOS 6.0, *) {
            // KVC avoids the custom armv7 compiler's NSUUID return-ABI crash.
            // The property is accessed only on systems that actually implement it.
            if let identifier = UIDevice.current.value(forKey: "identifierForVendor") as? NSObject,
               let value = identifier.value(forKey: "UUIDString") as? String {
                return value
            }
        }
        return UUID().uuidString
    }()
    let device: String = {
        if #available(iOS 14.0, *), UIDevice.current.userInterfaceIdiom == .mac {
            return "Mac"
        }
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return "iPhone"
        case .pad:
            return "iPad"
        default:
            return "iPhone"
        }
    }()
    // Get machine architecture
    var systemInfo = utsname()
    uname(&systemInfo)
    let modelCode = withUnsafePointer(to: &systemInfo.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) {
            ptr in String.init(validatingUTF8: ptr)
        }
    }
    let arch = withUnsafePointer(to: &systemInfo.machine) { ptr in
        ptr.withMemoryRebound(to: CChar.self, capacity: 1) {
            String(cString: $0)
        }
    }
    
    let properties: [String: Any] = [
        "os": "iOS",
        "browser": "Discord iOS",
        "device": modelCode ?? "",
        "system_locale": "en-US",
        "client_version": "0.0.326",
        "release_channel": "stable",
        "device_vendor_id": deviceVendorID,
        "browser_user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) discord/0.0.326 Chrome/128.0.6613.186 Electron/32.2.2 Safari/537.36",
        "browser_version": "32.2.2",
        "os_version": osVersion,
        "os_arch": arch,
        "app_arch": arch,
        "os_sdk_version": "23",
        "client_build_number": 209354,
        "native_build_number": NSNull(),
        "client_event_source": NSNull()
    ]
    
    return properties
}()

public let discordSuperPropertiesBase64: String = {
    let json = try! JSONSerialization.data(withJSONObject: discordSuperProperties)
    return json.base64Encode()
}()

public var userAgent: String {
    // 1. Get iOS version
    let osVersion = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
    
    // 3. Get device model (iPhone/iPad)
    let deviceModel = UIDevice.current.model // e.g., "iPhone"
    
    // 4. Discord app version info
    let discordVersion = "1.0.9211"
    let mobileBuild = "15E148"
    let webkitVersion = "605.1.15"
    let safariVersion = "604.1"
    
    // 5. Construct UA string
    return "Mozilla/5.0 (\(deviceModel); CPU \(deviceModel) OS \(osVersion) like Mac OS X) AppleWebKit/\(webkitVersion) (KHTML, like Gecko) discord/\(discordVersion) Mobile/\(mobileBuild) Safari/\(safariVersion)"
}

public let additionalHeaders: [String: String] = [
    "x-super-properties": discordSuperPropertiesBase64,
    "x-discord-locale": "en-US",
    "Referrer": "https://discord.com/channels/@me",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
    "Host": "discordapp.com",
    "Accept": "*/*"
]

