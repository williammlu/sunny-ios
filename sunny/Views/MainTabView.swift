import SwiftUI

/// The main tabbed layout (Streak, Tracking, Calendar, Profile).
struct MainTabView: View {
    @State private var selection: Int = 0
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        TabView(selection: $selection) {
            // Streak
            StreakDashboardView {
                withAnimation {
                    selection = 1 // Move to the Tracking tab
                }
            }
            .tabItem {
                Image(systemName: "flame")
                Text("Streak")
            }
            .tag(0)
            
            // Tracking
            TrackingView()
            .tabItem {
                Image(systemName: "sun.max.fill")
                Text("Track")
            }
            .tag(1)
            
            // Calendar
            CalendarView()
            .tabItem {
                Image(systemName: "calendar")
                Text("Calendar")
            }
            .tag(2)
            
            // Profile
            ProfileView()
            .tabItem {
                Image(systemName: "person.crop.circle")
                Text("Profile")
            }
            .tag(3)
        }
    }
}