# Learning Module 6: Frida and API Interception

## The Reverse Engineering Dilemma
When tasked with cloning the functionality of a compiled application (`inputmethodd.dmg`), the most difficult asset to replicate is the backend API. 
If we want to build our own Supabase backend that the original app would perfectly understand, we need to know exactly what the original app usually sends to the server.

### Why Proxies Fail
Normally, developers use tools like Charles Proxy or Proxyman. These tools set up a "Man In The Middle" (MITM) attack on your own computer to intercept web traffic.
However, modern macOS apps use SSL/TLS encryption. If an app implements **SSL Pinning** (hardcoding the server's certificate into the app so it refuses to talk to proxies), Proxyman will only see encrypted, unreadable gibberish.

## Enter Frida: Dynamic Instrumentation
Frida is a toolkit designed for developers and reverse engineers. Instead of trying to intercept the network traffic *outside* the app, Frida injects code directly into the app's *active memory space* as it is running.

By injecting JavaScript into the app's RAM, we can hook the internal macOS functions (like `NSURLSession`) exactly at the millisecond the app finishes building the JSON payload, but *before* it encrypts the payload for the network.

## The Intercept Script
We wrote a script (`trace_api.js`) that uses Objective-C runtime bridging. 

```javascript
var sessionClass = ObjC.classes.NSURLSession;
var dataTaskMethod = sessionClass['- dataTaskWithRequest:completionHandler:'];
    
Interceptor.attach(dataTaskMethod.implementation, {
    onEnter: function(args) {
        var request = new ObjC.Object(args[2]);
        var url = request.URL().absoluteString();
    // ... extract string payload ...
```

### How It Works
1. `ObjC.classes.NSURLSession`: We asked Frida to locate the native Apple networking class inside the app's memory.
2. `Interceptor.attach`: We told Frida, "Every time the app attempts to send network data, pause the app."
3. `request.HTTPBody()`: Because the app is paused *before* encryption takes place, the HTTP body is sitting in plain text in the RAM. We simply read the RAM, printed it to our terminal, and then let the app continue.

This technique allowed us to completely bypass SSL encryption and extract the exact JSON schema required to perfectly mimic the original developer's Supabase backend edge functions.
