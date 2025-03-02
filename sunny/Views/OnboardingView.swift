import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var step: Int = 0
    
    // We switch to a TabView with a page style to animate swipes or transitions
    // or we can manually animate. We'll do a TabView for a simpler delight.
    
    private let steps = [
        (title: "Welcome to Sunny",
         description: "Your daily sunlight companion for better health, mood, and energy.",
         imageName: "sun.max"),
        
        (title: "Track Your Sunshine",
         description: "Just 15 minutes of daily sunlight can boost your mood, energy, and overall wellness.",
         imageName: "sparkles"),
        
        (title: "Build Your Streak",
         description: "Maintain your daily sunlight routine and watch your streak grow!",
         imageName: "flame.fill"),
        
        (title: "Sign In to Continue",
         description: "Sign in or create an account to save your progress. (Demo auto logs you in.)",
         imageName: "person.crop.circle.fill")
    ]
    
    var body: some View {
        ZStack {
            // Sunny gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.97, blue: 0.85),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            TabView(selection: $step) {
                ForEach(0..<steps.count, id: \.self) { i in
                    let current = steps[i]
                    VStack(spacing: 24) {
                        Spacer()
                        Image(systemName: current.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.orange)
                            .padding(.bottom, 8)
                        
                        Text(current.title)
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)
                        
                        Text(current.description)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut) {
                                if step < steps.count - 1 {
                                    step += 1
                                } else {
                                    userManager.completeOnboarding()
                                }
                            }
                        }) {
                            Text(step < steps.count - 1 ? "Continue" : "Done")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(.horizontal, 40)
                        }
                        
                        // Dots
                        HStack {
                            ForEach(0..<steps.count, id: \.self) { s in
                                Circle()
                                    .fill(s == step ? Color.orange : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)
        }
    }
}