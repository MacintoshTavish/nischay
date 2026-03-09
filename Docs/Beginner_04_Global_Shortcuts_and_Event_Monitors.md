# 04. Global Shortcuts and Event Monitors

## Introduction for Beginners
Most apps only know you pressed a key if that app is currently the "active" window (like typing a URL into Safari). If Safari is active, and you press the Spacebar, Safari scrolls down. The Notes app doesn't know you pressed the Spacebar.

Nischay needs to be summoned instantly from *anywhere*. If you are staring at Xcode and want to ask Nischay a question, you press the `\` (backslash) key. How does Nischay know you pressed `\` if Xcode is the active window?

It uses **Global Event Monitors**.

---

## 1. What is an Event Monitor?

macOS processes every mouse movement, scroll wheel turn, and key press as an "Event" (`NSEvent`). These events are fired rapidly across the system. 

Apple allows certain authorized apps to "eavesdrop" on the system's global event stream. We do this using:
```swift
NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
    // This block runs every time ANY key is pressed, anywhere on the Mac.
}
```

### The Accessibility Security Requirement
Apple considers eavesdropping on other apps' keystrokes to be a massive security risk (it's how a keylogger virus works). 
Therefore:
1. Nischay's **Sandbox** must be disabled (as explained in the Permissions document).
2. The first time Nischay tries to run this code, macOS will block it and show an alert: *"Nischay would like to control this computer using accessibility features."*
3. The user must manually open `System Settings -> Privacy & Security -> Accessibility` and toggle the switch on for Nischay.

If the user denies this permission, the `addGlobalMonitorForEvents` function simply fails silently, and the `\` key shortcut will never work.

---

## 2. Reading the Key Code

When the global monitor captures a "keyDown" event, it hands us an `NSEvent` object. 

Keyboards around the world have different layouts (QWERTY, AZERTY, Dvorak), so checking if the user pressed the literal string `"\"` is notoriously unreliable in low-level programming. Instead, we use **Key Codes**, which are physical hardware locations on the keyboard.

```swift
if event.keyCode == 42 {
    // The physical key above the Return key (usually '\') was pressed
    self.onToggle?()
}
```

By checking `event.keyCode == 42`, we are bypassing language layouts entirely. 

---

## 3. The Toggle Animation

When the `onToggle` closure is fired, it reaches the `WindowManager`.

```swift
func toggleInterface() {
    let newState = !isVisible
    NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.2
        mainWindow?.animator().alphaValue = newState ? 1.0 : 0.0
        // ... (fades all other windows too)
    }
}
```

By using `NSAnimationContext`, we tell macOS to smoothly interpolate the `alphaValue` (transparency) of our stealth windows from `0.0` (invisible) to `1.0` (fully solid) over exactly 0.2 seconds. This gives Nischay that premium, snappy feeling of appearing out of thin air exactly when summoned.

## Summary for Beginners
- Normal apps only receive keystrokes when they are active.
- Nischay uses `NSEvent.addGlobalMonitorForEvents` to act as a system-wide keylogger.
- For security, macOS forces the user to grant explicit **Accessibility permissions**.
- We listen specifically for hardware key code `42` (`\`), firing an elegant 0.2-second fade animation without interrupting the user's active workflow.
