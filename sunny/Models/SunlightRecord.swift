import Foundation

/// Represents a single day's sunlight data.
struct SunlightRecord: Codable, Equatable {
    let date: Date
    var minutes: Int
    var isComplete: Bool
}