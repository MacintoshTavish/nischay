import SwiftUI

struct SuccessModalView: View {
    var onGetStarted: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill.viewfinder")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .foregroundColor(.blue)
            
            Text("Sign In Successful")
                .font(.system(size: 18, weight: .bold))
            
            Text("Welcome to Nischay! You can now access all features.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Get Started", action: onGetStarted)
                .buttonStyle(StealthButtonStyle(bg: Color.blue))
        }
        .padding(32)
        .frame(width: 320)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .cornerRadius(16)
        .preferredColorScheme(.dark)
    }
}
