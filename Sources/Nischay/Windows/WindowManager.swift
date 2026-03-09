import AppKit

/// Creates and owns all floating NSPanel windows.
/// Mirrors ChatInputPanel, ControlsPanel, and the main NSPanel from the class dump.
/// After creating all windows, calls StealthManager.applyStealth() so they are
/// excluded from screen-share pickers (setSharingType:.none).
class WindowManager {

    private(set) var mainWindow: NSPanel?
    private(set) var controlsWindow: NSPanel?
    private(set) var chatInputWindow: NSPanel?
    private(set) var menuWindow: NSPanel?

    weak var delegate: NischaySystemDelegate?

    init() {}

    // MARK: - Create All

    func createAllWindows(delegate: NischaySystemDelegate) {
        self.delegate = delegate
        createMainWindow()
        createControlsWindow()
        createChatInputWindow()

        // Apply stealth to all windows immediately after creation
        // (matches the call order in createInterface() -> applyStealth())
        StealthManager.applyStealth(
            mainWindow: mainWindow,
            controlsWindow: controlsWindow,
            chatInputWindow: chatInputWindow
        )
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

    private func makePanel(rect: NSRect) -> NSPanel {
        let panel = NSPanel(
            contentRect: rect,
            styleMask: [.nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.96)
        panel.isReleasedWhenClosed = false
        return panel
    }

    // MARK: - Toggle

    func toggleInterface() {
        guard let main = mainWindow else { return }
        if main.isVisible { hideAll() } else { showAll() }
    }

    func showAll() {
        mainWindow?.orderFront(nil)
        controlsWindow?.orderFront(nil)
        chatInputWindow?.orderFront(nil)
    }

    func hideAll() {
        mainWindow?.orderOut(nil)
        controlsWindow?.orderOut(nil)
        chatInputWindow?.orderOut(nil)
    }

    func setTransparency(_ alpha: CGFloat) {
        [mainWindow, controlsWindow, chatInputWindow].forEach { $0?.alphaValue = alpha }
    }
}
