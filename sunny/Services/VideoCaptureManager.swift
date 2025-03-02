import Foundation
import AVFoundation
import SwiftUI

/// A class that handles front camera capture, locks exposure,
/// and calculates approximate lumens (or lux) estimate based on
/// average pixel brightness, ISO, shutter speed, and aperture.
/// Must be a class to adopt AVCaptureVideoDataOutputSampleBufferDelegate.
final class VideoCaptureManager: NSObject, ObservableObject {
    
    // Published approximate lumens read by SwiftUI
    @Published var lumens: Float = 0.0
    
    // We store a rolling history of lumens for up to 15 minutes (900 seconds).
    @Published var lumensHistory: [Float] = []
    
    // Internals
    private var captureSession: AVCaptureSession?
    private let videoOutput = AVCaptureVideoDataOutput()
    private var activeDevice: AVCaptureDevice?
    
    /// We'll use a separate queue to configure and start the session
    private let sessionQueue = DispatchQueue(label: "com.sunny.videoSessionQueue")
    
    func startSession() {
        // Move session setup off the main thread
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
                try device.lockForConfiguration()
                let desiredISO: Float = 100.0
                let minDuration = CMTimeMake(value: 1, timescale: 60)  // 1/60
                if device.isExposureModeSupported(.custom) {
                    device.setExposureModeCustom(duration: minDuration, iso: desiredISO, completionHandler: nil)
                }
                device.unlockForConfiguration()
                
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
                
                // Start running in background
                session.startRunning()
                self.captureSession = session
                
            } catch {
                print("Error setting up camera input or locking exposure: \(error)")
            }
        }
    }
    
    func stopSession() {
        // Also do this off main thread to avoid blocking UI
        sessionQueue.async {
            self.captureSession?.stopRunning()
            self.captureSession = nil
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension VideoCaptureManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        // 1) Compute average pixel brightness
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer)?
            .assumingMemoryBound(to: UInt8.self) else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            return
        }
        
        var totalLuma: Double = 0
        let step = 20
        
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let offset = (y * width + x) * 4
                // BGRA
                let b = Double(base[offset + 0])
                let g = Double(base[offset + 1])
                let r = Double(base[offset + 2])
                // naive luminance
                let lum = 0.299*r + 0.587*g + 0.114*b
                totalLuma += lum
            }
        }
        
        let samples = (width/step) * (height/step)
        let avgPixelLuma = totalLuma / Double(samples)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        
        // 2) Gather exposure settings
        var iso: Float = 100.0
        var shutterSpeed: Float = 1.0/60.0
        var aperture: Float = 2.2  // default guess if lensAperture is unknown
        if let device = activeDevice {
            iso = device.iso
            let duration = device.exposureDuration
            if duration.isNumeric && duration.timescale != 0 {
                shutterSpeed = Float(duration.value) / Float(duration.timescale)
            }
            aperture = device.lensAperture
        }
        
        // 3) Approximate lumens or lux from these:
        let ev = log2( (Double(aperture * aperture) / Double(shutterSpeed)) * (100.0 / Double(iso)) )
        
        let pixelNorm = avgPixelLuma / 255.0
        // scale factor
        let c: Double = 250.0
        
        let approximateLux = c * pow(2.0, ev) * pixelNorm
        let approxLumens = Float(approximateLux)
        
        // 4) Publish to SwiftUI
        DispatchQueue.main.async {
            self.lumens = approxLumens
            
            // Track rolling history of last 15 minutes (900 samples if ~1 fps).
            self.lumensHistory.append(approxLumens)
            if self.lumensHistory.count > 900 {
                self.lumensHistory.removeFirst(self.lumensHistory.count - 900)
            }
        }
    }
}
