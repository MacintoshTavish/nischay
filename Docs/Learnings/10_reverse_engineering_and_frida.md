# Deep Dive: Reverse Engineering Proctoring Software (Frida & Payloads)

## The Objective
To build a compatible clone of a proctoring-resistant tool, we first had to understand how the original app communicated with its backend. This involved intercepting encrypted or hidden API traffic.

## 1. Dynamic Instrumentation with Frida
We used **Frida**, a world-class dynamic instrumentation toolkit, to hook into the running process and observe its behavior in real-time.

### The Trace Script:
We focused on hooking `NSURLSession` and `URLRequest` methods to capture payloads before they were encrypted or after they were decrypted in memory.

```javascript
// trace_api.js snippet
const URLSession = ObjC.classes.NSURLSession;
Interceptor.attach(URLSession['- dataTaskWithRequest:completionHandler:'].implementation, {
  onEnter(args) {
    const request = new ObjC.Object(args[2]);
    console.log("POST Body: " + request.HTTPBody().bytes().readUtf8String(request.HTTPBody().length()));
  }
});
```

## 2. Bypassing Code Signing
Internal tracing often fails on production macOS apps due to Hardened Runtime and Code Signing.

### The Mitigation:
We performed an **Ad-Hoc Re-signing** of the binary to remove restrictive entitlements that prevent debuggers and Frida from attaching.

```bash
codesign --force --deep --sign - inputmethodd_debug.app
```

## 3. API Payload Analysis
By observing the hooked traffic, we decoded the core business logic of the proctoring bypass.

### Key Discoveries:
- **Feature Gating**: The app calls a `/functions/v1/check-usage` endpoint before every AI request.
- **SSE Streaming**: The AI responses are streamed via Server-Sent Events (SSE) with a `[DONE]` terminator.
- **OCR Logic**: The app doesn't send the whole screenshot; it sends extracted text snippets to save bandwidth and improve latency.

## 4. Reconstructing the Schema
From the API traffic, we were able to "Reverse-Engineer" the backend database schema. We identified tables like `chat_messages`, `user_usage`, and `subscription_status` with their exact field names and types.

## Summary
Reverse engineering isn't just about reading code; it's about observing data in motion. Frida allowed us to bridge the gap between the compiled binary and the functional reality of the backend integration.
