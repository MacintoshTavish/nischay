# 24. Understanding Closures (Blocks of Code)

## Introduction for Beginners
In traditional programming, you write a function, you call the function, and it runs immediately.

```swift
func sayHello() { print("Hello") }
sayHello() // Prints immediately
```

But what if you want to write a block of code, package it up like a wrapped present, hand it to the `GlobalShortcutManager`, and say: *"Do not run this code now. Please run it exactly 10 minutes from now when the user finally presses the \ key?"*

That wrapped package of code is called a **Closure**.

---

## 1. What does a Closure look like?

In Swift, you define a Closure using squiggly brackets `{ }` and the word `in`.

In Nischay's `GlobalShortcutManager.swift`:
```swift
class GlobalShortcutManager {
    // We declare a variable that holds a block of code!
    // The "() -> Void" math means: "This code takes zero inputs, and returns nothing."
    var onToggle: (() -> Void)?
}
```

---

## 2. Handing over the Package

In `NischaySystemDelegate.setup()`, we actually "write" the code and hand it over to the shortcut manager's `onToggle` variable.

```swift
shortcutManager.onToggle = { [weak self] in
    // This code does NOT execute right now!
    // It is physically stored in memory.
    self?.windowManager.toggleInterface()
}
```

When the app finishes launching, the `toggleInterface()` line does not run. Nischay's windows remain invisible.

---

## 3. Opening the Package

Finally, hours later, the user presses the `\` key.

The `GlobalShortcutManager`, who has been holding onto that package of code all day, finally decides to execute it:

```swift
if event.keyCode == 42 {
    // The key was pressed! Unwrap the closure and execute everything inside it!
    self.onToggle?()
}
```

Suddenly, `toggleInterface()` fires, and the Nischay UI appears on the screen.

### Wait, why did we use `?()`?
Because `onToggle` is an **Optional**! It's a box that *might* hold a closure, or it might hold `nil`.
By writing `self.onToggle?()`, Swift says: *"If there is a closure inside this box, execute it. If it's a null box, do nothing."* (See the *Optionals* guide for more details).

## Summary for Beginners
- A **Closure** is an entire block of code treated like a variable.
- You can pass a closure to another file, saving it for later execution.
- They are denoted by curly braces `{ }` and the `in` keyword.
- We use closures in Nischay to link the global keyboard listener to the UI fade animation without making the code messy.
