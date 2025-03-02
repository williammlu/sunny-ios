
import SwiftUI
import AVFoundation
import Charts  // If you want to use SwiftUI Charts (iOS 16+). If not, remove import.

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
    
    // Accumulated seconds user has so far for today's session. They can pause/continue.
    // (You might store this in your UserManager or local storage for real usage.)
    @State private var accumulatedSeconds: Int = 0
    
    // Timer
    @State private var timer: Timer?
    @State private var isRunning = false  // is the session actively counting up?
    
    // UI states
    @State private var showMoon: Bool = false
    @State private var showCloudySun: Bool = false
    @State private var showBrightSun: Bool = false
    
    // Whether to show a "Result" screen
    @State private var showResultScreen: Bool = false
    
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
                
                // Title + day info
                Text("Sunlight Tracking")
                    .font(.title2)
                    .bold()
                    .padding(.top, 16)
                
                // Our new chart for the last 15 min lumens
                lumensGraphView
                
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
                ResultView(
                    minutes: accumulatedSeconds / 60,
                    goalMinutes: userManager.user.goalMinutes,
                    onContinue: {
                        showResultScreen = false
                    }
                )
            }
        }
        .onAppear {
            // Start camera
            captureManager.startSession()
            // If we want to load a saved "accumulatedSeconds", do so.
            // For now, we just keep ephemeral state.
            classifyTimeOfDay()
        }
        .onDisappear {
            captureManager.stopSession()
            stopTimer()
        }
        .onChange(of: captureManager.lumens) { newVal in
            updateLightCondition(brightness: newVal)
        }
    }
}

// MARK: - Subviews
extension TrackingView {
    
    // Use SwiftUI's native Charts if iOS 16+ available. If not, remove or do a custom.
    @ViewBuilder
    private var lumensGraphView: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(Array(captureManager.lumensHistory.enumerated()), id: \.offset) { (index, lum) in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Lumens", lum)
                    )
                }
            }
            .frame(height: 150)
            .padding(.horizontal)
        } else {
            // fallback if older iOS
            Text("Lumens chart requires iOS 16+")
                .foregroundColor(.secondary)
        }
    }
    
    private var progressBar: some View {
        // Display how much time we've logged vs daily target
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
                // Reached today's goal automatically
                stopTimer()
                // Possibly show result or just do a message
            }
        }
    }
    
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func finishSessionForToday() {
        // The user wants to end today's tracking. Possibly show result, log partial.
        stopTimer()
        
        // Log the partial or full session
        let minutes = accumulatedSeconds / 60
        userManager.trackSunlight(minutes: minutes)  // We store it
        // Show result if we want
        showResultScreen = true
    }
    
    private func startNewSession() {
        // Reset for a new day or new session
        accumulatedSeconds = 0
        showResultScreen = false
        isRunning = false
        // Optionally start immediately
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
        } else if captureManager.lumens > 20000 {
            return "Bright sunlight detected"
        } else if captureManager.lumens > 10000 {
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
