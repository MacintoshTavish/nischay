# 09. Server-Sent Events (Streaming) in Swift

## Introduction for Beginners
When you ask ChatGPT a question, the answer doesn't pause for 10 seconds and then magically appear all at once. Instead, it types out the answer word-by-word, like a human ghostwriting.

This provides an excellent user experience because the user isn't forced to stare at a blank screen waiting. This "typing effect" is built on a technology called **Server-Sent Events (SSE)**.

---

## 1. Normal HTTP vs Streaming HTTP

In a normal HTTP request (like loading a picture), Nischay asks the server, the server prepares the picture, and then sends a giant box containing the entire picture. The connection then cleanly closes.

In **Streaming HTTP**, Nischay asks the server, and the server says: *"I don't have the full answer yet, but keep the connection open and I'll toss words to you as I think of them."*

---

## 2. Setting up the Data Stream (`URLSessionDataDelegate`)

Normally, developers use `URLSession.shared.data(for: request)` which waits for the massive, final box of data.

To use streaming in `SupabaseManager`, we had to build a custom session delegate.

```swift
let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
let task = session.dataTask(with: request)
task.resume() // Start listening
```

Because `SupabaseManager` conforms to `URLSessionDataDelegate`, the moment the server tosses a single word, macOS wakes up the `didReceive data` method.

---

## 3. Parsing the SSE Format (`data: `)

The server doesn't just send raw words. It sends text formatted strictly to the SSE specification. It looks like this:

```text
data: {"choices":[{"delta":{"content":"Hello"}}]}

data: {"choices":[{"delta":{"content":" World"}}]}

data: [DONE]
```

Every new word arrives prefixed by `data: `, followed by a JSON dictionary, followed by a double line break (`\n\n`).

Our Swift code in `didReceive data` must act like a text parser:
1. It splits the incoming chunk by `\n`.
2. It looks for lines that start with `data: `.
3. It rips off the `data: ` prefix.
4. It checks if the remaining string says `[DONE]`. If it says DONE, the AI is finished, and we close the connection.
5. If it isn't DONE, we decode the JSON into a Swift struct.
6. We extract the exact substring `"Hello"`.

---

## 4. Bouncing to the Main Thread

Once `SupabaseManager` extracts the word `"Hello"`, it wants to update the UI so the user can see it instantly.

There is a golden rule in Apple development: **You can never touch the UI from a background thread.**

Network requests always happen on background threads so the app doesn't freeze. If we try to update `NSStackView` from a network thread, the app will instantly crash.

We must forcefully bounce the word over to the "Main Actor" (the exact pipeline that draws the screen).

```swift
// We are on a background network thread here.
DispatchQueue.main.async { 
    // We are now safely on the Main thread.
    self.broadcast(.nischayAnalysisUpdate, "Hello") 
}
```

The `ResponseViewController` catches this broadcast, hands it to `ChatBubbleManager`, and the text bubble physically updates on screen. A millisecond later, `" World"` arrives, and the cycle repeats.

## Summary for Beginners
- Real-time "typing" feels use **Server-Sent Events (SSE)**.
- Instead of waiting for the full response, the server keeps the connection open and fires chunks of data sequentially.
- The chunks always start with `data: ` and end with `data: [DONE]`.
- Nischay manually parses the chunks, extracts the JSON, and bounces the text back to the **Main Thread** (`DispatchQueue.main.async`) to safely update the visible Chat Bubble without crashing.
