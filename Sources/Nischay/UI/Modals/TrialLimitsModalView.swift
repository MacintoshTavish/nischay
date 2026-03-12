import SwiftUI

struct TrialLimitsModalView: View {
    var onUpgrade: () -> Void
    var onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill.viewfinder")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
            
            Text("Trial Account Active")
                .font(.system(size: 16, weight: .bold))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("You're using a free trial with daily usage limits:")
                    .font(.system(size: 13))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• 5 screen analyses per day")
                    Text("• 5 chat interactions per day")
                    Text("• 5 minutes of transcription per day")
                }
                .font(.system(size: 13, weight: .semibold))
                
                Text("Upgrade to Pro for unlimited access!")
                    .font(.system(size: 13))
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 10) {
                Button("Upgrade to Pro", action: onUpgrade)
                    .buttonStyle(StealthButtonStyle(bg: Color.blue))
                
                Button("Continue with Trial", action: onContinue)
                    .buttonStyle(StealthButtonStyle(bg: Color(white: 0.3)))
            }
        }
        .padding(24)
        .frame(width: 300)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .cornerRadius(16)
        .preferredColorScheme(.dark)
    }
}
