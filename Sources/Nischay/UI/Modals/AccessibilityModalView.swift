import SwiftUI

struct AccessibilityModalView: View {
    var onTryAgain: () -> Void
    var onSkip: () -> Void
    var onOpenSettings: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "person.fill.viewfinder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            }
            
            Text("Accessibility Permission Required")
                .font(.system(size: 16, weight: .bold))
            
            Text("Nischay needs accessibility permissions to enable global hotkeys that work even when the app is not focused.")
                .font(.system(size: 13))
                .foregroundColor(.primary.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Global Hotkeys:")
                    .font(.system(size: 13, weight: .bold))
                Text("• ⌘⇧\\ - Toggle Nischay window")
                Text("• ⌘↩ - Analyze screen content")
                Text("• ⌘+Arrow Keys - Move window")
            }
            .font(.system(size: 13))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Steps to enable:")
                    .font(.system(size: 13, weight: .bold))
                Text("1. Click 'Open System Settings' below")
                Text("2. Go to Privacy & Security -> Accessibility")
                Text("3. Find 'Nischay' in the list and toggle it ON")
                Text("4. You may need to restart Nischay for changes to take effect")
            }
            .font(.system(size: 13))
            
            Text("Without this permission, hotkeys will only work when Nischay is focused.")
                .font(.system(size: 13))
                .foregroundColor(.primary.opacity(0.8))
            
            HStack(spacing: 12) {
                Button("Try Again", action: onTryAgain)
                    .buttonStyle(StealthButtonStyle(bg: Color(white: 0.3)))
                
                Button("Skip for Now", action: onSkip)
                    .buttonStyle(StealthButtonStyle(bg: Color(white: 0.3)))
                
                Button("Open System Settings", action: onOpenSettings)
                    .buttonStyle(StealthButtonStyle(bg: Color.blue))
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(width: 480)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .cornerRadius(16)
        .preferredColorScheme(.dark)
    }
}
