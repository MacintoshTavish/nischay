import SwiftUI

struct SignInModalView: View {
    var onSignIn: (String) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Image(systemName: "person.fill.viewfinder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                
                Text("Nischay")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { onSignIn("github") }) {
                        HStack(spacing: 6) {
                            Image(systemName: "github.logo") // Fallback icon
                                .symbolVariant(.fill)
                            Text("GitHub")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button(action: { onSignIn("google") }) {
                        HStack(spacing: 6) {
                            Image(systemName: "g.circle")
                            Text("Google")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Welcome to Nischay")
                    .font(.system(size: 18, weight: .bold))
                
                Text("Please sign in to access all features.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .frame(width: 400)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .cornerRadius(16)
        .preferredColorScheme(.dark)
    }
}
