# 23. Access Control (`public` vs `private`)

## Introduction for Beginners
When you look through Nischay's codebase, almost every variable has the word `private` in front of it.

```swift
class ResponseViewController: NSViewController {
    private let titleLabel = NSTextField()
    private let chatScrollView = NSScrollView()
}
```

Why did we type `private` on all fifty text fields? What happens if we just leave it blank?

---

## 1. What is Access Control?

Access control is how developers build firewalls inside their own code to prevent themselves (or their teammates) from making catastrophic mistakes.

We have four main tiers:
1. **`open` / `public`:** Anyone, anywhere in the computer, can read and change this variable.
2. **`internal` (Default):** Any file inside the Nischay app can read and change this variable. If you write `var name = "Bob"` without typing `private`, it defaults to `internal`.
3. **`fileprivate`:** Any code inside the exact same `.swift` file can read and change this variable.
4. **`private`:** Only the exact squiggly brackets `{ }` that created the variable can touch it.

---

## 2. Why we use `private` relentlessly

Imagine `ResponseViewController` did *not* make its `chatScrollView` private.

Tomorrow, you create a new file called `SettingsWindow.swift`. In that code, you make a typo, and you accidentally write:
`ResponseViewController.chatScrollView.removeFromSuperview()`

Because it wasn't private, Swift allows you to do it. The chat window suddenly vanishes from the screen, and you spend 3 days trying to figure out where the bug came from.

If you had marked the view as `private`, Xcode would throw a massive red error the moment you made that typo:
**"Error: 'chatScrollView' is inaccessible due to 'private' protection level."**

---

## 3. The `private(set)` Trick

Often, a manager needs to let the rest of the app read its variables, but *forbids* the rest of the app from changing them.

In `AuthManager.swift`, we track if the user is authenticated. We want the View Controllers to check if the user is logged in, but we absolutely do not want a random UI button to magically set `isAuthenticated = true` without pinging the Supabase server.

```swift
class AuthManager {
    // The rest of the app can READ it.
    // But only AuthManager is allowed to WRITE it.
    private(set) var isAuthenticated: Bool = false
}
```

`private(set)` is the elegant halfway point. It creates a bulletproof wall for writes, but a glass window for reads.

## Summary for Beginners
- Access control builds firewalls inside the app.
- Never leave variables blank (`internal`) unless you want the entire app touching them.
- Always default to **`private`** for UI elements (like text fields and buttons) so other files can't ruin your layouts.
- Use **`private(set)`** when you want to build a read-only variable for other files.
