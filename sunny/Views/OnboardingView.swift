import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var step: Int = 0
    
    let steps = [
        (title: "Welcome to Sunny", description: "Your daily sunlight companion for better health, mood, and energy.", imageName: "sun.max"),
        (title: "Track Your Sunshine", description: "Just 15 minutes of daily sunlight can boost your mood, energy, and overall wellness.", imageName: "sparkles"),
        (title: "Build Your Streak", description: "Maintain your daily sunlight routine and watch your streak grow!", imageName: "flame.fill"),
        (title: "Sign In to Continue", description: "Sign in or create an account to save your progress. (Demo automatically logs you in.)", imageName: "person.crop.circle.fill")
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            if step < steps.count {
                let current = steps[step]
                Image(systemName: current.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(.bottom, 8)
                    .foregroundColor(.orange)
                
                Text(current.title)
                    .font(.title2).bold()
                Text(current.description)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    if step < steps.count - 1 {
                        step += 1
                    } else {
                        // Mark onboarding done
                        userManager.completeOnboarding()
                    }
                }) {
                    Text(step < steps.count - 1 ? "Continue" : "Done")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Page indicators
                HStack {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Circle()
                            .fill(i == step ? Color.orange : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .padding()
    }
}