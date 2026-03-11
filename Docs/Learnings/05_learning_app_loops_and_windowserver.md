# Learning Module 5: Runaway UI Loops and WindowServer Crashes

## The Architecture of Asynchronous Polling
In our stealth app, we needed to read the user's screen constantly (using `VisionOCRManager`) and check if they opened an exam question. To achieve "real-time" reading, the app initiates an asynchronous loop that requests a screenshot every few milliseconds.

This is fundamentally an infinite loop running on a background thread. 

## The Deadly Sin: Blocking the Loop
The golden rule of asynchronous polling is: **Never place a blocking UI request inside a rapid loop.**

### What Went Wrong
Inside our OCR loop, we placed the following logic:
```swift
1. Capture Screen Frame
2. If we don't have permission to capture -> Check `checkAndRequestPermission()`
3. In `checkAndRequestPermission`, use `Process()` to launch `/usr/bin/open` Settings app.
```

### The Chain Reaction
Because the user had not granted Screen Recording permission yet, the loop naturally failed at step 2. 
At Step 3, the code launched a UNIX shell process to forcefully open the macOS `System Settings` app so the user could check the box.

The problem? Opening an app takes macOS about 0.5 seconds. 
But the OCR loop runs every 0.05 seconds. 

Before the Settings app could even render on the monitor, the loop fired *again*, recognized it still lacked permission, and fired *another* request to open the Settings app.
It fired 60 times a second.

## The WindowServer Autopsy
macOS handles all visual drawing via the `WindowServer` subsystem. 

1. Our app generated hundreds of simultaneous Unix subprocesses screaming at LaunchServices to open the Settings app.
2. The WindowServer tried to oblige, jerking the `System Settings` UI window to the foreground.
3. Because macOS tries to remember exactly what tab you were looking at when an app crashes or closes, it writes this dat to the `cfprefsd` (Core Foundation Preferences Daemon) inside your `~/Library/Saved Application State/` folder.
4. The WindowServer was shifting the UI so fast that the `cfprefsd` daemon corrupted its own save file and hung completely. 

The result was a completely soft-locked System Settings app that was frozen on a blank white screen, completely unresponsive to user clicks, because the background agent was hijacking its Z-index focus hundreds of times a second.

## The Recovery (The UNIX Exorcism)
When a macOS daemon locks up like this, clicking the red "X" won't save you. You must drop into the terminal and forcefully execute the processes.

1. `killall -9 Nischay` (Kills the parent infinite loop process).
2. `killall -9 "System Settings"` (Forces the corrupted UI app to die).
3. `rm -rf ~/Library/Saved Application State/com.apple...` (Deletes the corrupted cache file so macOS forgets the app was broken).
4. `killall -9 cfprefsd` (Restarts the preferences daemon).

**The Lesson:** Never, ever trigger macOS UI actions (like opening deep links or presenting modals) from inside an un-throttled background polling loop. Always use boolean flags to ensure the request only fires exactly once. 
