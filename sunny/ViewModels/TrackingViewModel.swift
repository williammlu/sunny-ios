import SwiftUI

/// Tracks the current sunlight session in a simplified "camera-based tracking" simulation.
class TrackingViewModel: ObservableObject {
    @Published var isTracking = false
    @Published var elapsedSeconds: Int = 0
    
    // For demonstration, we won't actually access camera brightness.
    // We'll just simulate that if 'isTracking' = true, we increment elapsedSeconds.
    
    private var timer: Timer?
    
    func startTracking() {
        isTracking = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isTracking else { return }
            // simulate brightness threshold always good
            self.elapsedSeconds += 1
        }
    }
    
    func stopTracking() {
        isTracking = false
        timer?.invalidate()
        timer = nil
    }
    
    func reset() {
        elapsedSeconds = 0
    }
    
    func completeSession() -> Int {
        // Convert seconds to minutes
        let minutes = elapsedSeconds / 60
        stopTracking()
        return minutes
    }
}