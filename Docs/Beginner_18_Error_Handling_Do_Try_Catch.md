# 18. Error Handling (`do` / `try` / `catch`)

## Introduction for Beginners
When Nischay tries to start recording the screen with `ScreenCaptureKit`, what happens if the user hasn't granted Screen Recording permission? 

If we don't handle that possibility, the app will instantly crash.

Swift handles dangerous operations using a mechanism called **Error Handling**. It revolves around three keywords: `do`, `try`, and `catch`.

---

## 1. The `throws` Keyword

If you write a function that you *know* might fail (like downloading a file from the internet, or parsing a broken JSON file), you mark that function with the `throws` keyword.

```swift
func startScreenRecording() throws {
    // If we don't have permission, we literally "throw" a problem out of the function.
    if permission == false {
        throw CaptureError.permissionDenied
    }
}
```

By marking it `throws`, you are putting a giant warning label on the function: *"Warning! This function is dangerous and might explode!"*

---

## 2. Using `try`

Because of that warning label, Swift refuses to let you call the function normally.

```swift
startScreenRecording() // Error: Call can throw, but it is not marked with 'try'.
```

You must explicitly type the word `try` before calling it.
```swift
try startScreenRecording()
```
Typing `try` is your way of telling the compiler: *"I acknowledge this function is dangerous."*

---

## 3. Sandboxing the Explosion (`do` / `catch`)

But acknowledging the danger isn't enough. If the function *does* explode, where does the explosion go? If it hits the main app, the app crashes.

We must put the dangerous function inside a blast-proof box called a `do` block. We then attach a `catch` block to the side of the box to clean up the mess if an explosion occurs.

```swift
do {
    // 1. Put the dangerous code in the blast chamber.
    try startScreenRecording()
    
    // 2. If it succeeds, the code continues normally.
    print("Recording started!")
    
} catch {
    // 3. If an explosion happens (an error is thrown), Swift instantly teleports here.
    // The app SURVIVES! We can handle the error gracefully.
    print("Failed to start recording. Please check System Settings.")
}
```

### The Magic of the `catch` Block
Inside the `catch` block, Swift provides a hidden variable literally named `error`. You can inspect this variable to find out exactly *why* the function failed (e.g., whether it was a "Permission Denied" error or an "Out of Memory" error), and show a helpful red alert bubble to the user instead of exiting the app.

## Summary for Beginners
- Dangerous functions that might fail are marked with **`throws`**.
- To run a dangerous function, you must type **`try`**.
- To prevent the app from crashing when an error is thrown, wrap the dangerous `try` call inside a **`do`** block, and handle the failure inside the **`catch`** block.
