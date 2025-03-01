import SwiftUI

struct TrackingView: View {
    @EnvironmentObject var userManager: UserManager
    @StateObject private var vm = TrackingViewModel()
    
    @State private var showResult = false
    @State private var completedMinutes: Int = 0
    
    var body: some View {
        VStack {
            Text("Sunlight Tracking")
                .font(.title2)
                .bold()
                .padding(.top, 16)
            
            Spacer()
            
            // Simulated camera preview placeholder:
            ZStack {
                Color.yellow.opacity(0.3)
                Text("Camera Feed Simulation")
                    .foregroundColor(.black.opacity(0.8))
            }
            .frame(height: 200)
            .cornerRadius(12)
            .padding(.horizontal)
            
            if vm.isTracking {
                Text("Tracking in progress...\n\(minutesString(vm.elapsedSeconds))")
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                Text("Ready to start tracking?")
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            if !vm.isTracking {
                Button(action: {
                    vm.startTracking()
                }) {
                    Text("Start Tracking")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            } else {
                VStack(spacing: 8) {
                    Button(action: {
                        vm.stopTracking()
                    }) {
                        Text("Pause Tracking")
                            .foregroundColor(.orange)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.orange, lineWidth: 2)
                            )
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        let minutes = vm.completeSession()
                        userManager.trackSunlight(minutes: minutes)
                        completedMinutes = minutes
                        showResult = true
                    }) {
                        Text("Complete Session")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
            }
            
            Spacer()
        }
        .sheet(isPresented: $showResult) {
            ResultView(minutes: completedMinutes,
                       goalMinutes: userManager.user.goalMinutes) {
                showResult = false
            }
        }
    }
    
    func minutesString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d min %02d sec", m, s)
    }
}