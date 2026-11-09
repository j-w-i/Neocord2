import Foundation

extension String {
    
    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
    
    private static let httpFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "E, dd MMM yyyy HH:mm:ss z"
        return formatter
    }()
    
    /// A fully legacy-compatible ISO8601 date parser
    var date: Date? {
        return Self.legacyParseDate(self)
    }
    
    /// HTTP date parser
    var httpDate: Date? {
        // Apply the same cleaning before attempting HTTP parse
        let cleaned = Self.cleanDateString(self)
        return String.httpFormatter.date(from: cleaned)
    }
    
    // MARK: - Legacy parsing
    
    private static func legacyParseDate(_ str: String) -> Date? {
        let cleaned = cleanDateString(str)
        return isoFormatter.date(from: cleaned)
    }
    
    /// Normalises ISO8601-style timestamps for old ICU engines (e.g., iOS 6)
    private static func cleanDateString(_ str: String) -> String {
        var cleaned = str.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove fractional seconds (.SSS or longer)
        if let range = cleaned.range(of: "\\.\\d+", options: .regularExpression) {
            cleaned.removeSubrange(range)
        }
        
        // Replace trailing Z with +0000
        cleaned = cleaned.replacingOccurrences(of: "Z", with: "+0000")
        
        // If timezone contains a colon, remove it (e.g., +10:00 → +1000)
        if let match = cleaned.range(of: "([\\+\\-]\\d{2}):(\\d{2})", options: .regularExpression) {
            cleaned.replaceSubrange(match, with: cleaned[match].replacingOccurrences(of: ":", with: ""))
        }
        
        return cleaned
    }
}
