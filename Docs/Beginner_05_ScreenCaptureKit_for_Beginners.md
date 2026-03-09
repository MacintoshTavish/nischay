# 05. ScreenCaptureKit for Beginners

## Introduction for Beginners
Historically, taking a screenshot programmatically on a Mac was messy. You had to use old, deprecated C-based frameworks like `CGWindowListCreateImage`, which triggered ugly system alerts, drained the battery, and struggled to exclude specific windows.

In macOS 12.3, Apple introduced **ScreenCaptureKit** (SCK). SCK is modern, heavily optimized, utilizes hardware acceleration, and respects battery life.

Nischay relies entirely on ScreenCaptureKit to constantly monitor the pixels on your screen so they can be fed into the AI.

---

## 1. The Three Layers of ScreenCaptureKit

To record the screen using SCK, you need three distinct pieces of configuration:

### Layer A: The Content (`SCShareableContent`)
Before you can record, you have to tell SCK *what* you are allowed to record.
SCK asks the system for a manifest of every single Display, Application, and Window currently active.

```swift
let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
```

**The Invisibility Magic:** 
Why do we specify `excludingDesktopWindows: true`? 
By defining Nischay's panels as `.floating` and `.nonactivatingPanel` (as explained in the Stealth docs), they classify as "Desktop Windows." By telling SCK to exclude them here, SCK completely forgets Nischay exists. When the final recording starts, Nischay will literally not be in the video feed.

### Layer B: The Filter (`SCContentFilter`)
Now that we have the list of everything on the computer, we create a filter. Our filter says, "Target the primary display, and use the exclusion list we just made."

```swift
let filter = SCContentFilter(display: display, excludingWindows: [])
```

### Layer C: The Configuration (`SCStreamConfiguration`)
This is where we tell SCK *how* to record the stream. 

If we record at 60 Frames Per Second (FPS) at 4K resolution, the CPU will melt reading text that isn't moving. Since we are just making a chatbot that reads text, we throttle it intentionally.

```swift
let config = SCStreamConfiguration()
config.showsCursor = false // We don't want the mouse pointer covering text
config.queueDepth = 3 // Only keep exactly 3 frames in memory so we never cause a memory leak
config.minimumFrameInterval = CMTime(value: 1, timescale: 2) // Exactly 2 FPS.
```
This is a massive optimization. We only grab two static screenshots a second, leaving the CPU completely idle 90% of the time.

---

## 2. The `SCStream` and the Delegate

Once the filter and the config are ready, we create the `SCStream` (the actual recording engine) and tell it to start.
But where do the recorded pixels go?

They go to our **Delegate**.
A delegate is an assistant that says, "Hey, SCK just gave me a new frame of video. What should I do with it?"

```swift
func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
    // We receive a CMSampleBuffer at exactly 2 FPS.
}
```

### What is a `CMSampleBuffer`?
A `CMSampleBuffer` is a raw clump of timing data, audio bytes, and video bytes from deep inside the operating system. We can't display a `CMSampleBuffer` as an image easily, nor can we read text from it.

Inside our delegate, we do some low-level CoreVideo math to extract a `CVPixelBuffer` from the sample buffer, translate it into a standard `CGImage` (Core Graphics Image), and pass that image along to the Vision Framework for OCR.

## Summary for Beginners
- **ScreenCaptureKit** replaced the older, inefficient screenshot methods in macOS.
- It requires a **ShareableContent** list (where we surgically exclude Nischay's stealth windows).
- It requires a **Configuration** (where we cap it at 2 frames-per-second to save battery).
- It delivers raw data chunks (`CMSampleBuffer`) into a **delegate** method, which we unpack and convert into a traditional image (`CGImage`).
