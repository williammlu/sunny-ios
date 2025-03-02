import Foundation
import AVFoundation
import SwiftUI

/// A class that handles front camera capture, locks exposure,
/// and calculates an approximate lumens (or lux) estimate based on
/// average pixel brightness, ISO, shutter speed, and aperture.
/// Must be a class to adopt AVCaptureVideoDataOutputSampleBufferDelegate.
final class VideoCaptureManager: NSObject, ObservableObject {
    
    // Published approximate lumens read by SwiftUI
    @Published var lumens: Float = 0.0
    @Published var brightnessValue: Float = 0.0
    
    // Internals
    private var captureSession: AVCaptureSession?
    private let videoOutput = AVCaptureVideoDataOutput()
    private var activeDevice: AVCaptureDevice?
    
    // For camera setup
    func startSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front) else {
            print("No front camera available.")
            return
        }
        activeDevice = device
        
        do {
            // Attempt to lock exposure to a known mode:
            try device.lockForConfiguration()
            // For instance, set it to a constant ISO and shutter speed if possible:
            let desiredISO: Float = 100.0
            let minDuration = CMTimeMake(value: 1, timescale: 60)  // 1/60
            if device.isExposureModeSupported(.custom) {
                // Set manual exposure
                device.setExposureModeCustom(duration: minDuration, iso: desiredISO, completionHandler: nil)
            }
            device.unlockForConfiguration()
            
            // Build input:
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
            
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
            
            session.startRunning()
            self.captureSession = session
        } catch {
            print("Error setting up camera input or locking exposure: \(error)")
        }
    }
    
    func stopSession() {
        captureSession?.stopRunning()
        captureSession = nil
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
            // Note: might fail if device is not locked or if not available
            iso = device.iso
            // Shutter speed in fractional seconds:
            let duration = device.exposureDuration
            if duration.isNumeric && duration.timescale != 0 {
                shutterSpeed = Float(duration.value) / Float(duration.timescale)
            }
            aperture = device.lensAperture
        }
        
        // 3) Approximate lumens or lux from these:
        // (We can do a rough approach: we assume EV = log2(aperture^2 / shutterSpeed * 100 / iso).
        // Then we combine with average pixel luma. This is purely heuristic and uncalibrated:
        
        let ev = log2( (Double(aperture * aperture) / Double(shutterSpeed)) * (100.0 / Double(iso)) )
        
        // We'll just combine EV with avgPixelLuma in a random scaling. In reality, you'd calibrate.
        // e.g. approximateLux = constant * 2^ev * (avgPixelLuma / 255)
        
        let pixelNorm = avgPixelLuma / 255.0
        // A random scale factor "C" to get into a 0..200k lux-ish range for sun:
        let c: Double = 250.0
        
        let approximateLux = c * pow(2.0, ev) * pixelNorm
        
        // If we want "lumens" we can either treat them like lux over an area etc. We'll just call it lumens for demonstration:
        let approxLumens = Float(approximateLux)
        
        // 4) Publish to SwiftUI
        DispatchQueue.main.async {
            self.lumens = approxLumens
            self.brightnessValue = approxLumens
            
        }
    }
}
