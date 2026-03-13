import SwiftUI

struct UnifiedDashboardView: View {
    @ObservedObject var systemDelegate: NischaySystemDelegate
    @State private var chatInput: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "person.fill.viewfinder")
                Text("Nischay")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                
                if systemDelegate.dashboardMode != .instructions {
                    HStack(spacing: 12) {
                        Button(action: {
                            systemDelegate.chatHistory = []
                            systemDelegate.dashboardMode = .instructions
                        }) {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(white: 0.3))
                        .cornerRadius(6)
                        
                        Button(action: {
                            let text = systemDelegate.chatHistory.map { $0.content }.joined(separator: "\n")
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(text, forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(white: 0.3))
                        .cornerRadius(6)
                    }
                    .font(.system(size: 12, weight: .semibold))
                }
            }
            
            // Content
            Group {
                switch systemDelegate.dashboardMode {
                case .instructions:
                    instructionsView
                case .results, .chat:
                    chatView
                }
            }
            
            // Footer (Chat Input)
            if systemDelegate.dashboardMode == .chat {
                chatInputField
            }
        }
        .padding(24)
        .frame(width: 500, height: 450) // Slightly taller to accommodate chat
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .cornerRadius(20)
        .preferredColorScheme(.dark)
        .animation(.spring(), value: systemDelegate.dashboardMode)
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Instructions")
                .font(.system(size: 16, weight: .bold))
            
            VStack(alignment: .leading, spacing: 30) {
                InstructionRow(icon: "command", text: "Use the Analyze button or press ⌘↩ to scan screen content.")
                InstructionRow(icon: "eye.slash", text: "Navigate with ⌘\\ to toggle/hide the interface.")
                InstructionRow(icon: "cursorarrow.motionlines", text: "Use ⌘+arrow keys or your mouse to move the window around.")
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var chatView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(systemDelegate.chatHistory.indices, id: \.self) { index in
                        let msg = systemDelegate.chatHistory[index]
                        ChatBubble(message: msg)
                            .id(index)
                    }
                    
                    if systemDelegate.isProcessingAI {
                        if !systemDelegate.currentResponseText.isEmpty {
                            ChatBubble(message: ChatMessage(role: "assistant", content: systemDelegate.currentResponseText, timestamp: Date()))
                                .id("streaming")
                        } else {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.6)
                                Text("Nischay is thinking...")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                            .id("loading")
                        }
                    }
                }
            }
            .onChange(of: systemDelegate.chatHistory.count) { _ in
                withAnimation { proxy.scrollTo(systemDelegate.chatHistory.count - 1) }
            }
            .onChange(of: systemDelegate.currentResponseText.count) { _ in
                proxy.scrollTo("streaming", anchor: .bottom)
            }
            .onChange(of: systemDelegate.isProcessingAI) { processing in
                if processing { withAnimation { proxy.scrollTo("loading") } }
            }
        }
        .transition(.opacity)
    }
    
    private var chatInputField: some View {
        HStack {
            TextField("Ask anything about the screen...", text: $chatInput, onCommit: submitChat)
                .textFieldStyle(.plain)
                .padding(10)
                .background(Color(white: 0.15))
                .cornerRadius(10)
            
            Button(action: submitChat) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func submitChat() {
        guard !chatInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let query = chatInput
        chatInput = ""
        systemDelegate.didSubmitQuery(query)
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary.opacity(0.8))
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if message.role == "user" { Spacer() }
            
            Text(message.content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.role == "user" ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(message.role == "user" ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            
            if message.role != "user" { Spacer() }
        }
    }
}
