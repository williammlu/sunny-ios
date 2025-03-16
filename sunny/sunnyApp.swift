import SwiftUI
import BackgroundTasks
import ActivityKit
import SunnyShared

@main
struct SunnyApp: App {
    @StateObject var userManager = UserManager()
    
    init() {
        // Ensure background task registration happens on app launch
        BackgroundScheduler.register()
        
        // Handle any leftover Live Activities (optional)
        cleanupOldLiveActivities()
    }
    
    var body: some Scene {
        WindowGroup {
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
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .onAppear {
                        // Resume Live Activity state if needed
                        restoreLiveActivityState()
                    }
            }
        }
    }
    
    /// Handles when user taps on Live Activity and app opens via deep link
    private func handleDeepLink(_ url: URL) {
        if url.absoluteString == "sunny://continueSession" {
            print("Resuming session from Live Activity tap...")
            userManager.didFinishOnboarding = true // Ensure app is in main UI state
        }
    }
    
    /// Ends any lingering Live Activities when app is closed (optional)
    private func cleanupOldLiveActivities() {
        if #available(iOS 16.1, *) {
            for activity in Activity<SunlightActivityAttributes>.activities {
                Task {
                    let finalContent = SunlightActivityAttributes.ContentState(
                        isComplete: true, // Mark it as done if app was killed mid-session
                        startDate: activity.contentState.startDate
                    )
                    await activity.end(using: finalContent, dismissalPolicy: .immediate)
                }
            }
        }
    }
    
    /// Restores previous Live Activity state if app was reopened after a session
    private func restoreLiveActivityState() {
        if #available(iOS 16.1, *) {
            for activity in Activity<SunlightActivityAttributes>.activities {
                print("Restoring Live Activity: \(activity.id)")
                // Optional: Retrieve `activity.contentState` and resume tracking if needed
            }
        }
    }
}
