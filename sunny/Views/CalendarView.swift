import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var userManager: UserManager
    
    @State private var currentMonth: Int = {
        let now = Date()
        return Calendar.current.component(.month, from: now)
    }()
    @State private var currentYear: Int = {
        let now = Date()
        return Calendar.current.component(.year, from: now)
    }()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.97, blue: 0.85),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                Text("Your Sunshine Calendar")
                    .font(.title2)
                    .bold()
                    .padding(.top, 16)
                Text("Track your daily sunlight exposure")
                    .foregroundColor(.secondary)
                
                HStack {
                    Button(action: { prevMonth() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    Text("\(monthName(currentMonth)) \(currentYear)")
                        .font(.headline)
                    Spacer()
                    Button(action: { nextMonth() }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal)
                
                let days = daysInMonth(currentMonth, year: currentYear)
                let columns = Array(repeating: GridItem(.flexible()), count: 7)
                
                HStack {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { d in
                        Text(d)
                            .frame(maxWidth: .infinity)
                            .font(.caption)
                    }
                }
                
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(days, id: \.self) { date in
                        if let realDate = date {
                            let rec = userManager.dailyRecords.first(where: { Calendar.current.isDate($0.date, inSameDayAs: realDate) })
                            let dayNum = Calendar.current.component(.day, from: realDate)
                            
                            let isToday = Calendar.current.isDateInToday(realDate)
                            let minutes = rec?.minutes ?? 0
                            let complete = rec?.isComplete ?? false
                            
                            let bubbleColor: Color = {
                                if minutes == 0 {
                                    return Color.gray.opacity(0.2)
                                } else if complete {
                                    return Color.orange
                                } else {
                                    return Color.orange.opacity(0.3)
                                }
                            }()
                            
                            VStack(spacing: 2) {
                                Text("\(dayNum)")
                                    .font(.caption2)
                                    .foregroundColor(isToday ? .white : .primary)
                                    .frame(width: 24, height: 24)
                                    .background(bubbleColor)
                                    .cornerRadius(12)
                                if minutes > 0 && !complete {
                                    Text("\(minutes)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                } else if complete {
                                    Text("✔")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                } else {
                                    Text("")
                                        .font(.caption2)
                                }
                            }
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 30)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                let completionRate = monthlyCompletion()
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.orange)
                        Text("Monthly Goal Completion")
                            .font(.subheadline)
                    }
                    Text("\(completionRate)% of days completed — Goal: \(userManager.user.goalMinutes) min")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    ProgressView(value: Double(completionRate) / 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                }
                .padding()
            }
        }
    }
    
    private func daysInMonth(_ month: Int, year: Int) -> [Date?] {
        var result: [Date?] = []
        let cal = Calendar.current
        
        let comp = DateComponents(year: year, month: month, day: 1)
        guard let firstDay = cal.date(from: comp) else { return [] }
        
        let weekday = cal.component(.weekday, from: firstDay)
        for _ in 1..<weekday {
            result.append(nil)
        }
        
        let range = cal.range(of: .day, in: .month, for: firstDay)!
        for day in range {
            let c = DateComponents(year: year, month: month, day: day)
            if let d = cal.date(from: c) {
                result.append(d)
            }
        }
        return result
    }
    
    private func monthName(_ month: Int) -> String {
        let df = DateFormatter()
        df.dateFormat = "LLLL"
        let c = DateComponents(year: currentYear, month: month, day: 1)
        let date = Calendar.current.date(from: c) ?? Date()
        return df.string(from: date)
    }
    
    private func prevMonth() {
        var newMonth = currentMonth - 1
        var newYear = currentYear
        if newMonth < 1 {
            newMonth = 12
            newYear -= 1
        }
        currentMonth = newMonth
        currentYear = newYear
    }
    
    private func nextMonth() {
        var newMonth = currentMonth + 1
        var newYear = currentYear
        if newMonth > 12 {
            newMonth = 1
            newYear += 1
        }
        currentMonth = newMonth
        currentYear = newYear
    }
    
    private func monthlyCompletion() -> Int {
        let cal = Calendar.current
        let comp = DateComponents(year: currentYear, month: currentMonth)
        guard let firstDay = cal.date(from: comp),
              let range = cal.range(of: .day, in: .month, for: firstDay) else {
            return 0
        }
        let totalDays = range.count
        var completedDays = 0
        for day in range {
            let c = DateComponents(year: currentYear, month: currentMonth, day: day)
            if let d = cal.date(from: c) {
                if let rec = userManager.dailyRecords.first(where: { cal.isDate($0.date, inSameDayAs: d) }),
                   rec.isComplete {
                    completedDays += 1
                }
            }
        }
        let rate = Double(completedDays) / Double(totalDays) * 100
        return Int(round(rate))
    }
}