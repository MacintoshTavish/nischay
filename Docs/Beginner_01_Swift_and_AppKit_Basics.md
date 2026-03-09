# 01. Swift and AppKit Basics for Nischay

## Introduction for Beginners
If you are new to macOS development, Nischay's codebase might look different from a standard iOS app or a modern SwiftUI mac app. Nischay is built using **Swift 6** and **AppKit** (Apple's original, low-level UI framework for macOS).

This document explains the foundational concepts used in Nischay, so you can understand *how* the app even starts running.

---

## 1. No Storyboards, No SwiftUI

Modern Apple development heavily pushes **SwiftUI**, which uses declarative syntax (e.g., `Text("Hello")`).
However, SwiftUI hides the underlying window objects from the developer. Because Nischay's core feature (Stealth) requires precise manipulation of the underlying window server flags, we had to use the older, more powerful framework: **AppKit**.

In AppKit, everything centers around `NSApplication`, `NSWindow`, and `NSViewController`. We build the UI **programmatically**—meaning we write code to create views, rather than dragging and dropping elements in a visual editor (like Interface Builder or Storyboards).

---

## 2. How the App Starts (`main.swift`)

When you run a Swift program, the computer needs to know where to start. In standard iOS/macOS apps, this is hidden Behind a `@main` attribute. In Nischay, we take manual control using a `main.swift` file.

```swift
import AppKit

// 1. Create the shared application instance
let app = NSApplication.shared

// 2. Create our custom AppDelegate
let delegate = AppDelegate()
app.delegate = delegate

// 3. Start the continuous event loop
app.run()
```

### Concept: The Run Loop (`app.run()`)
A macOS app does not just run its code top-to-bottom and exit. `app.run()` starts the **Run Loop**. This is an infinite loop that sits quietly, waiting for events (like mouse clicks, key presses, or network responses). When an event happens, the run loop wakes up, processes it, updates the screen, and goes back to sleep.

---

## 3. The `AppDelegate`

When `app.run()` starts, it hands control over to the `AppDelegate`. The concept of a "Delegate" in Apple development is like an assistant. The system says, "Hey, an important event happened (like the app finishing launching), what should I do?" and the Delegate provides the answer.

### `applicationDidFinishLaunching`
This is the most important method in `AppDelegate.swift`. It is called once, immediately after the app is loaded into memory.

```swift
func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Hide the app from the Dock and CMD+TAB
    NSApp.setActivationPolicy(.accessory)
    
    // Start the heavy lifting
    systemDelegate.setup()
}
```

### `.accessory` Activation Policy
Normally, launching a macOS app puts a bouncing icon in your Dock and adds a menu bar at the top of the screen.
Setting the activation policy to `.accessory` tells macOS: *"I am a background utility tool. Do not show me in the Dock, and do not show me in the Command+Tab switcher."*

---

## 4. Understanding View Controllers (`NSViewController`)

In AppKit, the screen is broken down into manageable chunks.
- An **`NSWindow`** (or `NSPanel` in our case) is the literal window frame you can move around the screen.
- An **`NSViewController`** is the brains that manage the content *inside* that window.

In Nischay:
- `MainSplitViewController` manages the layout.
- `ResponseViewController` manages the chat bubbles inside the layout.
- `ControlsViewController` manages the buttons.

By separating these, the code remains clean. If we put all the chat logic and all the button logic into one giant file, it would be impossible to maintain.

## Summary for Beginners
- Nischay uses **AppKit** (not SwiftUI) for low-level control over windows.
- The app execution starts in `main.swift`, which starts the infinite **Run Loop**.
- Control is handed to `AppDelegate`, which immediately hides the app from the Dock.
- `NSViewController` classes are used to manage different puzzle pieces of the user interface.
