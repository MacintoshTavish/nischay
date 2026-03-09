# 10. Programmatic UI and ChatBubbles

## Introduction for Beginners
If you search for "how to build a Mac app" on YouTube, 99% of tutorials will show you **Interface Builder** (dragging buttons onto a canvas in Xcode) or **SwiftUI** (writing `Text("Hello")`).

Nischay doesn't use either. It uses **Programmatic AppKit**. This means every single button, text field, and chat bubble is created strictly by writing math and code.

Why? 
1. The app needs highly exact, complex overlay math.
2. We want real-time streaming text (SSE) to update specific views instantly without the overhead of SwiftUI state reloads.

---

## 1. Building a View from Scratch

In `ChatInputView.swift`, you will see a class that inherits from `NSView`.

```swift
class ChatInputView: NSView {
    private let textField   = NSTextField()
    private let sendButton  = NSButton()
}
```

Normally, an `NSView` is a massive empty box.
Inside `setup()`, we literally spawn the text field into existence, style it, and bolt it to the view.

```swift
textField.placeholderString = "Ask anything about your screen…"
textField.bezelStyle = .roundedBezel
textField.translatesAutoresizingMaskIntoConstraints = false
addSubview(textField) // Very important!
```

If you forget `addSubview`, the text field exists in the computer's memory, but it will never appear on the screen.

---

## 2. Auto Layout Constraints

Since we aren't dragging and dropping, how does Nischay know *where* to put the text field? What if the user resizes the window? What if they have a tiny 13" MacBook vs a massive 32" Pro Display XDR?

Apple invented **Auto Layout Constraints** for this exact reason. Instead of saying "Put the text field exactly 500 pixels from the left side of the screen," we write equations.

```swift
NSLayoutConstraint.activate([
    textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
    textField.centerYAnchor.constraint(equalTo: centerYAnchor),
    textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -6)
])
```

- Equation 1: Lock the left edge of the text field 10 pixels away from the left edge of our view.
- Equation 2: Pin the text field exactly in the vertical center.
- Equation 3: Lock the right edge of the text field 6 pixels away from the left edge of the Send button!

Because of Constraint 3, if the Send Button physically moves, the text field stretches like a rubber band automatically. It requires precise thinking, but results in a UI that never breaks.

---

## 3. `ChatBubbleManager` and the `NSStackView`

When ChatGPT answers you, it doesn't just print raw text into a terminal. It draws a pretty gray box around the text.
If you reply, it draws a pretty blue box aligned to the right side of the screen.

To do this programmatically, Nischay uses an `NSStackView`.
Think of an `NSStackView` like a cardboard box. If you drop a book into it, the book falls to the bottom. If you drop a second book, it stacks perfectly on top of the first. If you drop a third, it stacks on the second.

Every time the user types a question and hits Send, `ChatBubbleManager` creates a brand new `ChatBubbleView` (which is just an `NSView` painted blue with some text inside).

```swift
let bubble = ChatBubbleView(text: "What does this code do?", role: "user")
stackView.addArrangedSubview(bubble) // Drops the bubble into the box
```

### The Streaming Text Trick
But wait—what happens when the AI is streaming its answer word-by-word via Server-Sent Events (SSE)?

If we dropped a new blue text box into the `NSStackView` for *every single word*, you would suddenly have 500 separate boxes stacked on top of each other containing one word each.

```swift
func updateLastBubble(text: String, role: String) {
    if let last = lastBubble {
        last.updateText(text) // Overwrite the text inside the existing box
    } else {
        addBubble(text: text, role: role) // Create the box once
    }
}
```

The `ChatBubbleManager` cleverly remembers the very last box (`lastBubble`) it dropped into the stack. When `"Hello"` arrives from the network, it creates the box. When `" World"` arrives a millisecond later, it doesn't create a new box. It grabs the `lastBubble`, opens it, and overwrites the text to say `"Hello World"`.

## Summary for Beginners
- Nischay's UI is built entirely in raw Swift code without Interface Builder.
- Things like buttons and text fields must be manually `addSubview`ed to the screen.
- **Auto Layout Constraints** use rubber-band equations to stretch UI automatically when the window changes size.
- **`NSStackView`** is used to stack chat bubbles vertically like books in a box.
- The `ChatBubbleManager` remembers the last created bubble so it can update it thousands of times a second without making the screen flicker.
