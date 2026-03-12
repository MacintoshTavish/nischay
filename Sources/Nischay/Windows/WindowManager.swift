import AppKit

/// Creates and owns all floating NSPanel windows.
/// Mirrors ChatInputPanel, ControlsPanel, and the main NSPanel from the class dump.
/// After creating all windows, calls StealthManager.applyStealth() so they are
/// excluded from screen-share pickers (setSharingType:.none).
@MainActor
class WindowManager: NSObject {

    private(set) var mainWindow: NSPanel?
    private(set) var controlsWindow: NSPanel?
    private(set) var chatInputWindow: NSPanel?
    private(set) var menuWindow: NSPanel?
    
    // Auth & Permission Modals
    private(set) var signInWindow: StealthPanel?
    private(set) var accessibilityWindow: StealthPanel?
    private(set) var successWindow: StealthPanel?
    
    // Operational Utility Windows
    private(set) var trialLimitsWindow: StealthPanel?
    private(set) var instructionsWindow: StealthPanel?
    private(set) var toolbarWindow: StealthPanel?




    weak var delegate: NischaySystemDelegate?

    override init() {}

    // MARK: - Create All

    func createAllWindows(delegate: NischaySystemDelegate) {
        self.delegate = delegate
        createMainWindow()
        createControlsWindow()
        createChatInputWindow()
        
        // Modals
        createSignInWindow()
        createAccessibilityWindow()
        createSuccessWindow()
        
        // Operational
        createTrialLimitsWindow()
        createInstructionsWindow()
        createToolbarWindow()
        createMenuWindow()




        // Apply stealth to all windows immediately after creation
        // (matches the call order in createInterface() -> applyStealth())
        StealthManager.applyStealth([
            mainWindow,
            controlsWindow,
            chatInputWindow,
            signInWindow,
            accessibilityWindow,
            successWindow,
            trialLimitsWindow,
            instructionsWindow,
            toolbarWindow,
            menuWindow
        ])
    }

    // MARK: - Window creation

    private func createMainWindow() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let f = screen.visibleFrame
        let w: CGFloat = 420, h: CGFloat = 580
        let panel = makePanel(rect: NSRect(x: f.maxX - w - 20, y: f.minY + 80, width: w, height: h))
        panel.title = "Nischay"
        panel.styleMask.insert([.titled, .closable, .resizable])
        panel.titlebarAppearsTransparent = true
        mainWindow = panel
    }

    private func createControlsWindow() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let f = screen.visibleFrame
        let w: CGFloat = 420, h: CGFloat = 72
        // Stacked directly above main window
        let y = f.minY + 80 + 580 + 6
        let panel = makePanel(rect: NSRect(x: f.maxX - w - 20, y: y, width: w, height: h))
        controlsWindow = panel
    }

    private func createChatInputWindow() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let f = screen.visibleFrame
        let w: CGFloat = 420, h: CGFloat = 56
        // Sits directly below main window
        let y = f.minY + 80 - h - 6
        let panel = makePanel(rect: NSRect(x: f.maxX - w - 20, y: y, width: w, height: h))
        chatInputWindow = panel
    }
    
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
    
    private func createInstructionsWindow() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let f = screen.visibleFrame
        let w: CGFloat = 500, h: CGFloat = 350
        
        let panel = StealthPanel(contentRect: NSRect(x: f.midX - w / 2, y: f.midY - h / 2 + 50, width: w, height: h), isMovable: true)
        instructionsWindow = panel
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
        guard let main = mainWindow else { return }
        if main.isVisible { hideMainInterface() } else { showMainInterface() }
    }

    func showMainInterface() {
        mainWindow?.orderFront(nil)
        controlsWindow?.orderFront(nil)
        chatInputWindow?.orderFront(nil)
    }

    func hideMainInterface() {
        mainWindow?.orderOut(nil)
        controlsWindow?.orderOut(nil)
        chatInputWindow?.orderOut(nil)
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
        instructionsWindow?.orderFront(nil)
        trialLimitsWindow?.orderFront(nil)
    }
    
    func hideOperationalUI() {
        toolbarWindow?.orderOut(nil)
        instructionsWindow?.orderOut(nil)
        trialLimitsWindow?.orderOut(nil)
    }
    
    func hideAllModals() {
        hideAuthFlow()
        hideAccessibilityModal()
        hideSuccessModal()
    }
    
    func toggleInstructions() {
        guard let instructions = instructionsWindow else { return }
        if instructions.isVisible {
            instructions.orderOut(nil)
        } else {
            instructions.orderFront(nil)
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
        [mainWindow, controlsWindow, chatInputWindow, instructionsWindow, toolbarWindow, trialLimitsWindow].forEach { $0?.alphaValue = alpha }
    }
}

// MARK: - NSWindowDelegate for Syncing
extension WindowManager: NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        guard let movedWindow = notification.object as? NSWindow else { return }
        
        // Sync Logic: If toolbar moves, instructions must follow in lockstep
        if movedWindow == toolbarWindow, let instructions = instructionsWindow {
            let offset: CGFloat = 20 // Gap between toolbar and instructions
            let newX = movedWindow.frame.midX - instructions.frame.width / 2
            let newY = movedWindow.frame.maxY + offset
            
            instructions.setFrameOrigin(NSPoint(x: newX, y: newY))
        }
    }
}
