import SwiftUI

struct StreakDashboardView: View {
    
    @EnvironmentObject var userManager: UserManager
    
    // We'll simulate "start tracking" by simply navigating to a .tracking tab or a dedicated screen.
    var onStartTracking: () -> Void
    
    var body: some View {
        VStack {
            Text("Your Sunshine Journey")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 16)
            
            Text("Maintain your daily sunlight routine")
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            // Streak card
            VStack(spacing: 16) {
                Text("Current Streak")
                    .font(.headline)
                Text("\(userManager.currentStreak()) days")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                
                if let todayRecord = userManager.dailyRecords.first(where: { Calendar.current.isDateInToday($0.date) }) {
                    if !todayRecord.isComplete && todayRecord.minutes > 0 {
                        Text("Today: \(todayRecord.minutes) min logged")
                            .font(.subheadline)
                            .padding(.top, 4)
                        Text("Need \(max(0, userManager.user.goalMinutes - todayRecord.minutes)) more min to complete today")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else if !todayRecord.isComplete {
                        Text("No minutes logged yet today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Today's goal completed!")
                            .foregroundColor(.green)
                    }
                } else {
                    Text("No minutes logged yet today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
            .padding(.horizontal)
            
            // Weekly progress
            VStack(alignment: .leading, spacing: 8) {
                Text("Weekly Progress")
                    .font(.headline)
                let recs = userManager.weeklyRecords()
                HStack(spacing: 8) {
                    ForEach(recs, id: \.date) { rec in
                        VStack {
                            Text(shortWeekday(rec.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Circle()
                                .fill(rec.isComplete ? Color.orange : (rec.minutes > 0 ? Color.orange.opacity(0.3) : Color.gray.opacity(0.2)))
                                .frame(width: 24, height: 24)
                            Text("\(Calendar.current.component(.day, from: rec.date))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Text("\(userManager.totalCompleted()) total days of sunlight tracked")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
            .padding(.horizontal)
            .padding(.top, 16)
            
            Spacer()
            
            Button(action: {
                onStartTracking()
            }) {
                Text("Start Today's \(userManager.user.goalMinutes) Minutes")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.bottom, 16)
        }
    }
    
    private func shortWeekday(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "E"
        return df.string(from: date)
    }
}