# Nischay – App Overview & Architecture

## Core Purpose
Nischay is a stealthy macOS menu-bar agent that captures the user's screen, extracts text via OCR, and uses AI (Supabase Edge Functions + OpenAI) to analyze the content and answer questions. It is designed to be completely invisible to screen-sharing applications.

## High-Level Architecture

The app is built natively in Swift for macOS (v14+). It does not use SwiftUI, opting instead for raw AppKit `NSPanel` and `NSViewController` elements to achieve precise floating behaviors and window levels that bypass traditional macOS window management.

### The 4 Core Pillars

1. **Stealth & Windowing (`StealthManager`, `WindowManager`)**
   - No Dock icon (`LSUIElement = 1`).
   - Uses `NSPanel` with `.nonactivatingPanel` and `.floating` levels.
   - The critical stealth API is `window.sharingType = .none` and `window.isExcludedFromWindowsMenu = true`. This combination prevents the windows from appearing in Zoom/Google Meet sharing pickers.

2. **Screen Capture & OCR (`ScreenCaptureManager`, `VisionOCRManager`)**
   - Uses Apple's modern **ScreenCaptureKit** (`SCStream`).
   - Specifically calls `SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)`, which is the second half of the "invisibility" equation — ensuring our own app's windows don't get captured by our own stream.
   - Captured frames (`CGImage`) are passed to Apple's **Vision framework** (`VNRecognizeTextRequest`) for fast, on-device OCR.

3. **Backend Integration (`SupabaseManager`, `OpenAIManager`, `AuthManager`)**
   - **Supabase** acts as the primary backend:
     - **Auth:** OAuth PKCE flow (via GitHub/Google, etc.).
     - **Edge Functions:** 6 endpoints handle screen analysis (`analyze-screen`), usage quotas (`check-usage`), and subscription tiers (`check-subscription`).
     - **Database:** Chat history is saved and loaded via Supabase REST APIs.
   - **Server-Sent Events (SSE):** The screen analysis endpoint returns a streaming response. The app parses `data: ` chunks manually to update the UI in real-time.
   - **OpenAI Fallback:** If Edge Functions are disabled, the app uses `OpenAIManager` to reach out directly to `api.openai.com` for Chat Completions or Vision.

4. **User Interface (`NischaySystemDelegate`, ViewControllers)**
   - `NischaySystemDelegate` is the "god object" that wires all sub-managers together.
   - The UI is composed of three stacked `NSPanel`s:
     - `MainSplitViewController` (Chat history + AI responses)
     - `ControlsViewController` (Settings, analyze button)
     - `ChatInputView` (Text field for user questions)
   - Real-time chat bubbles are rendered via `ChatBubbleManager`, allowing streaming text updates in place.

---

## Technical Stack & Frameworks

| Category | Technology |
|----------|------------|
| **Language** | Swift 6.0 (Package Manager, macOS target) |
| **UI Framework** | AppKit (NSPanel, NSStackView, NSViewController) |
| **Screen Capture** | ScreenCaptureKit |
| **OCR** | Vision (VNRecognizeTextRequest) |
| **Concurrency** | Swift Structured Concurrency (`async/await`, `Task`) |
| **Networking** | `URLSession` (REST, SSE parsing) |
| **Persistence** | `UserDefaults` (Session tokens, config) |

---

## Design Decisions & Alternatives

### 1. AppKit vs SwiftUI
**Decision:** We chose raw AppKit (`NSPanel`) over SwiftUI.
**Why:** SwiftUI `Window` and `WindowGroup` types abstract away the underlying `NSWindow` properties (like `sharingType` and `isExcludedFromWindowsMenu`). Applying the precise "stealth" APIs requires direct pointer access to the `NSWindow` objects. Wrapping this in SwiftUI (`NSWindowRepresentable`) introduces unnecessary complexity and lifecycle bugs when dealing with floating HUD panels. AppKit gives direct, low-level control.

### 2. ScreenCaptureKit vs CGWindowListCreateImage
**Decision:** `ScreenCaptureKit` was chosen over legacy CoreGraphics / Quartz Window Services.
**Why:** `CGWindowListCreateImage` is deprecated, highly inefficient, and triggers intense privacy warnings on modern macOS. `ScreenCaptureKit` supports hardware acceleration, provides the `excludingDesktopWindows` API natively, and allows us to dictate frame rates (`CMTime`) easily to keep CPU usage low during continuous OCR.

### 3. Edge Functions vs Direct OpenAPI Calls
**Decision:** The app routes analysis through Supabase Edge Functions first, with a direct OpenAI fallback.
**Why:** Client-side API keys are insecure. Routing through Supabase allows us to:
1. Hide the OpenAI API key server-side.
2. Enforce usage limits (e.g., calling `check-usage` before allowing the analysis).
3. Gate features behind subscription tiers.

### 4. Continuous OCR vs On-Demand Snapshot
**Decision:** The app captures continuously at a low frame rate (e.g., 2 frames per second), constantly doing OCR in the background.
**Why:** When the user hits the hotkey (`\`) and asks a question, the screen state may have already changed. By keeping a rolling buffer of `lastScreenText`, the prompt is instantly ready without waiting for a new screenshot → OCR → completion pipeline. The tradeoff is higher background CPU usage, mitigated by the low frame interval config.
