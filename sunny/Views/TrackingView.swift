
import SwiftUI
import AVFoundation
import Charts
import ActivityKit
import UserNotifications
import SunnyShared

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
    
    // MARK: - Constants for “15 minutes” in UI
    private let kTrackGoalMinutes = 15
    private var kTrackGoalSeconds: Int { kTrackGoalMinutes * 60 }
    
    // Accumulated seconds user has so far for today's session
    @State private var accumulatedSeconds: Int = 0
    
    // Timer
    @State private var timer: Timer?
    @State private var isRunning = false  // is the session actively counting
    
    // UI states for icons
    @State private var showMoon: Bool = false
    @State private var showCloudySun: Bool = false
    @State private var showBrightSun: Bool = false
    
    // Whether to show a "Result" screen
    @State private var showResultScreen: Bool = false
    
    // A local state to show a "toast" if camera is overexposed
    @State private var showBlownOutToast: Bool = false
    
    // Show the camera feed at the top
    private let showDebugCamera: Bool = true
    
    // The ongoing Live Activity reference
    @State private var sunlightActivity: Activity<SunlightActivityAttributes>?
    
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
            
            VStack(spacing: 24) {
                
                if showDebugCamera {
                    CameraPreviewView(session: captureManager.captureSession)
                        .frame(width: 100, height: 100)
                }
                
                VStack(spacing: 8) {
                    if showMoon {
                        moonIconView.frame(width: 60, height: 60)
                    } else if showBrightSun {
                        brightSunView.frame(width: 60, height: 60)
                    } else if showCloudySun {
                        cloudySunView.frame(width: 60, height: 60)
                    } else {
                        lowSunView.frame(width: 60, height: 60)
                    }
                    Text(lightConditionText()).font(.headline)
                }
                
                Text("Sunlight Tracking")
                    .font(.largeTitle)
                    .bold()
                
                VStack(spacing: 8) {
                    Text("\(timeString(accumulatedSeconds)) / \(kTrackGoalMinutes) min")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    let fraction = min(1.0, CGFloat(accumulatedSeconds) / CGFloat(kTrackGoalSeconds))
                    let barWidth = UIScreen.main.bounds.width * 0.6
                    let cornerRadius: CGFloat = 8
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: geo.size.width, height: 10)
                            
                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: fraction * geo.size.width, height: 10)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    }
                    .frame(width: barWidth, height: 10)
                }
                
                Spacer()
                
                HStack(spacing: 20) {
                    if accumulatedSeconds < (userManager.user.goalMinutes * 60) {
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
                .padding(.bottom, 20)
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
            
            if showBlownOutToast {
                VStack {
                    Text("Warning: The camera is overexposed. Lux readings may be inaccurate.")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .onTapGesture { showBlownOutToast = false }
                }
                .padding(.top, 130)
                .padding(.horizontal, 20)
                .transition(.move(edge: .top))
            }
        }
        .onAppear {
            captureManager.startSession()
            classifyTimeOfDay()
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                print("Local notifications granted? \(granted)")
            }
        }
        .onDisappear {
            captureManager.stopSession()
            stopTimer()
            endLiveActivityIfNeeded()
        }
        .onChange(of: captureManager.showBlownOutWarning) { newVal in
            if newVal {
                showBlownOutToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { showBlownOutToast = false }
            }
        }
    }
}

// MARK: - Session Logic
extension TrackingView {
    private func toggleSession() {
        isRunning ? stopTimer() : resumeSession()
    }
    
    private func resumeSession() {
        isRunning = true
        startTimer()
        startLiveActivityIfNeeded()
        BackgroundScheduler.scheduleSunTask(inMinutes: kTrackGoalMinutes)
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            accumulatedSeconds += 1
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
        setLiveActivityComplete()
        showResultScreen = true
    }
    
    private func startNewSession() {
        accumulatedSeconds = 0
        showResultScreen = false
        isRunning = false
        startTimer()
        startLiveActivityIfNeeded()
    }
}

// MARK: - Live Activity
extension TrackingView {
    private func startLiveActivityIfNeeded() {
        guard #available(iOS 16.1, *), sunlightActivity == nil else { return }
        let content = SunlightActivityAttributes.ContentState(
            isComplete: false,
            startDate: Date()
        )
        let attrs = SunlightActivityAttributes()
        do {
            sunlightActivity = try Activity.request(attributes: attrs, contentState: content, pushType: nil)
        } catch {
            print("Live activity request failed: \(error)")
        }
    }
    
    private func setLiveActivityComplete() {
        guard #available(iOS 16.1, *), let activity = sunlightActivity else { return }
        Task {
            let newContent = SunlightActivityAttributes.ContentState(
                isComplete: true,
                startDate: activity.contentState.startDate
            )
            await activity.update(using: newContent)
            await activity.end(using: newContent, dismissalPolicy: .immediate)
            sunlightActivity = nil
        }
    }
    
    private func endLiveActivityIfNeeded() {
        guard #available(iOS 16.1, *), let activity = sunlightActivity else { return }
        Task {
            let final = SunlightActivityAttributes.ContentState(
                isComplete: true,
                startDate: activity.contentState.startDate
            )
            await activity.end(using: final, dismissalPolicy: .immediate)
            sunlightActivity = nil
        }
    }
}

// MARK: - Helpers
extension TrackingView {
    private func updateLightCondition(brightness: Float) {
        if isNight {
            showMoon = true; showBrightSun = false; showCloudySun = false; return
        }
        if brightness > 20000 { showBrightSun = true; showCloudySun = false; showMoon = false }
        else if brightness > 10000 { showBrightSun = false; showCloudySun = true; showMoon = false }
        else { showBrightSun = false; showCloudySun = false; showMoon = false }
    }
    
    private func lightConditionText() -> String {
        if isNight { return "Nighttime conditions" }
        else if captureManager.lux > 20000 { return "Bright sunlight detected" }
        else if captureManager.lux > 10000 { return "Moderate light detected" }
        else { return "Low light detected" }
    }
    
    private func classifyTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: Date())
        isNight = (hour < 6 || hour > 19)
    }
    
    private func timeString(_ secs: Int) -> String {
        let m = secs / 60, s = secs % 60
        return String(format: "%dm %02ds", m, s)
    }
}

// MARK: - Camera Preview Helper
import UIKit
import AVKit

struct CameraPreviewView: UIViewRepresentable {
    var session: AVCaptureSession?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        guard let session = session else { return view }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let session = session,
              let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer else { return }
        layer.frame = uiView.bounds
    }
}

// MARK: - Additional sun icons
extension TrackingView {
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
