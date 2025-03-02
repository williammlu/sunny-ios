import SwiftUI
import AVFoundation

/// A struct for capturing brightness classification
enum LightCondition {
    case veryBright
    case moderate
    case low
    case nighttime
}

struct TrackingView: View {
    @EnvironmentObject var userManager: UserManager
    
    /// Class-based manager for video capture
    @StateObject private var captureManager = VideoCaptureManager()
    
    // For time-of-day check
    @State private var isNight: Bool = false
    
    // Countdown logic
    @State private var remainingSeconds: Int = 0
    @State private var timer: Timer?
    
    // UI display states
    @State private var showMoon: Bool = false
    @State private var showCloudySun: Bool = false
    @State private var showBrightSun: Bool = false
    
    // Done bar fill
    @State private var fillFraction: CGFloat = 0.0
    
    // Session status
    @State private var sessionComplete: Bool = false
    @State private var showResultScreen: Bool = false
    @State private var completedMinutes: Int = 0
    
    var body: some View {
        ZStack {
            // Sunny background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.97, blue: 0.85),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Title
                Text(sessionComplete ? "Session Complete" : "Sunlight Tracking")
                    .font(.title2)
                    .bold()
                    .padding(.top, 16)
                
                Spacer()
                
                // Pulsing icon
                ZStack {
                    if showMoon {
                        moonIconView
                            .frame(width: 120, height: 120)
                            // Animate based on lumens (Float is Equatable, so it's valid)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                       value: captureManager.lumens)
                    } else if showBrightSun {
                        brightSunView
                            .frame(width: 120, height: 120)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                       value: captureManager.lumens)
                    } else if showCloudySun {
                        cloudySunView
                            .frame(width: 120, height: 120)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                       value: captureManager.lumens)
                    } else {
                        lowSunView
                            .frame(width: 120, height: 120)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                       value: captureManager.lumens)
                    }
                }
                .padding(.bottom, 8)
                
                // Info about brightness
                Text(lightConditionText())
                    .font(.headline)
                
                if !sessionComplete {
                    Text("Tracking in progress...")
                        .foregroundColor(.secondary)
                    Text("\(timeString(remainingSeconds)) left")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Done bar
                doneBarButton
                    .frame(height: 50)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showResultScreen) {
                ResultView(
                    minutes: completedMinutes,
                    goalMinutes: userManager.user.goalMinutes,
                    onContinue: {
                        showResultScreen = false
                    }
                )
            }
        }
        .onAppear {
            captureManager.startSession()
            let totalSeconds = userManager.user.goalMinutes * 60
            remainingSeconds = totalSeconds
            startCountdownTimer()
            classifyTimeOfDay()
        }
        .onDisappear {
            captureManager.stopSession()
            timer?.invalidate()
        }
        // Instead of dynamicMember subscript, we use the raw property
        .onChange(of: captureManager.lumens) { newVal in
            updateLightCondition(brightness: newVal)
        }
    }
}

// MARK: - UI Subviews
extension TrackingView {
    
    private var doneBarButton: some View {
        ZStack(alignment: .leading) {
            // Outline
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange, lineWidth: 2)
            
            // Fill based on fillFraction
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange)
                .frame(width: fillFraction * UIScreen.main.bounds.width * 0.60)
            
            HStack {
                Spacer()
                Text(sessionComplete ? "Done" : "Finish Early")
                    .foregroundColor(sessionComplete ? .white : .orange)
                Spacer()
            }
        }
        .onTapGesture {
            if !sessionComplete {
                endSessionEarly()
            } else {
                finalizeSession()
            }
        }
    }
    
    private var brightSunView: some View {
        Image(systemName: "sun.max.fill")
            .resizable()
            .foregroundColor(.yellow)
            .scaleEffect(1.1)
            .shadow(color: .yellow.opacity(0.5), radius: 10)
    }
    
    private var cloudySunView: some View {
        ZStack {
            Image(systemName: "cloud.sun.fill")
                .resizable()
                .foregroundColor(.yellow.opacity(0.8))
        }
    }
    
    private var lowSunView: some View {
        Image(systemName: "sun.max")
            .resizable()
            .foregroundColor(.yellow.opacity(0.4))
            .shadow(color: .yellow.opacity(0.2), radius: 5)
    }
    
    private var moonIconView: some View {
        Image(systemName: "moon.stars.fill")
            .resizable()
            .foregroundColor(.blue.opacity(0.6))
    }
}

// MARK: - Countdown Logic
extension TrackingView {
    private func startCountdownTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            remainingSeconds -= 1
            if remainingSeconds < 0 {
                endSession()
            }
            let totalSeconds = userManager.user.goalMinutes * 60
            fillFraction = 1.0 - (CGFloat(remainingSeconds) / CGFloat(totalSeconds))
        }
    }
    
    private func endSessionEarly() {
        endSession()
    }
    
    private func endSession() {
        sessionComplete = true
        timer?.invalidate()
        timer = nil
        
        let actualTrackedSeconds = (userManager.user.goalMinutes * 60) - remainingSeconds
        let minutes = actualTrackedSeconds / 60
        
        userManager.trackSunlight(minutes: minutes)
        completedMinutes = minutes
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showResultScreen = true
        }
    }
    
    private func finalizeSession() {
        showResultScreen = true
    }
    
    private func timeString(_ secs: Int) -> String {
        let m = secs / 60
        let s = secs % 60
        return String(format: "%d min %02d sec", m, s)
    }
    
    private func classifyTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: Date())
        isNight = (hour < 6 || hour > 19)
    }
}

// MARK: - Light Condition
extension TrackingView {
    
    private func updateLightCondition(brightness: Float) {
        print("brightness", brightness)
        if isNight {
            showMoon = true
            showBrightSun = false
            showCloudySun = false
            return
        }
        
        if brightness > 20000 {
            // Very bright
            showBrightSun = true
            showCloudySun = false
            showMoon = false
        } else if brightness > 10000 {
            // moderate
            showBrightSun = false
            showCloudySun = true
            showMoon = false
        } else {
            // low
            showBrightSun = false
            showCloudySun = false
            showMoon = false
        }
    }
    
    private func lightConditionText() -> String {
        if isNight {
            return "Nighttime conditions"
        } else if captureManager.lumens > 20000 {
            return "Bright sunlight detected"
        } else if captureManager.lumens > 10000 {
            return "Moderate light detected"
        } else {
            return "Low light detected"
        }
    }
}
