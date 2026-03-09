import AppKit
import Foundation

/// The central orchestrator for Nischay – equivalent of NistaroSystemDelegate in the original.
/// Holds all sub-managers, wires them together, and implements the core feature flows:
///   - Screen capture → OCR → AI analysis (Supabase Edge or OpenAI)
///   - Chat history load/save
///   - Usage/subscription gating (calls checkFeatureUsage before analyze)
///   - Stealth toggle via backslash shortcut
///
/// Key ivars mirrored from the RE class dump (71 ivars on NistaroSystemDelegate):
///   window, isHidden, isChatModeEnabled, chatHistory, chatInputView, chatInputWindow,
///   isVoiceModeEnabled, isAutoAnswerEnabled, isShortAnswerMode, isResponseVisible,
///   controlsWindow, menuWindow, useEdgeFunctionAPI, openAIAPIKey, openAIModel,
///   lastScreenText, isProcessingAI, captureQueue, isCapturingScreenshot, etc.
@MainActor
class NischaySystemDelegate: NSObject {

    // MARK: - Sub-managers
    let windowManager    = WindowManager()
    let shortcutManager  = GlobalShortcutManager()
    let captureManager   = ScreenCaptureManager()
    let ocrManager       = VisionOCRManager()
    let supabaseManager  = SupabaseManager()
    let openAIManager    = OpenAIManager()
    let config           = ConfigManager.shared
    var authManager: AuthManager { AuthManager.shared }

    // MARK: - App State
    var isUserAuthenticated = false
    var isChatModeEnabled   = false
    var isVoiceModeEnabled  = false
    var isAutoAnswerEnabled = false
    var isResponseVisible   = false
    var chatHistory: [ChatMessage] = []
    var lastScreenText = ""
    var isProcessingAI = false

    // MARK: - Setup

    func setup() {
        // 1. Create all windows + apply stealth immediately
        windowManager.createAllWindows(delegate: self)

        // 2. Wire backslash shortcut → toggleInterface
        shortcutManager.onToggle = { [weak self] in self?.toggleInterface() }
        shortcutManager.startMonitoring()

        // 3. Request screen capture permission then start capture loop
        captureManager.delegate = self
        captureManager.checkAndRequestPermission { [weak self] granted in
            guard granted else { return }
            self?.captureManager.startCapture()
        }

        // 4. Wire UI into windows
        setupWindowContent()

        // 5. Observe auth changes
        NotificationCenter.default.addObserver(self,
            selector: #selector(authStateChanged),
            name: .nischayAuthStateChanged, object: nil)

        // 6. Show UI on launch
        windowManager.showAll()
        print("Nischay: setup complete")
    }

    private func setupWindowContent() {
        // Response + Controls in mainWindow via split view
        if let mainWindow = windowManager.mainWindow {
            let splitVC = MainSplitViewController()
            splitVC.systemDelegate = self
            mainWindow.contentViewController = splitVC
        }
        // Controls panel
        if let ctrlWin = windowManager.controlsWindow {
            let ctrlVC = ControlsViewController()
            ctrlVC.systemDelegate = self
            ctrlWin.contentViewController = ctrlVC
        }
        // Chat input panel
        if let inputWin = windowManager.chatInputWindow {
            let inputView = ChatInputView()
            inputView.delegate = self
            inputWin.contentView = inputView
        }
    }

    // MARK: - Interface Toggle

    func toggleInterface() {
        windowManager.toggleInterface()
    }

    // MARK: - Screen Analysis

    /// Called when user submits a query via ChatInputView.
    /// Chooses Supabase Edge Function or direct OpenAI based on config.
    /// Checks usage first (mirrors decompiled streamAnalyzeText_entry.c checkFeatureUsage call).
    func analyzeScreenContentForChat(screenText: String, image: NSImage?, userQuery: String) {
        guard !isProcessingAI else { return }
        isProcessingAI = true

        let useEdge  = config.useEdgeFunctionAPI && !config.supabaseURL.isEmpty
        let hasOAI   = !config.openAIAPIKey.isEmpty
        let prompt   = "User question: \(userQuery)\n\nScreen content:\n\(screenText)"

        if useEdge {
            Task {
                // Check usage before calling Edge Function (exactly as in decompiled binary)
                let usage = await supabaseManager.checkFeatureUsage(.screenAnalysis, amount: 1.0)
                guard usage.allowed else {
                    await MainActor.run {
                        self.isProcessingAI = false
                        self.broadcast(.nischayAnalysisError, "Usage limit reached. Consider upgrading.")
                    }
                    return
                }
                await supabaseManager.streamAnalyzeText(
                    content: prompt,
                    requestType: "chat",
                    useShortMode: config.isShortAnswerMode,
                    onUpdate: { [weak self] chunk in
                        DispatchQueue.main.async { self?.broadcast(.nischayAnalysisUpdate, chunk) }
                    },
                    onComplete: { [weak self] result in
                        guard let self else { return }
                        DispatchQueue.main.async { self.isProcessingAI = false }
                        if case .success(let text) = result {
                            self.saveChatMessage(ChatMessage(role: "assistant", content: text, timestamp: Date()))
                        } else if case .failure(let err) = result {
                            DispatchQueue.main.async { self.broadcast(.nischayAnalysisError, err.localizedDescription) }
                        }
                    }
                )
            }
        } else if hasOAI {
            Task {
                do {
                    let response: String
                    if let img = image, config.useVisionMode {
                        response = try await openAIManager.callVisionAPI(prompt: prompt, image: img)
                    } else {
                        response = try await openAIManager.callChatAPI(prompt: prompt)
                    }
                    await MainActor.run {
                        self.isProcessingAI = false
                        self.broadcast(.nischayAnalysisUpdate, response)
                        self.saveChatMessage(ChatMessage(role: "assistant", content: response, timestamp: Date()))
                    }
                } catch {
                    await MainActor.run {
                        self.isProcessingAI = false
                        self.broadcast(.nischayAnalysisError, error.localizedDescription)
                    }
                }
            }
        } else {
            isProcessingAI = false
            broadcast(.nischayAnalysisError, "No API configured. Add your OpenAI key or Supabase URL in Settings.")
        }
    }

    // MARK: - Chat History

    func loadChatHistory() {
        Task {
            let messages = authManager.isAuthenticated && !config.supabaseURL.isEmpty
                ? await supabaseManager.loadChatHistory()
                : []
            await MainActor.run {
                self.chatHistory = messages
                self.broadcast(.nischayChatHistoryLoaded, messages)
            }
        }
    }

    func saveChatMessage(_ message: ChatMessage) {
        chatHistory.append(message)
        if authManager.isAuthenticated && !config.supabaseURL.isEmpty {
            Task { await supabaseManager.saveChatMessage(message) }
        }
    }

    // MARK: - Auth

    @objc private func authStateChanged() {
        isUserAuthenticated = authManager.isAuthenticated
        if isUserAuthenticated { loadChatHistory() }
    }

    // MARK: - Cleanup

    func cleanup() {
        shortcutManager.stopMonitoring()
        captureManager.stopCapture()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Helpers

    private func broadcast(_ name: Notification.Name, _ object: Any?) {
        NotificationCenter.default.post(name: name, object: object)
    }
}

// MARK: - ScreenCaptureDelegate
extension NischaySystemDelegate: ScreenCaptureDelegate {
    func didCaptureFrame(_ image: NSImage) {
        ocrManager.extractText(from: image) { [weak self] text in
            guard let self, !text.isEmpty,
                  text.count >= self.config.minTextLength else { return }
            self.lastScreenText = text
        }
    }
}

// MARK: - ChatInputDelegate
extension NischaySystemDelegate: ChatInputDelegate {
    func didSubmitQuery(_ query: String) {
        let userMsg = ChatMessage(role: "user", content: query, timestamp: Date())
        saveChatMessage(userMsg)
        analyzeScreenContentForChat(screenText: lastScreenText, image: nil, userQuery: query)
    }
}
