import SwiftUI

struct InstructionsOverlayView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Image(systemName: "person.fill.viewfinder")
                Text("Nischay")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.3))
                    .cornerRadius(6)
                    
                    Button(action: {}) {
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
            
            Text("Instructions")
                .font(.system(size: 16, weight: .bold))
            
            VStack(alignment: .leading, spacing: 40) {
                HStack(spacing: 12) {
                    Text("Use the Analyze button or press ⌘↩ to scan screen content.")
                }
                
                HStack(spacing: 12) {
                    Text("Navigate with ⌘\\ to toggle/hide the interface.")
                }
                
                HStack(spacing: 12) {
                    Text("Use ⌘+arrow keys or your mouse to move the window around.")
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.primary.opacity(0.8))
        }
        .padding(24)
        .frame(width: 500, height: 350)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .cornerRadius(20)
        .preferredColorScheme(.dark)
    }
}

