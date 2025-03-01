import Foundation
import SwiftUI

/// Handles storing/loading user data (like a simplified supabase or local storage).
/// Acts similarly to a context or provider in the webapp.
class UserManager: ObservableObject {
    
    @Published var user: UserProfile
    @Published var dailyRecords: [SunlightRecord] = []
    
    /// Track whether user completed onboarding.
    @Published var didFinishOnboarding: Bool
    
    private let userDefaultsKey = "sunny_user"
    private let recordsKey = "sunny_records"
    private let onboardingKey = "sunny_onboarding"
    
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
    
    /// Start or update today's record by adding minutes of sunlight (sim).
    func trackSunlight(minutes: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let index = dailyRecords.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            // Update existing record
            dailyRecords[index].minutes += minutes
            dailyRecords[index].isComplete = dailyRecords[index].minutes >= user.goalMinutes
        } else {
            // Add new record
            let new = SunlightRecord(date: today,
                                     minutes: minutes,
                                     isComplete: minutes >= user.goalMinutes)
            dailyRecords.append(new)
        }
        saveRecords()
    }
    
    /// Returns how many days in a row user has completed the daily goal.
    func currentStreak() -> Int {
        let calendar = Calendar.current
        // We'll walk backward from today until the chain breaks.
        let sorted = dailyRecords.sorted { $0.date > $1.date }
        
        var streak = 0
        var dayOffset = 0
        
        for rec in sorted {
            // rec.date must be offset from "today" by dayOffset
            let comp = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            let sameDay = calendar.isDate(comp, inSameDayAs: rec.date)
            if sameDay && rec.isComplete {
                streak += 1
                dayOffset += 1
            } else {
                // as soon as we find a day that doesn't match or not complete, break
                break
            }
        }
        
        return streak
    }
    
    /// Returns total days ever completed
    func totalCompleted() -> Int {
        dailyRecords.filter { $0.isComplete }.count
    }
    
    /// Returns the weekly records from Sunday-Saturday
    func weeklyRecords() -> [SunlightRecord] {
        // We'll figure out which day of the week is Sunday -> Saturday
        // For simplicity, assume calendar Sunday as .weekday=1
        let cal = Calendar.current
        let startOfWeek = cal.startOfDay(for: Date())
        let dayOfWeek = cal.component(.weekday, from: startOfWeek)
        
        // We'll gather records for the current Sunday-Saturday window
        // But simpler approach: just build an array of 7 days from Sunday
        var result: [SunlightRecord] = []
        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: offset - (dayOfWeek - 1), to: startOfWeek) else { continue }
            // see if we have a record for that date
            if let rec = dailyRecords.first(where: { cal.isDate($0.date, inSameDayAs: day) }) {
                result.append(rec)
            } else {
                // create a "dummy" record with 0 minutes
                result.append(SunlightRecord(date: day, minutes: 0, isComplete: false))
            }
        }
        return result
    }
    
    /// Retrieve monthly records for a given month-year
    func recordsForMonth(month: Int, year: Int) -> [SunlightRecord] {
        let cal = Calendar.current
        return dailyRecords.filter {
            let comps = cal.dateComponents([.month, .year], from: $0.date)
            return comps.month == month && comps.year == year
        }
    }
    
    /// Mark sign-out logic (for demonstration).
    func signOut() {
        // Clear user & records for demo
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