import AppKit

/// A custom NSPanel that absolutely strips all native macOS window controls to achieve stealth.
class StealthPanel: NSPanel {
    init(contentRect: NSRect, isMovable: Bool = false) {
        super.init(
            contentRect: contentRect,
            // nonactivatingPanel prevents the NSPanel from making the app the frontmost "active" app, preserving stealth
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Aggressively remove all native titling and controls
        self.styleMask.remove(.titled)
        self.styleMask.remove(.closable)
        self.styleMask.remove(.miniaturizable)
        self.styleMask.remove(.resizable)
        
        // Ensure it floats above ordinary desktop windows
        self.level = .floating
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
        
        // Show on all spaces so the user does not lose it when swiping desktops
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // The frosted glass effect is managed by a SwiftUI VisualEffectView inside the content,
        // so the panel background itself must be perfectly clear.
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        
        // Total Stealth Implementation:
        // .none ensures the window is invisible to all screen capture/sharing APIs
        self.sharingType = .none
        // true ensures the window does not appear in system window lists or pickers
        self.isExcludedFromWindowsMenu = true
        
        self.isMovableByWindowBackground = isMovable
    }
    
    // We want the panel to be able to become key so SwiftUI buttons inside it can capture clicks
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}
