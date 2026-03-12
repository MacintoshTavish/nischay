import SwiftUI

struct MasterMenuView: View {
    @State var transparency: Double = 1.0
    var onToggleInstructions: () -> Void
    var onQuit: () -> Void
    var onTransparencyChange: (Double) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: {}) {
                HStack {
                    Image(systemName: "info.circle")
                    Text("About")
                }
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "circle.lefthalf.filled")
                    Text("Transparency \(Int(transparency * 100))%")
                }
                Slider(value: $transparency, in: 0.1...1.0)
                    .onChange(of: transparency) { newValue in
                        onTransparencyChange(newValue)
                    }
            }
            
            Button(action: onToggleInstructions) {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Instructions")
                }
            }
            .buttonStyle(.plain)
            
            Divider()
            
            Button(action: onQuit) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit")
                }
                .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 200)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .cornerRadius(12)
        .preferredColorScheme(.dark)
    }
}
