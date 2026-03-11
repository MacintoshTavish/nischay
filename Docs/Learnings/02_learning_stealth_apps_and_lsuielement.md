# Learning Module 2: Stealth Apps and LSUIElement

## The Anatomy of a Normal Mac App
When you open a normal application on macOS, several things happen visually:
1. Its icon appears in the **Dock** at the bottom of the screen.
2. Its name and menus (File, Edit, View, Help) take over the global **Menu Bar** at the top of the screen.
3. If you press `Cmd + Option + Esc`, the app appears in the **Force Quit Applications** list.

For a stealth application, all three of these behaviors are unacceptable. 

## The Magic Key: `LSUIElement`
Apple provides a framework called **LaunchServices** (the "LS" in LSUIElement). LaunchServices manages how applications are opened and represented to the user.

Inside every Mac app is a file called `Info.plist` (Information Property List). This file defines the app's DNA. If you inject the following XML into the `Info.plist`:

```xml
<key>LSUIElement</key>
<true/>
```

You are explicitly telling LaunchServices: *"I am a background agent, not a foreground application."*

### The Effects of LSUIElement
Setting this key to `true` instantly achieves the following stealth properties:
1. **Dock Independence:** The app will *never* bounce or appear in the macOS Dock.
2. **Menu Bar Surrender:** The app will *never* claim the top Menu Bar. 
3. **Force Quit Evasion:** The app is hidden from the standard `Cmd + Option + Esc` menu, making it invisible to casual non-technical users looking to close it.

## The Drawbacks of UI Independence
When you sever an app from the Dock and Menu Bar, you lose the ability to easily provide UI to the user. 
- You cannot rely on a "Preferences" menu.
- You must build custom global keyboard shortcuts (like `Cmd + Shift + Space`) just to summon a floating window.
- If you need to offer a user a way to "Sign In" or "Log Out", you must build that into a floating panel, because there is no normal menu bar to place a standard `NSStatusItem`.

### The LaunchServices Security Penalty
Apple considers background `LSUIElement` processes to be inherently slightly suspicious, because malware loves to use them.

As a result, macOS aggressively sandboxes `LSUIElement` apps when they try to interact with the broader OS. For example, if a background agent tries to forcefully open the System Settings app, macOS will often sanitize or block the request to prevent the invisible app from harassing the user with unexpected windows.
