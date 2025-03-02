import SwiftUI

@main
struct sunnyApp: App {
    @StateObject var userManager = UserManager()
    
    var body: some Scene {
        WindowGroup {
            // Force light mode for a bright, sunny vibe
            if !userManager.didFinishOnboarding {
                OnboardingView()
                    .environmentObject(userManager)
                    .preferredColorScheme(.light)
                    .accentColor(.orange)
            } else {
                MainTabView()
                    .environmentObject(userManager)
                    .preferredColorScheme(.light)
                    .accentColor(.orange)
            }
        }
    }
}