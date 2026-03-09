# Screen Capture & OCR Pipeline

## Overview
A core requirement of Nischay is to "read" the user's screen in real-time without taking explicit screenshots that save to the disk or trigger loud camera shutter sounds. To achieve this quietly and efficiently, we combined two modern Apple frameworks: **ScreenCaptureKit** and **Vision**.

---

## 1. ScreenCaptureKit (`ScreenCaptureManager.swift`)

ScreenCaptureKit is Apple's high-performance framework for recording the screen, introduced in macOS 12.3. It is significantly more efficient than older methods like `CGWindowListCreateImage` and allows for fine-grained filtering.

### Configuration
We configure the `SCStreamConfiguration` for optimal text-reading performance while keeping CPU usage low:
- `minimumFrameInterval = CMTime(value: 1, timescale: 2)` (Caps capture at 2 frames per second. We don't need 60 FPS for reading text).
- `showsCursor = false` (Cursor obstructs text).
- `queueDepth = 3` (Keep memory footprint low).

### The Invisibility Filter
As documented in the Stealth Implementation, the critical filter applied is:
```swift
let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
let filter = SCContentFilter(display: display, excludingWindows: [])
```
This guarantees the stream never contains Nischay's own UI.

### Frame Processing
The manager conforms to `SCStreamOutput`. Every time a frame is captured, `stream(_:didOutputSampleBuffer:of:)` is called.
We extract the `CVPixelBuffer` from the sample buffer and convert it to a `CGImage`, which is then passed via the `ScreenCaptureDelegate` to the system delegate.

---

## 2. Text Extraction (`VisionOCRManager.swift`)

Apple's built-in **Vision** framework provides fast, entirely on-device Optical Character Recognition (OCR). This means no images are ever sent over the internet—only the extracted text is sent to the AI.

### Configuration
```swift
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true
```
We use `.accurate` over `.fast` because AI context relies on correct spelling of code snippets, URLs, and complex technical terms that appear on the screen.

### Execution
The `CGImage` received from the capture manager is wrapped in a `VNImageRequestHandler`.
Once the request finishes, we iterate through the recognized text observations:
```swift
let recognizedText = observations.compactMap { observation in
    observation.topCandidates(1).first?.string
}.joined(separator: "\n")
```

### Pipeline Result
The combined text string represents everything visible on the user's screen (excluding Nischay itself) at that exact millisecond. 

This string is held in memory by `NischaySystemDelegate.lastScreenText`. When the user types a question and hits Enter, this string is immediately injected into the prompt alongside the user's question, resulting in zero perceived latency for the capture step.
