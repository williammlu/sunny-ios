import SwiftUI

/// Tracks the current sunlight session in a "camera-based tracking" simulation.
class TrackingViewModel: ObservableObject {
    @Published var isTracking = false
    @Published var elapsedSeconds: Int = 0
    
    private var timer: Timer?
    
    func startTracking() {
        isTracking = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isTracking else { return }
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
        let minutes = elapsedSeconds / 60
        stopTracking()
        return minutes
    }
}
