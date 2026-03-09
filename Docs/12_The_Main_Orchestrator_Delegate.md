# 12. The Main Orchestrator (`NischaySystemDelegate`)

## Introduction for Beginners
macOS apps are vast. Nischay has a file to run the ScreenCaptureKit loop (`ScreenCaptureManager`), a file to handle the UI buttons (`ControlsViewController`), a file to talk to Supabase (`SupabaseManager`), and a file to capture the backslash global shortcut (`GlobalShortcutManager`).

If the shortcut manager detects `\`, it shouldn't go blindly ping the Supabase backend. It needs to tell the window manager to toggle the interface. If the UI's "Send" button is clicked, it needs to grab the OCR text from the Capture manager.

How do all these isolated files talk to each other without creating a tangled rat's nest of code?

# Meet the God Object

`NischaySystemDelegate` is the central orchestrator (often controversially called a "God Object" in software engineering).

It acts like the air traffic controller at a busy airport. No manager talks directly to another manager. They relay all messages through the System Delegate.

---

## 1. Composition
In the very top of `NischaySystemDelegate.swift`, you will see:

```swift
class NischaySystemDelegate: NSObject {
    let windowManager    = WindowManager()
    let shortcutManager  = GlobalShortcutManager()
    let captureManager   = ScreenCaptureManager()
    let ocrManager       = VisionOCRManager()
    let supabaseManager  = SupabaseManager()
    let openAIManager    = OpenAIManager()
```

The delegate physically owns the one and only copy of all the managers. Because it owns them, it can connect their pipes together.

---

## 2. Wiring the Pipes (The `setup()` function)

When the app finishes launching, `setup()` is called. 
This is the moment the air traffic controller issues the flight plans.

```swift
func setup() {
    // Pipeline 1: Keyboard -> UI Toggle
    shortcutManager.onToggle = { [weak self] in 
        self?.windowManager.toggleInterface() 
    }

    // Pipeline 2: ScreenCapture -> System Delegate
    captureManager.delegate = self
    captureManager.startCapture()

    // Pipeline 3: Setup UI Architecture
    windowManager.createAllWindows(delegate: self)
}
```

Now, when the `shortcutManager` hears the backslash key `\`, it fires `onToggle()`. The delegate intercepts this firing, and calmly tells the `windowManager` to execute the fade animation. 

---

## 3. The Core Execution Loop

The true power of the System Delegate is the `analyzeScreenContentForChat()` function. This is the heart of Nischay.

When the user types *"What does this error mean?"* and clicks the UI Send button, the `ChatInputView` shouts up to the System Delegate.

The System Delegate then executes a complex, 5-step master plan:

1. **Lock State:** It sets `isProcessingAI = true` so the user can't spam the Send button and crash the app.
2. **Fetch Context:** It grabs `self.lastScreenText` (which the OCR manager silently placed there half a second ago).
3. **Pre-flight Gate:** It commands the `supabaseManager` to hit the `/check-usage` endpoint to ensure the user isn't banned.
4. **Broadcast Updates:** It commands the AI to stream. As chunks of text arrive via Server-Sent Events, the delegate uses `NotificationCenter` to broadcast: *"Hey everyone (`ResponseViewController`), here is a new sentence!"*
5. **Persistence:** When the AI stream says `[DONE]`, the delegate commands the `supabaseManager` to permanently save the Chat History array to the PostgreSQL database.

If the UI tried to do all 5 of these steps by itself, it would be overwhelmed. Because we isolated all the heavy lifting into specific managers, the System Delegate just has to act as a brilliant conductor waving a baton.

## Summary for Beginners
- You should never have two isolated system managers directly talk to each other.
- Nischay uses `NischaySystemDelegate` as the central Air Traffic Controller.
- The `setup()` function physically wires the inputs of some managers to the outputs of other managers.
- When the user sends a message, the System Delegate marshals the OCR text, executes the Edge Function checks, routes the streaming text back to the UI, and issues database saves in one clean master pipeline.
