# 17. Working with NSPasteboard (Copy and Paste)

## Introduction for Beginners
When the AI generates an excellent code snippet on the screen, the user will want to copy it to paste into Xcode. 

In `ResponseViewController.swift`, we have a UI button called "Copy". When clicked, how exactly does the text move from Nischay into the Mac's universal clipboard?

---

## 1. What is the Pasteboard?

In macOS, the "clipboard" is technically called the **Pasteboard** (`NSPasteboard`). 

Just like `NotificationCenter` or `UserDefaults`, there is a global, shared instance of the Pasteboard that every single application on your Mac talks to. If you copy an image in Safari, Safari writes it to `NSPasteboard.general`. When you press CMD+V in Photoshop, Photoshop reads `NSPasteboard.general`.

---

## 2. The Golden Rule of Copying

Before you can place a new string or image onto the Pasteboard, you **must** clear it first.

If you don't clear the Pasteboard, macOS assumes you are trying to append or mix different types of data, which frequently causes the copy operation to silently fail.

```swift
@objc private func copyResponse() {
    // 1. Wipe the universal clipboard clean.
    NSPasteboard.general.clearContents()
    
    // 2. Write the AI's response to the clipboard as plain text (.string).
    NSPasteboard.general.setString(currentResponseText, forType: .string)
}
```

### Pasteboard Data Types (`forType:`)
The Pasteboard is vastly more complex than just holding text. If you copy a folder in Finder, you aren't copying text—you are copying a `fileURL`. If you copy an image in your web browser, you are copying `tiff` or `png` data.

By specifying `forType: .string`, we are explicitly telling macOS: *"This data is pure text, treat it as a String."* If the user then opens TextEdit and presses CMD+V, TextEdit asks the Pasteboard for `.string` data, finds our AI response, and pastes it.

## Summary for Beginners
- The Mac clipboard is called `NSPasteboard.general`.
- Always call `clearContents()` before placing new items on the clipboard.
- Use `setString(_:forType:)` to inject data, specifying the correct macOS uniform type (like `.string` or `.tiff`).
