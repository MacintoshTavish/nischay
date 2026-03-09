# 15. What is the Delegate Pattern?

## Introduction for Beginners
If you look at the Swift files in Nischay, you will see the word `delegate` everywhere. 

For example, `ChatInputView.swift` has this line:
```swift
weak var delegate: ChatInputDelegate?
```
What is this, and why do we need it?

---

## 1. The Problem

Let's imagine you are building the `ChatInputView`. This view has a text box and a "Send" button.

When the user clicks "Send", what should happen? The view needs to grab the text, send it to OpenAI, wait 2 seconds, and then draw a new blue chat bubble on the screen.

If you put the code to talk to OpenAI inside the `ChatInputView` file, your code becomes a disaster. The "Send Button Code" shouldn't know how to connect to Postgres databases or parse Server-Sent Events.

The `ChatInputView` should be dumb. It should only know how to draw a pretty button and a text box.

---

## 2. The Solution: The Delegate (The Manager)

A Delegate is simply a "Manager."

Instead of the `ChatInputView` doing the heavy lifting, it shouts: *"Hey Manager! The user just clicked Send and typed 'Hello'!"*

The `ChatInputView` doesn't care *how* the manager handles it. It just passes the message up the chain of command.

---

## 3. How to create a Pipeline (Protocols)

In order for the `ChatInputView` to shout to its manager, it needs to know what language the manager speaks. We define this language using a **Protocol**.

In `Models.swift`, we wrote:
```swift
protocol ChatInputDelegate: AnyObject {
    func didSubmitQuery(_ query: String)
}
```
A Protocol is a contract. It says: *"Anyone who wants to be my manager MUST have a function called `didSubmitQuery`."*

---

## 4. Wiring it up

In `NischaySystemDelegate.swift`, we tell the System Delegate to sign the contract using the word `extension`:

```swift
extension NischaySystemDelegate: ChatInputDelegate {
    func didSubmitQuery(_ query: String) {
        // The System Delegate receives the shout!
        // Now the delegate can do the complex OpenAI networking.
        print("The user typed: \(query)")
        analyzeScreenContentForChat(...)
    }
}
```

Finally, when the app launches and creates the windows, we physically connect the pipe:
```swift
// We tell the View: "I am your manager now."
chatInputView.delegate = self
```

### The Keyword: `weak`
You will always see `weak var delegate`. If the View holds tightly to the Manager, and the Manager holds tightly to the View, they create a "Retain Cycle"—a Chinese Finger Trap where neither object can ever be deleted from RAM, causing a memory leak. `weak` ensures the View doesn't trap the Manager in memory.

## Summary for Beginners
- UI Views (like buttons) should be "dumb" and only worry about drawing themselves.
- A **Delegate** (Manager) handles the complex logic (like networking).
- A **Protocol** is a contract that defines exactly what functions the View is allowed to shout to the Manager.
- The View shouts up the chain, and the Manager does the actual work. 
- Use **`weak`** to prevent memory leaks!
