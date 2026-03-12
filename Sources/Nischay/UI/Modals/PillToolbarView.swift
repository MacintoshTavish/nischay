import SwiftUI

struct PillToolbarView: View {
    var onAnalyze: () -> Void
    var onChat: () -> Void
    var onMenu: () -> Void
    
    @State private var isAuto = false
    @State private var isLong = false
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onAnalyze) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.and.mic")
                    Text("Analyze")
                }
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Text("00:00")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
            
            Divider().frame(height: 20)
            
            Button(action: onChat) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                    Text("Chat")
                }
                .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Auto")
            }
            .font(.system(size: 12))
            .opacity(isAuto ? 1 : 0.5)
            .onTapGesture { isAuto.toggle() }
            
            HStack(spacing: 4) {
                Text("Short")
                    .opacity(isLong ? 0.5 : 1)
                
                Toggle("", isOn: $isLong)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .labelsHidden()
                    .scaleEffect(0.7)
                
                Text("Long")
                    .opacity(isLong ? 1 : 0.5)
            }
            .font(.system(size: 12))
            
            Button(action: onMenu) {
                HStack(spacing: 4) {
                    Image(systemName: "ellipsis.circle")
                    Text("Menu")
                }
                .font(.system(size: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .cornerRadius(20)
        .preferredColorScheme(.dark)
    }
}
