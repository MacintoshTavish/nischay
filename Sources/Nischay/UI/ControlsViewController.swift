import AppKit

/// Controls panel: screenshot, settings, mode toggles.
/// Mirrors ControlsViewController from the RE class dump.
class ControlsViewController: NSViewController {

    weak var systemDelegate: NischaySystemDelegate?

    private let analyzeButton  = ModernButton(title: "Analyze Screen")
    private let settingsButton = ModernButton(title: "⚙")
    private let shortModeCheck = NSButton(checkboxWithTitle: "Short", target: nil, action: nil)

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let stack = NSStackView(views: [analyzeButton, shortModeCheck, NSView(), settingsButton])
        stack.orientation = .horizontal
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        analyzeButton.target  = self
        analyzeButton.action  = #selector(analyzeScreen)
        settingsButton.target = self
        settingsButton.action = #selector(openSettings)
        shortModeCheck.target = self
        shortModeCheck.action = #selector(toggleShortMode)
        shortModeCheck.state  = ConfigManager.shared.isShortAnswerMode ? .on : .off
    }

    @objc private func analyzeScreen() {
        let text = systemDelegate?.lastScreenText ?? ""
        systemDelegate?.analyzeScreenContentForChat(screenText: text, image: nil, userQuery: "What's on my screen?")
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.showWindow(nil)
    }

    @objc private func toggleShortMode() {
        ConfigManager.shared.isShortAnswerMode = shortModeCheck.state == .on
    }
}

// MARK: - Minimal Settings Window (placeholder)

class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private init() {
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Nischay Settings"
        w.center()
        super.init(window: w)
        let label = NSTextField(wrappingLabelWithString:
            "Supabase and OpenAI settings will appear here.\nSet your API keys once you have them.")
        label.frame = NSRect(x: 20, y: 120, width: 360, height: 60)
        w.contentView?.addSubview(label)
    }
    required init?(coder: NSCoder) { fatalError() }
}
