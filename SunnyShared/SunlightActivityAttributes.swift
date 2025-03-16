
import ActivityKit
import Foundation

/// Shared by the main app + widget extension.
/// We track a startDate for the system `.timer`
/// and an isComplete flag to mark session done.
public struct SunlightActivityAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable {
        /// Whether the session is marked complete
        public var isComplete: Bool
        
        /// The date the session started, used for the system-based `.timer`
        public var startDate: Date
        
        public init(isComplete: Bool, startDate: Date) {
            self.isComplete = isComplete
            self.startDate = startDate
        }
    }
    
    // Add optional static fields if needed.
    public init() { }
}
