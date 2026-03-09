# Nischay

**Nischay** is a stealthy macOS assistant built natively in Swift. It acts as an invisible overlay that can "read" your screen using real-time Apple Vision OCR and answer contextual questions via AI (Supabase Edge Functions + OpenAI).

Nischay was developed as a clean-room reimplementation based entirely on reverse-engineering insights (bypassing the WindowServer, utilizing ScreenCaptureKit exclusions, and mimicking the exact backend API flow).

## Key Features

- **True Stealth:** The application runs completely hidden from screen-sharing pickers (Zoom, Google Meet, Slack Huddles, etc.). 
- **Low-Latency Screen Reading:** Uses `ScreenCaptureKit` to keep a rolling 2 FPS buffer of what is on your screen, extracting text locally on-device via Apple's `Vision` framework.
- **Global Access:** Toggle the transparent, floating chat UI from anywhere using the `\` (backslash) key.
- **AI Integration:** Forwards screen context + user questions to Supabase Edge Functions, returning answers via a real-time Server-Sent Events (SSE) stream.
- **Chat History:** Seamlessly syncs your conversation history to a backend PostgreSQL database.

## Documentation

Extensive documentation of the app's architecture and the reverse-engineering decisions Behind it can be found in the `Docs/` directory:

1. [`01_Architecture_Overview.md`](Docs/01_Architecture_Overview.md): High-level breakdown of the 4 core pillars (Stealth, Capture, API, UI) and why raw AppKit was chosen over SwiftUI.
2. [`02_Stealth_Implementation.md`](Docs/02_Stealth_Implementation.md): Explains the technical mechanics behind window invisibility (`sharingType = .none`).
3. [`03_Screen_Capture_OCR.md`](Docs/03_Screen_Capture_OCR.md): Details the efficient 2 FPS ScreenCaptureKit loop and `SCShareableContent` exclusions.
4. [`04_Supabase_API_Integration.md`](Docs/04_Supabase_API_Integration.md): Outlines the 6 Edge Function endpoints, the pre-flight usage checks, and the direct OpenAI fallback.
5. [`05_UI_Architecture.md`](Docs/05_UI_Architecture.md): How the Tri-Panel overlay works, and how the chat bubbles support streaming text updates.
6. [`06_Chat_History_Persistence.md`](Docs/06_Chat_History_Persistence.md): How state is managed in RAM and synced to Supabase.

## Building the App

*Note: The project uses the modern Swift Package Manager structure with `swift-tools-version: 6.0`.*

1. **Prerequisites:** Ensure you have **Xcode** installed from the Mac App Store (the basic CommandLineTools are insufficient for this SPM structure due to a linking issue with `PackageDescription`).
2. **Open the Project:** Double-click on `Package.swift` to open the package in Xcode.
3. **Capabilities:** In the Target settings -> Signing & Capabilities, add the **Screen Recording** capability and ensure the `Nischay.entitlements` file is linked.
4. **Build & Run:** Hit `Cmd + R` to run.

## Setup & Configuration

Once running, you can click the settings gear (bottom left) or inject your own backend credentials directly into the App's UserDefaults:

```swift
// Example UserDefaults Configuration
UserDefaults.standard.set("https://your-project.supabase.co", forKey: "supabaseURL")
UserDefaults.standard.set("your-anon-key", forKey: "supabaseAnonKey")
UserDefaults.standard.set("sk-your-openai-key", forKey: "openAIAPIKey")
```

If Supabase is omitted, Nischay will fall back strictly to direct OpenAI API calls (useful for private, offline-history usage).
