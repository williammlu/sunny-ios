import SwiftUI

@main
struct sunnyApp: App {
    @StateObject var userManager = UserManager()
    
    var body: some Scene {
        WindowGroup {
            if !userManager.didFinishOnboarding {
                OnboardingView()
                    .environmentObject(userManager)
            } else {
                MainTabView()
                    .environmentObject(userManager)
            }
        }
    }
}