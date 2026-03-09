import AppKit

/// Implements the stealth window behavior extracted from applyStealth() in inputmethodd.
///
/// Decompiled logic (applyStealth.c @ 0x100033fe4):
///   _objc_msgSend(window, "setSharingType:", 0)           → window.sharingType = .none
///   _objc_msgSend(window, "setExcludedFromWindowsMenu:", 1) → window.isExcludedFromWindowsMenu = true
///
/// Applied to: mainWindow, all childWindows, controlsWindow, chatInputWindow.
/// This is what makes the app's windows invisible in screen share pickers ("Invisibility mode").
class StealthManager {

    /// Apply stealth to all app windows – matches the exact logic from decompiled applyStealth.c
    static func applyStealth(
        mainWindow: NSWindow?,
        controlsWindow: NSWindow?,
        chatInputWindow: NSWindow?
    ) {
        let targets: [NSWindow?] = [mainWindow, controlsWindow, chatInputWindow]

        for window in targets {
            guard let w = window else { continue }
            applyToWindow(w)
            // Also apply to every child window (childWindows loop from decompiled C)
            w.childWindows?.forEach { applyToWindow($0) }
        }
    }

    private static func applyToWindow(_ window: NSWindow) {
        window.sharingType = .none              // setSharingType: 0
        window.isExcludedFromWindowsMenu = true // setExcludedFromWindowsMenu: 1
    }
}
