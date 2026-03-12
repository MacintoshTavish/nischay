import SwiftUI

struct StealthButtonStyle: ButtonStyle {
    var bg: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout)
            .fontWeight(.medium)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? bg.opacity(0.7) : bg)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
