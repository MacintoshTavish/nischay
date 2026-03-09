# Stealth & Invisibility Implementation

## Overview
The defining feature of Nischay is its ability to remain completely invisible during screen-sharing sessions (like Zoom, Google Meet, or Slack Huddles), while still allowing the user to interact with the AI assistant. 

This behavior is broken down into two distinct parts:
1. **Window Invisibility:** Ensuring the app's own UI panels do not show up in the macOS system window picker when a user clicks "Share Screen".
2. **Capture Exclusion:** Ensuring that when Nischay records the screen for its OCR loop, it doesn't accidentally capture its own windows.

---

## 1. Window Invisibility (The `StealthManager`)

macOS AppKit provides specific, low-level properties on `NSWindow` to control how a window interacts with Desktop Window Manager (WindowServer) features.

### Reverse Engineering Context
We extracted the exact logic from the original `inputmethodd` binary by decompiling the `applyStealth()` function at address `0x100033fe4` via Ghidra.

The decompiled C showed:
```c
_objc_msgSend(window, "setSharingType:", 0);
_objc_msgSend(window, "setExcludedFromWindowsMenu:", 1);
```

### Swift Implementation
In `Sources/Nischay/Stealth/StealthManager.swift`, we replicate this line-by-line using Swift's AppKit overlays:

```swift
private static func applyToWindow(_ window: NSWindow) {
    // 1. setSharingType: 0 (.none)
    // Tells the WindowServer that this window's contents should NEVER be shared
    // with other applications (like Zoom/Slack's screen capture daemons).
    window.sharingType = .none

    // 2. setExcludedFromWindowsMenu: 1 (true)
    // Prevents the window from appearing in any global system window menus.
    window.isExcludedFromWindowsMenu = true
}
```

### Which windows does this apply to?
The `WindowManager` creates three main `NSPanel`s (HUDs). Immediately after creating them, it passes them to `StealthManager`:
- `mainWindow` (Chat UI)
- `controlsWindow` (Settings / Analyze buttons)
- `chatInputWindow` (The text prompt at the bottom)

It also safely loops through `window.childWindows` to catch any dropdown menus or popovers spawned by these panels.

---

## 2. Capture Exclusion (ScreenCaptureKit)

If Nischay is constantly capturing the screen (to feed the OCR loop), what happens if the user leaves the Nischay chat window open on top of their screen? Without exclusion, Nischay would capture its own chat window, feed it to the AI, and cause an infinite feedback loop.

### Reverse Engineering Context
The class dump revealed the use of `SCStreamCapture` and the selector `getShareableContentExcludingDesktopWindows:onScreenWindowsOnly:`.

### Swift Implementation
In `Sources/Nischay/Capture/ScreenCaptureManager.swift`, we use Apple's modern ScreenCaptureKit framework:

```swift
let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
```

By passing `excludingDesktopWindows: true`, ScreenCaptureKit automatically builds a `SCShareableContent` manifest that excludes "desktop level" elements. Since our `NSPanel` windows are configured with `LSUIElement` and `.nonactivatingPanel` behaviors without normal `NSApp` activation status, this flag reliably drops them from the capture stream.

We then pass this filtered content list to the `SCContentFilter`:
```swift
guard let display = content.displays.first else { return }
let filter = SCContentFilter(display: display, excludingWindows: [])
```

### Result
The `SCStreamOutput` delegate receives raw CMSampleBuffers of the user's screen — with the Nischay UI completely omitted, as if it was never there.
