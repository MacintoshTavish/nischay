# 13. Swift Concurrency (`async` / `await` / `Task`)

## Introduction for Beginners
When you ask Nischay a question, it needs to send that question to the OpenAI servers over the internet. That transfer could take 2 seconds.

If normal Swift code hits an instruction that takes 2 seconds, the entire application **freezes** for 2 seconds. You wouldn't be able to click buttons, the Mac's beachball of death would appear, and it would feel completely broken. 

To solve this, we use **Concurrency**.

---

## 1. What is asynchronous code?

Asynchronous (async) code is code that can be paused.

When `OpenAIManager.swift` needs to talk to the internet, it defines the function like this:
```swift
func callChatAPI(prompt: String) async throws -> String
```

The word `async` tells Swift: *"Warning! This function takes a long time. Do not freeze the app while waiting for it."*

---

## 2. Using `await`

When Nischay wants to actually call that function, it can't just write:
`let response = callChatAPI(prompt: "Hello")`

Because `callChatAPI` takes 2 seconds, Swift forces you to explicitly acknowledge the delay by writing the word `await`.

```swift
let response = await callChatAPI(prompt: "Hello")
print(response) // This prints 2 seconds later
```

When the computer hits the word `await`, it literally pauses that specific function, steps aside, and goes back to managing the rest of the app (like keeping the UI responsive and processing clicks). Once the internet data finally arrives 2 seconds later, the computer steps back in, resumes the function, and moves to the next line.

---

## 3. What is a `Task`?

If you try to write `await` inside a normal, synchronous function (like a button click handler), Xcode will give you a red error. You cannot pause a normal function.

To fix this, we wrap the `await` call inside a `Task { }` block.
A `Task` is like a cardboard box. You throw your slow, pausing async code inside the box, tape it shut, and chuck it onto a background conveyor belt.

```swift
@objc private func analyzeScreen() {
    // Normal button click function. Cannot pause.
    
    Task {
        // We are now on a background conveyor belt! We can pause.
        let response = try await openAIManager.callChatAPI(prompt: "Hello")
        
        // Update the UI when finished.
    }
}
```

The main app instantly finishes the button click function, while the `Task` floats in the background doing the heavy lifting.

## Summary for Beginners
- Hard work (like downloading data or heavy OCR) freezes the app if done normally.
- We mark slow functions with **`async`**.
- We call slow functions with **`await`**, which temporarily pauses that specific line of code without freezing the whole app.
- We start async work from a normal function by wrapping it inside a **`Task { }`**.
