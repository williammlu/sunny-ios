import SwiftUI

struct ResultView: View {
    let minutes: Int
    let goalMinutes: Int
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            if minutes >= goalMinutes {
                Image(systemName: "checkmark.seal.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.green)
                Text("Goal Achieved!")
                    .font(.title2).bold()
                Text("You've completed \(minutes) minutes of sunlight today!")
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "sun.max")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.orange)
                Text("Great Progress!")
                    .font(.title2).bold()
                Text("You've completed \(minutes) of your \(goalMinutes)-minute goal.\nJust \(goalMinutes - minutes) more minutes to reach today's target!")
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Benefits")
                    .font(.headline)
                Text("• Energy Boost: Regulate your circadian rhythm")
                Text("• Mood Enhancement: Increase serotonin release")
                Text("• Vitamin D Production: Essential for bone health")
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5)
            
            Spacer()
            
            Button(action: {
                onContinue()
            }) {
                Text("Continue to Dashboard")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}