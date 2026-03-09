# 11. State Management and UserDefaults

## Introduction for Beginners
When you check the "Short" checkbox in Nischay to get snappy answers, then quit the app, and reopen it tomorrow: the "Short" checkbox should still be checked. 

If the user types in their Supabase URL, they shouldn't have to retype it every time they launch Nischay. 
How does the app remember things across reboots?

---

## 1. What is UserDefaults?

`UserDefaults` is Apple's built-in local database for extremely lightweight storage. It is not designed for heavy files (like storing 1,000 photos). It is designed purely for "True/False", Strings, and small Numbers.

Behind the scenes, `UserDefaults` is just a tiny `.plist` file buried deep in the hidden `~/Library/Preferences` folder on your Mac.

### The Singleton Pattern

If three different files in Nischay need to know whether the "Short" mode is checked, how do we make sure they all read from the same source of truth?

We use the **Singleton Pattern**.

```swift
class ConfigManager {
    static let shared = ConfigManager() // The one and only instance

    private let defaults = UserDefaults.standard
    // ...
}
```

By defining `static let shared = ConfigManager()`, there is exactly one `ConfigManager` in the entire computer's memory.
If `ResponseViewController` wants to check the configuration, it says:
`let config = ConfigManager.shared`
If `SupabaseManager` wants the url, it says:
`let config = ConfigManager.shared`

They are both talking to the exact same object.

---

## 2. Computed Properties (Getters and Setters)

In standard Swift, a variable is just a bucket that holds data.
```swift
var isShortMode = true
```
But if that variable is just a bucket in memory, the data evaporates when the app crashes or quits.

In `ConfigManager`, we use **Computed Properties**. A computed property acts like a function disguised as a variable. It intercepts the data right before it gets placed into the bucket.

```swift
var isShortAnswerMode: Bool {
    get {
        return defaults.bool(forKey: "isShortAnswerMode") // Read from hard drive
    }
    set {
        defaults.set(newValue, forKey: "isShortAnswerMode") // Write to hard drive
    }
}
```

**What this means:**
When the user clicks the checkbox in `ControlsViewController.swift`, they think they are just flipping a true/false switch:
```swift
ConfigManager.shared.isShortAnswerMode = true
```
But behind the scenes, the `set` block instantly executes and writes the word `true` directly to the Mac's hard drive inside the preferences `.plist` file.

The next day, when the app launches and the AI tries to decide if it should be concise, it reads `ConfigManager.shared.isShortAnswerMode`. The `get` block instantly executes, reads the Mac's hard drive, and returns `true`.

## 3. Why we don't commit API Keys

You will notice `ConfigManager.swift` handles `openAIAPIKey` and `supabaseAnonKey`. 

Because they use exact the same `UserDefaults` setup, they are stored securely on the user's hard drive. 
We *never* declare:
`let myKey = "sk-12345"`
anywhere in the source code.

This guarantees that when we push Nischay to GitHub, the source code is public, but the user's heavy API secrets remain completely isolated in their `~/Library/Preferences` folder, perfectly immune from hackers scraping GitHub.

## Summary for Beginners
- `UserDefaults` is Apple's built-in hard drive for small settings (like True/False checkboxes and API keys).
- The **Singleton Pattern** (`.shared`) ensures the entire app looks at the same source of truth.
- **Computed Properties** (`get` and `set`) allow us to intercept normal variable changes and silently save them to the disk.
- Never hardcode secret API keys directly into Swift files.
