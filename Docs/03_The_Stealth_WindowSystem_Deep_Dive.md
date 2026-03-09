# 03. The Stealth Window System Deep Dive

## Introduction for Beginners
When you join a Zoom or Google Meet call and click "Share Screen", a menu pops up showing you all the windows currently open on your Mac. The most "magical" trick of Nischay is that its windows *never appear in that menu*. 

How does an app lie to the operating system? We must understand the **WindowServer**.

---

## 1. What is the WindowServer?

In macOS, when an app draws a window, it doesn't draw directly to your physical monitor. It draws onto an invisible canvas in memory, and hands it to a core macOS process called **WindowServer**. 

WindowServer collects canvases from Safari, Xcode, Finder, and Nischay, stacks them up, composites them together (handling transparency and drop shadows), and paints the final result to your display hardware.

Because WindowServer knows about every window, screen-sharing apps (like Zoom) ask WindowServer: *"Give me a list of all visual windows."*

---

## 2. NSPanel vs NSWindow

Nischay builds its UI using **`NSPanel`**, which is a special subclass of `NSWindow`.
A standard `NSWindow` is meant for heavy documents (like a Word document). An `NSPanel` is meant for utility HUDs (Heads-Up Displays) and floating tool palettes.

### Floating Above Everything
In `WindowManager.swift`, we set:
```swift
panel.level = .floating
```
Normally, windows are painted at `.normal` level. If Safari is active, it paints above Xcode. By setting `.floating`, WindowServer is instructed to *always* paint Nischay on top of `.normal` windows, ensuring the user can always see the AI context.

### Non-Activating
```swift
panel.styleMask = [.borderless, .nonactivatingPanel]
```
If you are typing in Safari, and you click a normal window, Safari loses focus (the traffic light buttons turn gray) and the new window gains focus. 
By making Nischay an `.nonactivatingPanel`, you can click Nischay's buttons or type in its chat input, and Safari *keeps its focus*. Nischay never steals the spotlight.

---

## 3. Lying to the WindowServer (The Stealth Mechanics)

The ultimate stealth requirement was reverse-engineered from the original app (inputmethodd). We found a C function called `applyStealth` that did two things. In Swift, it looks like this:

### Trick 1: `window.sharingType = .none`
Every window has a `sharingType` property. 
- By default, it is `.readOnly` (meaning Zoom is allowed to read the pixels of this window to broadcast them).
- By setting it to **`.none`**, we send a hardware-level instruction to WindowServer: *"Under no circumstances are you allowed to hand the pixel data of this canvas to any other application."*
- As a result, when Zoom asks WindowServer for the screen, WindowServer literally paints a black box over where Nischay is, or omits it entirely from window pickers.

### Trick 2: `window.isExcludedFromWindowsMenu = true`
macOS maintains a global "Window" menu in the top menu bar, and Mission Control (Exposé) uses this registry to fan out all your open windows.
- By setting this to `true`, Nischay tells macOS to remove it from the global registry of human-interactable windows. Mission Control will completely ignore Nischay.

## Summary for Beginners
- macOS composites all graphics via the **WindowServer**.
- Nischay uses **`NSPanel`** to float above other apps without stealing focus (`.nonactivatingPanel`).
- We achieve absolute stealth by setting `sharingType = .none`, stripping the window of its right to be recorded by third-party apps like Zoom or Slack.
