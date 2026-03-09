# 02. Project Configuration and Permissions

## Introduction for Beginners
Before a macOS application is allowed to read your screen or listen to your keyboard, the operating system (macOS) demands that the app explicitly asks for permission. Furthermore, macOS apps operate inside security constraints called the "Sandbox."

This document explains what `Info.plist`, `Entitlements`, and the `Package.swift` files are, and why they look the way they do in Nischay.

---

## 1. The Swift Package Manager (`Package.swift`)

When building complex software, developers write files that tell the compiler how to stitch everything together. Nischay uses the **Swift Package Manager (SPM)**.

The `Package.swift` file is the recipe for Nischay.
- It declares the app name (`Nischay`).
- It declares the minimum operating system required (`macOS 14`).
- It tells the compiler to bundle everything inside the `Sources/Nischay` folder into an `.executableTarget`.

### Why not an `.xcodeproj` file?
Normally, macOS apps use an Xcode Project file. By using SPM, Nischay's source code is completely portable and can be compiled purely from the command line using `swift build`, or seamlessly opened in Xcode without dealing with messy `.pbxproj` merge conflicts on GitHub.

---

## 2. Information Property List (`Info.plist`)

Every Apple application requires an `Info.plist` (Property List) file. This is an XML file that macOS reads *before* it even executes your code to know what your app is capable of.

### Key Entries in Nischay's Info.plist:

1. **`LSUIElement = 1`**
   - **What it does:** Similar to `setActivationPolicy(.accessory)` in code, this key tells macOS that Nischay is a background agent. It prevents the app from bouncing in the Dock during launch.

2. **`NSScreenCaptureUsageDescription`**
   - **What it does:** Whenever an app tries to record the screen, macOS shows a scary alert to the user. This key contains the text that will be shown in that alert (e.g., *"Nischay needs to read your screen to provide AI context."*). If you don't include this key, macOS will instantly crash your app the moment you try to capture the screen.

3. **`CFBundleURLTypes`**
   - **What it does:** This registers the `nischay://` URL scheme with macOS. When the user logs in via the browser and the browser redirects to `nischay://auth-callback`, macOS knows to look for our app and wake it up, passing it the secret authentication token.

---

## 3. Entitlements (`Nischay.entitlements`)

While the `Info.plist` focuses on user-facing metadata and descriptions, **Entitlements** are hardcoded security privileges cryptographically signed into the app binary.

### Key Entries in Nischay's Entitlements:

1. **`com.apple.security.app-sandbox` is Missing (or False)**
   - **Concept: The App Sandbox.** Apple normally forces apps into a "Sandbox" where they cannot read files outside their own folder, or listen to system-wide events.
   - **Why we disable it:** Nischay needs to monitor the user's keyboard globally to wait for the backslash (`\`) key, regardless of what app is currently active. Sandboxed apps are explicitly banned from global keyboard monitoring. Therefore, Nischay must run un-sandboxed.

2. **`com.apple.security.cs.allow-unsigned-executable-memory = YES`**
   - **What it does:** Allows the app to generate code in memory at runtime. This is required by Apple's newer Swift Concurrency (`async/await`) mechanics, as well as several internal AppKit frameworks.

3. **`com.apple.security.screen-capture = YES`**
   - **What it does:** Grants the app the underlying technical permission to communicate with the macOS WindowServer to request pixel data from the screen.

## Summary for Beginners
- `Package.swift` is the build recipe.
- `Info.plist` tells macOS how the app behaves and provides descriptions for permission alerts.
- `.entitlements` are cryptographic security keys. We disabled the Sandbox to allow global keyboard monitoring, and enabled screen capture access.
