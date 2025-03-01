import Foundation

/// A simple user model storing goal minutes, notifications, etc.
struct UserProfile: Codable, Equatable {
    var id: UUID = UUID()
    var email: String = ""
    var fullName: String = ""
    var goalMinutes: Int = 15
    var notificationsEnabled: Bool = true
}