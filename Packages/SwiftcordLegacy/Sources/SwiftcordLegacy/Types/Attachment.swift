import Foundation
import UIKit

public struct Attachment {
    public let id: Snowflake?
    public let filename: String?
    public let url: URL?
    public let proxyURL: URL?
    public let size: Int?
    public let height: CGFloat?
    public let width: CGFloat?
    public let contentType: String?
    
    public init(_ json: [String: Any]) {

        self.id = Snowflake(json["id"])
        self.filename = json["filename"] as? String
        self.url = (json["url"] as? String).flatMap { URL(string: $0) }
        self.proxyURL = (json["proxy_url"] as? String).flatMap { URL(string: $0) }
        self.size = json["size"] as? Int
        self.height = json["height"] as? CGFloat
        self.width = json["width"] as? CGFloat
        self.contentType = json["content_type"] as? String
    }
}

/*public extension Attachment {
    
    public static let memoryCache = NSCache<NSString, AnyObject>()
    
    /// Fetch this attachment asynchronously with memory caching
    /// - Parameter completion: Called on the main thread with UIImage (if image) or Data (for other files)
    func fetch(completion: @escaping (Any?) -> Void) {
        guard let url = self.url else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        let cacheKey = url.absoluteString as NSString
        
        // Check cache first
        if let cached = Attachment.memoryCache.object(forKey: cacheKey) {
            DispatchQueue.main.async {
                completion(cached)
            }
            return
        }
        
        // Download if not cached
        URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            let result: AnyObject
            if self.contentType?.starts(with: "image") == true, let image = UIImage(data: data) {
                result = image
            } else {
                result = data as AnyObject
            }
            
            // Store in cache
            Attachment.memoryCache.setObject(result, forKey: cacheKey)
            
            DispatchQueue.main.async {
                completion(result)
            }
        }.resume()
    }
}
*/
//Memorysafe


 public extension Attachment {
     
     /// Fetch this attachment asynchronously without caching.
     /// - Parameter completion: Called on the main thread with UIImage (if image) or Data (for other files)
     func fetch(completion: @escaping (Any?) -> Void) {
         guard let url = self.url else {
             DispatchQueue.main.async { completion(nil) }
             return
         }
         
         URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, error in
             guard let data = data, error == nil else {
                 DispatchQueue.main.async { completion(nil) }
                 return
             }
             
             var result: Any?
             if self.contentType?.starts(with: "image") == true {
                 // Decode image inside an autoreleasepool to free memory ASAP
                 autoreleasepool {
                     result = UIImage(data: data)
                 }
             } else {
                 result = data
             }
             
             DispatchQueue.main.async {
                 completion(result)
             }
         }.resume()
     }
 }
 
