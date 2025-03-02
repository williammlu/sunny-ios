import XCTest
@testable import sunny

final class sunnyTests: XCTestCase {

    func testUserDefaultsStorage() {
        let manager = UserManager()
        let initialGoal = manager.user.goalMinutes
        
        manager.updateGoalMinutes(to: 25)
        let loadedManager = UserManager()
        XCTAssertEqual(loadedManager.user.goalMinutes, 25, "Goal minutes should persist across sessions")
        
        // Reset
        manager.updateGoalMinutes(to: initialGoal)
    }
    
    func testStreakCalculation() {
        let manager = UserManager()
        manager.signOut() // Clear everything
        manager.updateGoalMinutes(to: 15)
        
        // Add 3 days of completed data
        let dayOffsets = [0, 1, 2]
        for offset in dayOffsets {
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            manager.dailyRecords.append(
                SunlightRecord(
                    date: date,
                    minutes: 15,
                    isComplete: true
                )
            )
        }
        manager.saveRecords()
        
        let streak = manager.currentStreak()
        XCTAssertEqual(streak, 3, "Should count a 3-day streak")
        
        manager.signOut()
    }
}