import Foundation
import SwiftUI

/// Handles storing/loading user data (like a simplified supabase or local storage).
/// Acts similarly to a context or provider in the webapp.
class UserManager: ObservableObject {
    
    @Published var user: UserProfile
    @Published var dailyRecords: [SunlightRecord] = []
    
    /// Track whether user completed onboarding.
    @Published var didFinishOnboarding: Bool
    
    private let userDefaultsKey = "sunny_soul_user"
    private let recordsKey = "sunny_soul_records"
    private let onboardingKey = "sunny_soul_onboarding"
    
    init() {
        // Load from UserDefaults or use defaults.
        if let storedUserData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedUser = try? JSONDecoder().decode(UserProfile.self, from: storedUserData) {
            self.user = decodedUser
        } else {
            // Default user
            self.user = UserProfile(
                email: "user@example.com",
                fullName: "Demo User",
                goalMinutes: 15,
                notificationsEnabled: true
            )
        }
        
        // Load daily records
        if let storedRecordsData = UserDefaults.standard.data(forKey: recordsKey),
           let decodedRecords = try? JSONDecoder().decode([SunlightRecord].self, from: storedRecordsData) {
            self.dailyRecords = decodedRecords
        }
        
        // Check if onboarding is complete
        let hasOnboarded = UserDefaults.standard.bool(forKey: onboardingKey)
        self.didFinishOnboarding = hasOnboarded
    }
    
    func saveUser() {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func saveRecords() {
        if let encoded = try? JSONEncoder().encode(dailyRecords) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
    }
    
    func completeOnboarding() {
        self.didFinishOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }
    
    // MARK: - Goal/Notifications
    func updateGoalMinutes(to minutes: Int) {
        user.goalMinutes = minutes
        saveUser()
    }
    
    func updateNotificationsEnabled(_ enabled: Bool) {
        user.notificationsEnabled = enabled
        saveUser()
    }
    
    // MARK: - Sunlight Recording
    
    func trackSunlight(minutes: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let index = dailyRecords.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            dailyRecords[index].minutes += minutes
            dailyRecords[index].isComplete = dailyRecords[index].minutes >= user.goalMinutes
        } else {
            let new = SunlightRecord(date: today,
                                     minutes: minutes,
                                     isComplete: minutes >= user.goalMinutes)
            dailyRecords.append(new)
        }
        saveRecords()
    }
    
    func currentStreak() -> Int {
        let calendar = Calendar.current
        let sorted = dailyRecords.sorted { $0.date > $1.date }
        
        var streak = 0
        var dayOffset = 0
        
        for rec in sorted {
            let comp = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            let sameDay = calendar.isDate(comp, inSameDayAs: rec.date)
            if sameDay && rec.isComplete {
                streak += 1
                dayOffset += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    func totalCompleted() -> Int {
        dailyRecords.filter { $0.isComplete }.count
    }
    
    func weeklyRecords() -> [SunlightRecord] {
        let cal = Calendar.current
        let startOfWeek = cal.startOfDay(for: Date())
        let dayOfWeek = cal.component(.weekday, from: startOfWeek)
        
        var result: [SunlightRecord] = []
        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: offset - (dayOfWeek - 1), to: startOfWeek) else { continue }
            if let rec = dailyRecords.first(where: { cal.isDate($0.date, inSameDayAs: day) }) {
                result.append(rec)
            } else {
                result.append(SunlightRecord(date: day, minutes: 0, isComplete: false))
            }
        }
        return result
    }
    
    func recordsForMonth(month: Int, year: Int) -> [SunlightRecord] {
        let cal = Calendar.current
        return dailyRecords.filter {
            let comps = cal.dateComponents([.month, .year], from: $0.date)
            return comps.month == month && comps.year == year
        }
    }
    
    func signOut() {
        user = UserProfile(
            email: "user@example.com",
            fullName: "Demo User",
            goalMinutes: 15,
            notificationsEnabled: true
        )
        dailyRecords = []
        didFinishOnboarding = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: recordsKey)
        UserDefaults.standard.removeObject(forKey: onboardingKey)
    }
}