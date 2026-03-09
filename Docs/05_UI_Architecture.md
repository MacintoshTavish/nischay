# UI Architecture

## Overview
Unlike most standard macOS apps that use a single `NSWindow` with built-in title bars and traffic lights (red/yellow/green buttons), Nischay relies on an overlay architecture. 

It uses raw AppKit `NSPanel` objects layered on top of all other applications. 

---

## 1. The Tri-Panel Structure (`WindowManager.swift`)

The user interface is not monolithic; it is composed of three separate, borderless, transparent windows that move and fade together.

### Panel A: `mainWindow` (The Content Layer)
- **Role:** Displays chat history, AI streaming text, and voice transcription playback.
- **Controller:** `MainSplitViewController`, which contains the `ResponseViewController`.
- **Properties:**
  - `styleMask = [.borderless, .nonactivatingPanel]`
  - `level = .floating` (Keeps it above normal apps)
  - `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]` (Ensures it follows the user across multiple desktop spaces).

### Panel B: `chatInputWindow` (The Input Layer)
- **Role:** Docks at the bottom of the main window. Contains the NSTextField where the user types questions about their screen.
- **Controller:** None (Uses a raw `ChatInputView`).
- **Interaction:** Because `.nonactivatingPanel` is used, clicking into this text field does not steal focus from the user's active application (e.g., Xcode or Safari). The user can type into Nischay while their other app remains visually active.

### Panel C: `controlsWindow` (The Utility Layer)
- **Role:** Docks below the main window, providing quick access to Settings, "Short" mode toggle, and the manual "Analyze Screen" button.
- **Controller:** `ControlsViewController`.

---

## 2. Rendering the Chat (`ChatBubbleManager.swift`)

Nischay implements a custom chat UI layout within `ResponseViewController` using standard `NSStackView`.

### The ChatBubbles
A `ChatBubbleView` is an `NSTextField` styled to look like an iMessage bubble:
- `user` messages align right, tinted blue (`NSColor.controlAccentColor.withAlphaComponent(0.15)`).
- `assistant` messages align left, tinted gray (`NSColor.windowBackgroundColor.withAlphaComponent(0.05)`).
- `error` messages appear red.

### Streaming Text Support
When a long response is streaming from the OpenAI/Supabase backend, creating a new `NSTextField` for every word would kill performance.
Instead, `ChatBubbleManager` keeps a reference to `lastBubble`. 
When the `NischaySystemDelegate` broadcasts intermittent chunks via `NotificationCenter` (`.nischayAnalysisUpdate`), the manager simply appends the chunk to `lastBubble.stringValue`.

---

## 3. The Global Toggle (`GlobalShortcutManager.swift`)

To feel like an invisible assistant, the UI must appear and vanish instantly without clicking a dock icon (which Nischay doesn't have).

### Implementation
We use macOS's Accessibility APIs to listen for key presses globally:
```swift
NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
    // keyCode 42 is the backslash '\' key on standard US keyboards
    if event.keyCode == 42 {
        self.onToggle?()
    }
}
```

When triggered, `WindowManager.toggleInterface()` is called, which simultaneously animates the `alphaValue` of all three NSPanels on or off, creating a smooth fade-in/fade-out effect.
