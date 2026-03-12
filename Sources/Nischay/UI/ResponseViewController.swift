import AppKit

/// Displays AI responses, chat history, and voice output.
/// Mirrors ResponseViewController from the RE class dump:
///   responseTextView, chatScrollView, voiceTextView, displayMode,
///   signInButton, copyButton, clearButton
class ResponseViewController: NSViewController {

    weak var systemDelegate: NischaySystemDelegate?

    // MARK: - Display Mode
    enum DisplayMode { case response, chat, voice }
    var displayMode: DisplayMode = .chat { didSet { updateLayout() } }

    // MARK: - Views
    private var chatScrollView  = NSScrollView()
    private var chatContentView = NSStackView()    // holds ChatBubbles
    private var responseTextView = NSTextView()
    private var voiceTextView    = NSTextView()
    private var signInButton     = ModernButton(title: "Sign in")
    private var copyButton       = ModernButton(title: "Copy")
    private var clearButton      = ModernButton(title: "Clear")

    private var bubbleManager: ChatBubbleManager!
    private var currentResponseText = ""

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bubbleManager = ChatBubbleManager(stackView: chatContentView)
        setupLayout()
        observeNotifications()
    }

    // MARK: - Layout

    private func setupLayout() {
        // Chat scroll view fills the view
        chatScrollView.hasVerticalScroller = true
        chatScrollView.borderType = .noBorder
        chatScrollView.backgroundColor = .clear
        chatScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chatScrollView)

        chatContentView.orientation = .vertical
        chatContentView.alignment   = .leading
        chatContentView.spacing     = 8
        chatContentView.edgeInsets  = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        chatContentView.translatesAutoresizingMaskIntoConstraints = false
        chatScrollView.documentView = chatContentView

        // Bottom bar: sign-in / copy / clear
        let bar = NSStackView(views: [signInButton, NSView(), copyButton, clearButton])
        bar.orientation = .horizontal
        bar.spacing = 8
        bar.edgeInsets = NSEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)

        NSLayoutConstraint.activate([
            chatScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            chatScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatScrollView.bottomAnchor.constraint(equalTo: bar.topAnchor),

            chatContentView.widthAnchor.constraint(equalTo: chatScrollView.widthAnchor),

            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bar.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Button actions
        copyButton.target  = self; copyButton.action  = #selector(copyResponse)
        clearButton.target = self; clearButton.action = #selector(clearChat)
        signInButton.target = self; signInButton.action = #selector(signIn)

        updateAuthUI()
    }

    private func updateLayout() {
        chatScrollView.isHidden = displayMode == .voice
        voiceTextView.isHidden  = displayMode != .voice
    }

    // MARK: - Notifications

    private func observeNotifications() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(onAnalysisUpdate(_:)),
            name: .nischayAnalysisUpdate, object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(onAnalysisError(_:)),
            name: .nischayAnalysisError, object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(onChatHistoryLoaded(_:)),
            name: .nischayChatHistoryLoaded, object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(onAuthChanged),
            name: .nischayAuthStateChanged, object: nil)
    }

    @objc private func onAnalysisUpdate(_ n: Notification) {
        guard let chunk = n.object as? String else { return }
        currentResponseText += chunk
        bubbleManager.updateLastBubble(text: currentResponseText, role: "assistant")
        scrollToBottom()
    }

    @objc private func onAnalysisError(_ n: Notification) {
        guard let msg = n.object as? String else { return }
        bubbleManager.addBubble(text: "⚠️ \(msg)", role: "error")
        scrollToBottom()
    }

    @objc private func onChatHistoryLoaded(_ n: Notification) {
        guard let messages = n.object as? [ChatMessage] else { return }
        bubbleManager.clear()
        messages.forEach { bubbleManager.addBubble(text: $0.content, role: $0.role) }
        scrollToBottom()
    }

    @objc private func onAuthChanged() { updateAuthUI() }

    // MARK: - Actions

    @objc private func copyResponse() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentResponseText, forType: .string)
    }

    @objc private func clearChat() {
        bubbleManager.clear()
        currentResponseText = ""
    }

    @objc private func signIn() { systemDelegate?.authManager.signInWithSupabase() }

    private func updateAuthUI() {
        let authed = systemDelegate?.authManager.isAuthenticated ?? false
        signInButton.isHidden = authed
    }

    func appendUserMessage(_ text: String) {
        currentResponseText = ""
        bubbleManager.addBubble(text: text, role: "user")
        bubbleManager.addBubble(text: "…", role: "assistant") // placeholder
        scrollToBottom()
    }

    private func scrollToBottom() {
        guard let docView = chatScrollView.documentView else { return }
        let bottom = NSPoint(x: 0, y: docView.bounds.maxY)
        chatScrollView.contentView.scroll(to: bottom)
    }
}
