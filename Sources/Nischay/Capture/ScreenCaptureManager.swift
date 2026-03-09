import AppKit
import ScreenCaptureKit
import CoreMedia

/// Manages screen capture via ScreenCaptureKit.
/// Mirrors SCStreamCapture from the RE class dump (stream, delegate ivars).
/// Uses excludingDesktopWindows:onScreenWindowsOnly: so our own stealth windows
/// don't appear in the system screen-share picker.
class ScreenCaptureManager: NSObject {

    weak var delegate: ScreenCaptureDelegate?

    private var stream: SCStream?
    private let captureQueue = DispatchQueue(label: "com.nischay.capture", qos: .userInitiated)
    private var isCapturing = false

    // MARK: - Permission

    func checkAndRequestPermission(completion: @escaping (Bool) -> Void) {
        Task {
            do {
                // Attempting to list shareable content triggers the macOS permission dialog
                _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                completion(true)
            } catch {
                print("Nischay: Screen capture permission denied – \(error)")
                completion(false)
            }
        }
    }

    // MARK: - Continuous Capture (for OCR loop)

    func startCapture() {
        guard !isCapturing else { return }
        isCapturing = true
        Task { await _startStream() }
    }

    private func _startStream() async {
        do {
            // Exclude our own windows: this is the "Invisibility mode for screen sharing"
            let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
            guard let display = content.displays.first else { return }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let cfg = SCStreamConfiguration()
            cfg.width  = Int(display.width)
            cfg.height = Int(display.height)
            // Slower frame rate for OCR loop (mirrors ocrInterval config)
            cfg.minimumFrameInterval = CMTime(value: 1, timescale: ConfigManager.shared.ultraFastMode ? 10 : 2)
            cfg.queueDepth = 3

            let s = SCStream(filter: filter, configuration: cfg, delegate: self)
            try s.addStreamOutput(self, type: .screen, sampleHandlerQueue: captureQueue)
            try await s.startCapture()
            self.stream = s
        } catch {
            print("Nischay: Failed to start capture stream – \(error)")
            isCapturing = false
        }
    }

    func stopCapture() {
        guard isCapturing else { return }
        isCapturing = false
        let s = stream
        stream = nil
        Task { try? await s?.stopCapture() }
    }

    // MARK: - Single Screenshot

    func captureScreenshot() async -> NSImage? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
            guard let display = content.displays.first else { return nil }
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let cfg = SCStreamConfiguration()
            cfg.width  = Int(display.width)
            cfg.height = Int(display.height)
            let cg = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: cfg)
            return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
        } catch {
            print("Nischay: Screenshot failed – \(error)")
            return nil
        }
    }
}

// MARK: - SCStreamDelegate
extension ScreenCaptureManager: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("Nischay: Stream stopped – \(error)")
        isCapturing = false
    }
}

// MARK: - SCStreamOutput
extension ScreenCaptureManager: SCStreamOutput {
    func stream(_ stream: SCStream,
                didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
                of type: SCStreamOutputType) {
        guard type == .screen, let pixelBuffer = sampleBuffer.imageBuffer else { return }
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        let context = CIContext()
        guard let cg = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
        DispatchQueue.main.async { [weak self] in self?.delegate?.didCaptureFrame(image) }
    }
}
