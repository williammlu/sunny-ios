import SwiftUI

/// The main tabbed layout (Streak, Tracking, Calendar, Profile).
struct MainTabView: View {
    @State private var selection: Int = 0
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        TabView(selection: $selection) {
            // Streak
            NavigationView {
                StreakDashboardView {
                    // Start tracking
                    selection = 1 // Move to the Tracking tab
                }
                .navigationTitle("Streak")
                .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: "flame")
                Text("Streak")
            }
            .tag(0)
            
            // Tracking
            NavigationView {
                TrackingView()
                    .navigationTitle("Track")
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: "sun.max.fill")
                Text("Track")
            }
            .tag(1)
            
            // Calendar
            NavigationView {
                CalendarView()
                    .navigationTitle("Calendar")
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Calendar")
            }
            .tag(2)
            
            // Profile
            NavigationView {
                ProfileView()
                    .navigationTitle("Profile")
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: "person.crop.circle")
                Text("Profile")
            }
            .tag(3)
        }
    }
}