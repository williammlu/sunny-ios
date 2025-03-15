import Foundation
import AVFoundation
import SwiftUI

/// A class that handles front camera capture, calculates approximate lux,
/// using the approach from Stack Overflow: "avgLightness * (fRef^2/f^2) * (isoRef/iso) * (shutter/shutterRef)".
/// We do blowout detection if >0.5% pixels are saturated.
final class VideoCaptureManager: NSObject, ObservableObject {
    
    // MARK: - Constants for lux sampling
    /// Number of minutes of lux data to keep in history.
    private let kLuxHistoryMinutes = 15
    /// If ~1 fps, 15 minutes => 900 samples
    private let kLuxHistoryCount = 900
    
    // MARK: - Published properties
    /// Approximate lux read by SwiftUI
    @Published var lux: Float = 0.0
    
    /// Rolling history of last kLuxHistoryMinutes minutes
    @Published var luxHistory: [Float] = []
    
    /// Whether camera has “initiated” (skip outputs first few seconds)
    @Published var isCameraInitiated: Bool = false
    
    /// If more than 0.5% pixels are saturated => show a UI warning
    @Published var showBlownOutWarning: Bool = false
    
    // MARK: - Session/Device properties
    /// Public or internal session so TrackingView can display it, if needed
    var captureSession: AVCaptureSession?
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private var activeDevice: AVCaptureDevice?
    
    // Queue for session config and start
    private let sessionQueue = DispatchQueue(label: "com.sunny.videoSessionQueue")
    
    // Reference exposure values (ISO=100, Aperture=2.2, Shutter=1/60)
    private let isoRef: Float = 100
    private let apertureRef: Float = 2.2
    private let shutterRef: Float = 1.0 / 60.0
    
    // A final multiplier that converts the normalized brightness into approximate “lux”
    // Tweak as needed to match real measurements.
    private let luxScaleFactor: Double = 450000.0
    
    // MARK: - Lifecycle
    func startSession() {
        sessionQueue.async {
            let session = AVCaptureSession()
            session.sessionPreset = .medium
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .front) else {
                print("No front camera available.")
                return
            }
            self.activeDevice = device
            
            do {
                // Let ISO/shutter float
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                self.videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraFrameQueue"))
                
                if session.canAddOutput(self.videoOutput) {
                    session.addOutput(self.videoOutput)
                }
                
                session.startRunning()
                self.captureSession = session
                
                // Wait a few seconds, then mark camera as initiated
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isCameraInitiated = true
                }
                
            } catch {
                print("Error setting up camera: \(error)")
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            self.captureSession?.stopRunning()
            self.captureSession = nil
            self.isCameraInitiated = false
            self.showBlownOutWarning = false
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension VideoCaptureManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        // 1) If camera not initiated, skip
        guard isCameraInitiated else { return }
        
        // 2) Access pixel buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer)?
            .assumingMemoryBound(to: UInt8.self) else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            return
        }
        
        // We step by 20 for performance. Tweak as needed.
        let step = 20
        var totalLuma: Double = 0
        var blowOutCount = 0
        var totalCount = 0
        var totalR: Double = 0
        var totalG: Double = 0
        var totalB: Double = 0

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let offset = (y * width + x) * 4
                let b = Double(base[offset + 0])
                let g = Double(base[offset + 1])
                let r = Double(base[offset + 2])
                
                totalR += r
                totalG += g
                totalB += b
                
                // blow-out detection
                if (r > 250 && g > 250 && b > 250) {
                    blowOutCount += 1
                }
                totalCount += 1
            }
        }

        // naive luminance
        let lum = (0.2126 * totalR + 0.7152 * totalG + 0.0722 * totalB) / Double(totalCount)
        totalLuma = lum
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        
        let blowOutRatio = Double(blowOutCount) / Double(totalCount)
        // If more than 2% => blow out warning
        let blowOutWarning = blowOutRatio >= 0.02
        
        // 3) Gather actual exposure settings
        var iso: Float = 0
        var shutterSpeed: Float = 0
        var aperture: Float = 0
        
        if let device = activeDevice {
            iso = device.iso
            let duration = device.exposureDuration
            if duration.isNumeric && duration.timescale != 0 {
                shutterSpeed = Float(duration.value) / Float(duration.timescale)
            }
            aperture = device.lensAperture
        } else {
            // no outputs
            print("I can't get any real values!")
        }
        
        // 4) If iso=0, shutter=0, or aperture=0 => skip
        if iso <= 0 || shutterSpeed <= 0 || aperture <= 0 {
            DispatchQueue.main.async {
                self.lux = 0
                self.luxHistory.append(0)
                if self.luxHistory.count > self.kLuxHistoryCount {
                    self.luxHistory.removeFirst(self.luxHistory.count - self.kLuxHistoryCount)
                }
                self.showBlownOutWarning = false
            }
            return
        }
        
        // 5) average pixel brightness
        let sampleCount = Double(totalCount)
        let avgLuma = totalLuma / sampleCount
        
        // 6) normalizing formula from stack overflow:
        // L_final = L * (apertureRef^2 / aperture^2) * (isoRef / iso) * (shutterSpeed / shutterRef)
        // Then multiply by an overall scale factor => approximate lux
        let ratioAperture = Double(aperture*aperture) / Double(apertureRef*apertureRef)
        let ratioISO = Double(iso) / Double(iso/isoRef)
        let ratioShutter = Double(shutterSpeed) / Double(shutterRef)
        
        let normalizedValue = avgLuma * ratioAperture / (ratioISO * ratioShutter)
        let approximateLux = Float(normalizedValue * luxScaleFactor)
        
        // 7) Print for debugging
        print("""
        [Lux Calc] blowOut=\(blowOutRatio*100)%, iso=\(iso), aperture=\(aperture), shutter=\(shutterSpeed),
        avgLuma=\(avgLuma), ratioAperture=\(ratioAperture), ratioISO=\(ratioISO), ratioShutter=\(ratioShutter),
        => normalized=\(normalizedValue), => lux=\(approximateLux)
        """)
        
        // 8) Publish to SwiftUI
        DispatchQueue.main.async {
            self.lux = approximateLux
            self.showBlownOutWarning = blowOutWarning
            
            self.luxHistory.append(approximateLux)
            if self.luxHistory.count > self.kLuxHistoryCount {
                self.luxHistory.removeFirst(self.luxHistory.count - self.kLuxHistoryCount)
            }
        }
    }
}
