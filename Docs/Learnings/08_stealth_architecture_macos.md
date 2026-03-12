# Deep Dive: Stealth App Architecture on macOS

## Overview
Building an application that remains invisible to proctoring software while maintaining full functionality requires a deep understanding of the macOS Window Server and ScreenCaptureKit. This document outlines the technical implementation of "Stealth Mode" in Nischay.

## 1. Window System Exclusion
Standard windows in macOS are visible to any application capturing the screen. To bypass this, Nischay utilizes `NSPanel` with specific collection behaviors.

### Implementation:
We set the `sharingType` of the window to `none` and exclude it from the window menu.

```swift
// Core Stealth Implementation
window.sharingType = .none
window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
```

### Why this works:
- `sharingType = .none`: Explicitly tells the macOS Window Server that this window's content should NOT be included in any screen capture or screen recording stream initiated by other apps.
- `canJoinAllSpaces`: Ensures the overlay persists even when the user switches desktops.

## 2. Bypassing ScreenShare Pickers
Most proctoring tools use the `SCShareableContent` API to list available windows for sharing. Nischay's windows are designed to be "invisible" to this list.

### Technique:
By using the `isExcludedFromWindowsMenu` property and setting the window level to `NSWindow.Level.statusBar + 1`, we move the UI into a specialized layer that standard capture tools often overlook.

```swift
window.isExcludedFromWindowsMenu = true
window.level = .statusBar + 1
```

## 3. ScreenCaptureKit Integration
While being invisible to others, Nischay must still "see" the screen. We use `ScreenCaptureKit` (introduced in macOS 12.3) for high-performance, system-level capture.

### Filtering Self-Capture:
To avoid "Inception" effects (capturing our own invisible windows), we use `SCContentFilter` to exclude our running process.

```swift
let filter = SCContentFilter(display: display, excludingApplications: [myAppInstance], exceptingWindows: [])
```

## 4. Hardware-Level Guardrails
Some proctoring tools attempt to detect the presence of "Overlays" by querying the system for windows with specific transparency or levels. Nischay mitigates this by:
1.  **Dynamic Transparency**: The user can slide transparency to 0% instantly.
2.  **Global Kill-switch**: A single designated key (Backslash `\`) instantly tears down all UI panels.

## Summary
The combination of `sharingType = .none`, `SCContentFilter` exclusions, and high-level window layering creates a robust stealth layer that is mathematically excluded from standard macOS screen capture streams.
