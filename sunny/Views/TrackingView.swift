
import SwiftUI
import AVFoundation
import Charts

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
    
    // The total daily target in seconds
    private var dailyTargetSeconds: Int {
        userManager.user.goalMinutes * 60
    }
    
    // Accumulated seconds user has so far for today's session
    @State private var accumulatedSeconds: Int = 0
    
    // Timer
    @State private var timer: Timer?
    @State private var isRunning = false  // is the session actively counting up?
    
    // UI states for icons
    @State private var showMoon: Bool = false
    @State private var showCloudySun: Bool = false
    @State private var showBrightSun: Bool = false
    
    // Whether to show a "Result" screen
    @State private var showResultScreen: Bool = false
    
    // A local state to show a "toast" or ephemeral warning if camera is "blown out"
    @State private var showBlownOutToast: Bool = false
    
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
            
            VStack(spacing: 16) {
                
                // Title
                Text("Sunlight Tracking")
                    .font(.title2)
                    .bold()
                    .padding(.top, 16)
                
                // Our chart for last 15 min of lux
                luxGraphView
                
                // Show the progress bar for daily target
                progressBar
                
                if accumulatedSeconds < dailyTargetSeconds {
                    if isRunning {
                        Text("Session in progress...")
                            .foregroundColor(.secondary)
                        Text("\(timeString(accumulatedSeconds)) so far")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Session paused at \(timeString(accumulatedSeconds))")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("You reached today's goal!")
                        .foregroundColor(.green)
                }
                
                // Pulsing icon
                ZStack {
                    if showMoon {
                        moonIconView
                            .frame(width: 120, height: 120)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                       value: captureManager.lux)
                    } else if showBrightSun {
                        brightSunView
                            .frame(width: 120, height: 120)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                       value: captureManager.lux)
                    } else if showCloudySun {
                        cloudySunView
                            .frame(width: 120, height: 120)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                       value: captureManager.lux)
                    } else {
                        lowSunView
                            .frame(width: 120, height: 120)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                       value: captureManager.lux)
                    }
                }
                .padding(.bottom, 8)
                
                Text(lightConditionText())
                    .font(.headline)
                
                Spacer()
                
                // Session control buttons
                HStack(spacing: 20) {
                    if accumulatedSeconds < dailyTargetSeconds {
                        Button(isRunning ? "Pause" : "Resume") {
                            toggleSession()
                        }
                        .font(.headline)
                        .padding()
                        .background(Color.orange.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    } else {
                        Button("New Session") {
                            startNewSession()
                        }
                        .font(.headline)
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    Button("Finish Today") {
                        finishSessionForToday()
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showResultScreen) {
                // Show final minutes
                ResultView(
                    minutes: accumulatedSeconds / 60,
                    goalMinutes: userManager.user.goalMinutes,
                    onContinue: {
                        showResultScreen = false
                    }
                )
            }
            
            // A simple "toast" overlay if blowOut is detected
            if showBlownOutToast {
                VStack {
                    Text("Warning: The camera is overexposed. Lux readings may be inaccurate.")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .onTapGesture {
                            // Dismiss on tap
                            showBlownOutToast = false
                        }
                }
                .padding(.horizontal, 20)
                .padding(.top, 80)
                .transition(.move(edge: .top))
            }
        }
        .onAppear {
            captureManager.startSession()
            classifyTimeOfDay()
        }
        .onDisappear {
            captureManager.stopSession()
            stopTimer()
        }
        // Listen for blow-out warning changes
        .onChange(of: captureManager.showBlownOutWarning) { newVal in
            // If camera sees >0.5% blown out => show a toast for 3s
            if newVal == true {
                showBlownOutToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showBlownOutToast = false
                }
            }
        }
        // Also onChange of the lux value => update icons
        .onChange(of: captureManager.lux) { newVal in
            updateLightCondition(brightness: newVal)
        }
    }
}

// MARK: - Subviews
extension TrackingView {
    
    @ViewBuilder
    private var luxGraphView: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(Array(captureManager.luxHistory.enumerated()), id: \.offset) { (index, luxVal) in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Lux", luxVal)
                    )
                }
            }
            .frame(height: 150)
            .padding(.horizontal)
        } else {
            Text("Lux chart requires iOS 16+")
                .foregroundColor(.secondary)
        }
    }
    
    private var progressBar: some View {
        let fraction = min(1.0, CGFloat(accumulatedSeconds) / CGFloat(dailyTargetSeconds))
        
        return VStack(alignment: .leading) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange)
                    .frame(width: fraction * UIScreen.main.bounds.width * 0.6, height: 10)
            }
            .frame(height: 10)
            
            Text("\(timeString(accumulatedSeconds)) / \(timeString(dailyTargetSeconds))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
    }
    
    private var brightSunView: some View {
        Image(systemName: "sun.max.fill")
            .resizable()
            .foregroundColor(.yellow)
            .scaleEffect(1.1)
            .shadow(color: .yellow.opacity(0.5), radius: 10)
    }
    
    private var cloudySunView: some View {
        Image(systemName: "cloud.sun.fill")
            .resizable()
            .foregroundColor(.yellow.opacity(0.8))
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

// MARK: - Session Logic
extension TrackingView {
    
    private func toggleSession() {
        if isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            accumulatedSeconds += 1
            if accumulatedSeconds >= dailyTargetSeconds {
                // Reached daily goal
                stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func finishSessionForToday() {
        stopTimer()
        let minutes = accumulatedSeconds / 60
        userManager.trackSunlight(minutes: minutes)
        showResultScreen = true
    }
    
    private func startNewSession() {
        accumulatedSeconds = 0
        showResultScreen = false
        isRunning = false
        startTimer()
    }
}

// MARK: - Helpers
extension TrackingView {
    private func updateLightCondition(brightness: Float) {
        if isNight {
            showMoon = true
            showBrightSun = false
            showCloudySun = false
            return
        }
        
        if brightness > 20000 {
            showBrightSun = true
            showCloudySun = false
            showMoon = false
        } else if brightness > 10000 {
            showBrightSun = false
            showCloudySun = true
            showMoon = false
        } else {
            showBrightSun = false
            showCloudySun = false
            showMoon = false
        }
    }
    
    private func lightConditionText() -> String {
        if isNight {
            return "Nighttime conditions"
        } else if captureManager.lux > 20000 {
            return "Bright sunlight detected"
        } else if captureManager.lux > 10000 {
            return "Moderate light detected"
        } else {
            return "Low light detected"
        }
    }
    
    private func classifyTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: Date())
        isNight = (hour < 6 || hour > 19)
    }
    
    private func timeString(_ secs: Int) -> String {
        let m = secs / 60
        let s = secs % 60
        return String(format: "%dm %02ds", m, s)
    }
}
