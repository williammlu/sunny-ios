import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var selectedReminderTime = "Morning (9:00 AM)"
    
    var reminderTimes = ["Morning (9:00 AM)", "Noon (12:00 PM)", "Afternoon (3:00 PM)"]
    
    var body: some View {
        VStack {
            Text("Your Profile")
                .font(.title2)
                .bold()
                .padding(.top, 16)
            Text("Manage your account and preferences")
                .foregroundColor(.secondary)
                .padding(.bottom, 16)
            
            // Account info
            VStack(alignment: .leading, spacing: 8) {
                Text("Account Information")
                    .font(.headline)
                HStack {
                    ZStack {
                        Circle().fill(Color.orange.opacity(0.2))
                            .frame(width: 80, height: 80)
                        Text(userManager.user.fullName.isEmpty ? "U" : String(userManager.user.fullName.prefix(1)))
                            .font(.title)
                            .foregroundColor(.orange)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        if !userManager.user.fullName.isEmpty {
                            Text("Name: \(userManager.user.fullName)")
                                .font(.subheadline)
                        }
                        Text("Email: \(userManager.user.email)")
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 3)
            .padding(.horizontal)
            
            // Daily goal setting
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Sunlight Goal")
                    .font(.headline)
                Text("Set your daily sunlight exposure target (minutes)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: Binding(
                    get: { Double(userManager.user.goalMinutes) },
                    set: { userManager.updateGoalMinutes(to: Int($0)) }
                ), in: 5...30, step: 1)
                HStack {
                    Text("5 min")
                    Spacer()
                    Text("\(userManager.user.goalMinutes) min").bold()
                    Spacer()
                    Text("30 min")
                }
                .font(.caption)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 3)
            .padding(.horizontal)
            .padding(.top, 16)
            
            // Notification settings
            VStack(alignment: .leading, spacing: 8) {
                Text("Notification Settings")
                    .font(.headline)
                Toggle(isOn: Binding(
                    get: { userManager.user.notificationsEnabled },
                    set: { userManager.updateNotificationsEnabled($0) }
                )) {
                    Text("Daily Reminders")
                }
                .padding(.top, 8)
                
                if userManager.user.notificationsEnabled {
                    HStack {
                        Text("Reminder Time")
                        Spacer()
                        Picker("Reminder Time", selection: $selectedReminderTime) {
                            ForEach(reminderTimes, id: \.self) { time in
                                Text(time).tag(time)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 3)
            .padding(.horizontal)
            .padding(.top, 16)
            
            // Sign Out
            Button(action: {
                userManager.signOut()
            }) {
                Text("Sign Out")
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: 2)
                    )
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            Spacer()
        }
    }
}