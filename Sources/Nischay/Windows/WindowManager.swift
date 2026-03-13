import AppKit

/// Creates and owns all floating NSPanel windows.
/// Mirrors ChatInputPanel, ControlsPanel, and the main NSPanel from the class dump.
/// After creating all windows, calls StealthManager.applyStealth() so they are
/// excluded from screen-share pickers (setSharingType:.none).
@MainActor
class WindowManager: NSObject {

    private(set) var dashboardWindow: StealthPanel?
    private(set) var menuWindow: NSPanel?
    
    // Auth & Permission Modals
    private(set) var signInWindow: StealthPanel?
    private(set) var accessibilityWindow: StealthPanel?
    private(set) var successWindow: StealthPanel?
    
    // Operational Utility Windows
    private(set) var trialLimitsWindow: StealthPanel?
    private(set) var toolbarWindow: StealthPanel?




    weak var delegate: NischaySystemDelegate?

    override init() {}

    // MARK: - Create All

    func createAllWindows(delegate: NischaySystemDelegate) {
        self.delegate = delegate
        createSignInWindow()
        createAccessibilityWindow()
        createSuccessWindow()
        
        // Operational
        createTrialLimitsWindow()
        createDashboardWindow()
        createToolbarWindow()
        createMenuWindow()




        // Apply stealth to all windows immediately after creation
        StealthManager.applyStealth([
            dashboardWindow,
            signInWindow,
            accessibilityWindow,
            successWindow,
            trialLimitsWindow,
            toolbarWindow,
            menuWindow
        ])
    }

    // MARK: - Window creation

    
    // MARK: - Specific Phase Modals
    
    private func createSignInWindow() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let f = screen.visibleFrame
        let w: CGFloat = 400, h: CGFloat = 200
        
        // Center screen
        let x = f.midX - w / 2
        let y = f.midY - h / 2 + 100 // Slightly elevated
        
        let panel = StealthPanel(contentRect: NSRect(x: x, y: y, width: w, height: h), isMovable: true)
        signInWindow = panel
    }
    
    private func createAccessibilityWindow() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let f = screen.visibleFrame
        let w: CGFloat = 480, h: CGFloat = 280
        
        // Center screen, slightly in front of SignIn
        let x = f.midX - w / 2
        let y = f.midY - h / 2 + 60
        
        let panel = StealthPanel(contentRect: NSRect(x: x, y: y, width: w, height: h), isMovable: true)
        
        // Ensure it naturally layers over the SignIn window
        panel.level = .floating
        
        accessibilityWindow = panel
    }
    
    private func createSuccessWindow() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let f = screen.visibleFrame
        let w: CGFloat = 320, h: CGFloat = 280
        
        // Center screen
        let x = f.midX - w / 2
        let y = f.midY - h / 2 + 80
        
        let panel = StealthPanel(contentRect: NSRect(x: x, y: y, width: w, height: h), isMovable: true)
        panel.level = .floating
        successWindow = panel
    }
    
    // MARK: - Operational Windows
    
    private func createTrialLimitsWindow() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let f = screen.visibleFrame
        let w: CGFloat = 300, h: CGFloat = 360
        
        let panel = StealthPanel(contentRect: NSRect(x: f.midX - w / 2, y: f.midY - h / 2, width: w, height: h), isMovable: true)
        trialLimitsWindow = panel
    }
    
    private func createDashboardWindow() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let f = screen.visibleFrame
        let w: CGFloat = 500, h: CGFloat = 450 // Dashboard size
        
        let panel = StealthPanel(contentRect: NSRect(x: f.midX - w / 2, y: f.midY - h / 2 + 100, width: w, height: h), isMovable: true)
        dashboardWindow = panel
    }
    
    private func createToolbarWindow() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let f = screen.visibleFrame
        let w: CGFloat = 600, h: CGFloat = 50 // Wider pill
        
        // Sits below instructions
        let panel = StealthPanel(contentRect: NSRect(x: f.midX - w / 2, y: f.midY - h / 2 - 200, width: w, height: h), isMovable: true)
        
        // The toolbar is the "master" for movement syncing
        panel.delegate = self
        
        toolbarWindow = panel
    }
    
    func createMenuWindow() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let f = screen.visibleFrame
        let w: CGFloat = 200, h: CGFloat = 220
        
        // Appear slightly above the toolbar usually
        let panel = StealthPanel(contentRect: NSRect(x: f.midX + 150, y: f.midY - 100, width: w, height: h), isMovable: true)
        menuWindow = panel
    }

    private func makePanel(rect: NSRect) -> NSPanel {
        let panel = NSPanel(
            contentRect: rect,
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        // Allow the panel to appear on all spaces but still accept clicks
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = NSColor(calibratedWhite: 0.12, alpha: 0.97)
        panel.isReleasedWhenClosed = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        // becomeKey so buttons/text can be clicked
        panel.becomesKeyOnlyIfNeeded = false
        return panel
    }

    // MARK: - Toggle

    func toggleInterface() {
        guard let dashboard = dashboardWindow else { return }
        if dashboard.isVisible { hideOperationalUI() } else { showOperationalUI() }
    }

    func showMainInterface() {
        dashboardWindow?.orderFront(nil)
    }

    func hideMainInterface() {
        dashboardWindow?.orderOut(nil)
    }
    
    // Auth Flow Triggers
    func showAuthFlow() {
        signInWindow?.makeKeyAndOrderFront(nil)
    }
    
    func hideAuthFlow() {
        signInWindow?.orderOut(nil)
    }
    
    func showAccessibilityModal() {
        accessibilityWindow?.makeKeyAndOrderFront(nil)
    }
    
    func hideAccessibilityModal() {
        accessibilityWindow?.orderOut(nil)
    }
    
    func showOperationalUI() {
        toolbarWindow?.makeKeyAndOrderFront(nil)
        dashboardWindow?.orderFront(nil)
        trialLimitsWindow?.orderFront(nil)
    }
    
    func hideOperationalUI() {
        toolbarWindow?.orderOut(nil)
        dashboardWindow?.orderOut(nil)
        trialLimitsWindow?.orderOut(nil)
    }
    
    func hideAllModals() {
        hideAuthFlow()
        hideAccessibilityModal()
        hideSuccessModal()
    }
    
    func toggleInstructions() {
        guard let dashboard = dashboardWindow else { return }
        if dashboard.isVisible {
            dashboard.orderOut(nil)
        } else {
            dashboard.orderFront(nil)
        }
    }
    
    func showSuccessModal() {
        successWindow?.makeKeyAndOrderFront(nil)
    }
    
    func hideSuccessModal() {
        successWindow?.orderOut(nil)
    }
    
    func showMenu() {

        menuWindow?.makeKeyAndOrderFront(nil)
    }
    
    func hideMenu() {
        menuWindow?.orderOut(nil)
    }
    
    func toggleMenu() {
        guard let menu = menuWindow else { return }
        if menu.isVisible { hideMenu() } else { showMenu() }
    }

    func setTransparency(_ alpha: CGFloat) {
        [dashboardWindow, toolbarWindow, trialLimitsWindow].forEach { $0?.alphaValue = alpha }
    }
}

// MARK: - NSWindowDelegate for Syncing
extension WindowManager: NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        guard let movedWindow = notification.object as? NSWindow else { return }
        
        // Sync Logic: If toolbar moves, dashboard must follow in lockstep
        if movedWindow == toolbarWindow, let dashboard = dashboardWindow {
            let offset: CGFloat = 20 // Gap between toolbar and dashboard
            let newX = movedWindow.frame.midX - dashboard.frame.width / 2
            let newY = movedWindow.frame.maxY + offset
            
            dashboard.setFrameOrigin(NSPoint(x: newX, y: newY))
        }
    }
}
