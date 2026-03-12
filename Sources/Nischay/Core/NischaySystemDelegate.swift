import AppKit
import Foundation
import SwiftUI

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

        // 6. Logic to show the correct windows on launch
        evaluateAppState()
        
        print("Nischay: setup complete")
    }
    
    // MARK: - App State Evaluation (Phase A & C)
    
    private var hasSkippedAccessibility = false


    @objc func evaluateAppState() {
        let isTrusted = AXIsProcessTrusted()
        let isAuthd = authManager.isAuthenticated
        
        // 1. Reset all modals and functional UI to a clean base state
        windowManager.hideAllModals()
        windowManager.hideMainInterface()
        windowManager.hideOperationalUI()
        
        // 2. AUTH LAYER: This is the absolute requirement for user identity.
        if !isAuthd {
            // User needs to login - Show Sign-In flow and STOP here.
            windowManager.showAuthFlow()
            return
        }
        
        // 3. OPERATIONAL LAYER: User IS authenticated! 
        // We show the main "Login Bar" (Toolbar) and load history immediately.
        windowManager.showOperationalUI()
        loadChatHistory()
        
        // 4. PERMISSION LAYER: This is a requirement for features (hotkeys).
        // If missing AND not skipped, we overlay the prompt.
        if !isTrusted && !hasSkippedAccessibility {
            windowManager.showAccessibilityModal()
        }
    }

    private func setupWindowContent() {
        // Main Core panels
        if let mainWindow = windowManager.mainWindow {
            let splitVC = MainSplitViewController()
            splitVC.systemDelegate = self
            mainWindow.contentViewController = splitVC
        }
        if let ctrlWin = windowManager.controlsWindow {
            let ctrlVC = ControlsViewController()
            ctrlVC.systemDelegate = self
            ctrlWin.contentViewController = ctrlVC
        }
        if let inputWin = windowManager.chatInputWindow {
            let inputView = ChatInputView()
            inputView.delegate = self
            inputWin.contentView = inputView
        }
        
        // Twin Initial Modals
        if let signInWin = windowManager.signInWindow {
            let signInView = SignInModalView(
                onSignIn: { [weak self] provider in
                    self?.authManager.signInWithSupabase(provider: provider)
                }
            )
            signInWin.contentView = NSHostingView(rootView: signInView)
        }
        
        if let accWin = windowManager.accessibilityWindow {
            let accView = AccessibilityModalView(
                onTryAgain: { [weak self] in
                    self?.hasSkippedAccessibility = false
                    self?.evaluateAppState()
                },
                onSkip: { [weak self] in
                    self?.hasSkippedAccessibility = true
                    self?.windowManager.hideAccessibilityModal()
                },
                onOpenSettings: { [weak self] in
                    // Use modern Sonoma deep-linking for Accessibility
                    if let url = URL(string: "x-apple.systempreferences:com.apple.PreferenceSync.SystemSettings.PrivacySecurity?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    } else if let fallback = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(fallback)
                    }
                    self?.windowManager.hideAccessibilityModal()
                }
            )
            accWin.contentView = NSHostingView(rootView: accView)
        }
        
        if let successWin = windowManager.successWindow {
            let successView = SuccessModalView(
                onGetStarted: { [weak self] in
                    self?.evaluateAppState()
                }
            )
            successWin.contentView = NSHostingView(rootView: successView)
        }
        
        if let trialWin = windowManager.trialLimitsWindow {
            let trialView = TrialLimitsModalView(
                onUpgrade: { [weak self] in
                    // Open upgrade URL
                    if let url = URL(string: "https://nohonorlock.com/upgrade") {
                        NSWorkspace.shared.open(url)
                    }
                },
                onContinue: { [weak self] in
                    self?.windowManager.trialLimitsWindow?.orderOut(nil)
                }
            )
            trialWin.contentView = NSHostingView(rootView: trialView)
        }
        
        if let instructionsWin = windowManager.instructionsWindow {
            let instructionsView = InstructionsOverlayView()
            instructionsWin.contentView = NSHostingView(rootView: instructionsView)
        }
        
        if let toolbarWin = windowManager.toolbarWindow {
            let toolbarView = PillToolbarView(
                onAnalyze: { [weak self] in
                    // Trigger analysis flow (mirrors streamAnalyzeText entry point)
                    Task {
                        guard let img = await self?.captureManager.captureScreenshot() else { return }
                        self?.didCaptureFrame(img)
                        // Note: analysis now happens on user demand or auto
                        // For now we just use the last extracted text
                        self?.analyzeScreenContentForChat(screenText: self?.lastScreenText ?? "", image: img, userQuery: "Analyze the screen and provide insights.")
                    }
                },
                onChat: { [weak self] in
                    self?.isChatModeEnabled.toggle()
                    if self?.isChatModeEnabled == true {
                        self?.windowManager.showMainInterface()
                    } else {
                        self?.windowManager.hideMainInterface()
                    }
                },
                onMenu: { [weak self] in
                    self?.windowManager.toggleMenu()
                }
            )
            toolbarWin.contentView = NSHostingView(rootView: toolbarView)
        }
        
        if let menuWin = windowManager.menuWindow {
            let menuView = MasterMenuView(
                onToggleInstructions: { [weak self] in
                    self?.windowManager.toggleInstructions()
                },
                onQuit: {
                    NSApplication.shared.terminate(nil)
                },
                onTransparencyChange: { [weak self] value in
                    self?.windowManager.setTransparency(value)
                }
            )
            menuWin.contentView = NSHostingView(rootView: menuView)
        }
    }

    // MARK: - Interface Toggle

    func toggleInterface() {
        guard let main = windowManager.mainWindow else { return }
        if main.isVisible { windowManager.hideMainInterface() } else { windowManager.showMainInterface() }
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
            // Convert NSImage → base64 String HERE on MainActor (Sendable-safe)
            let imageBase64: String? = image.flatMap { img in
                guard let tiff = img.tiffRepresentation,
                      let bmp  = NSBitmapImageRep(data: tiff),
                      let jpeg = bmp.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
                else { return nil }
                return jpeg.base64EncodedString()
            }
            let useVision = config.useVisionMode
            Task {
                do {
                    let response: String
                    if let base64 = imageBase64, useVision {
                        response = try await openAIManager.callVisionAPI(prompt: prompt, imageBase64: base64)
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
        evaluateAppState()
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
            DispatchQueue.main.async { self.lastScreenText = text }
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
