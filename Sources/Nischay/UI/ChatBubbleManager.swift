import AppKit

/// Manages the stack of chat bubble views inside ResponseViewController.
/// Mirrors ChatBubbleManager from the RE class dump.
@MainActor
class ChatBubbleManager {

    private weak var stackView: NSStackView?
    private var lastBubble: ChatBubbleView?

    init(stackView: NSStackView) {
        self.stackView = stackView
    }

    func addBubble(text: String, role: String) {
        let bubble = ChatBubbleView(text: text, role: role)
        stackView?.addArrangedSubview(bubble)
        bubble.widthAnchor.constraint(lessThanOrEqualTo: stackView!.widthAnchor, multiplier: 0.88).isActive = true
        lastBubble = bubble
    }

    /// Update the last (streaming) bubble's text in place.
    func updateLastBubble(text: String, role: String) {
        if let last = lastBubble {
            last.updateText(text)
        } else {
            addBubble(text: text, role: role)
        }
    }

    func clear() {
        stackView?.arrangedSubviews.forEach { $0.removeFromSuperview() }
        lastBubble = nil
    }
}

// MARK: - ChatBubbleView

class ChatBubbleView: NSView {

    private let label = NSTextField(wrappingLabelWithString: "")
    private let role: String

    init(text: String, role: String) {
        self.role = role
        super.init(frame: .zero)
        wantsLayer = true
        setup(text: text)
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup(text: String) {
        layer?.cornerRadius = 12
        layer?.backgroundColor = backgroundColor(for: role).cgColor

        label.stringValue = text
        label.font = .systemFont(ofSize: 13)
        label.textColor = textColor(for: role)
        label.backgroundColor = .clear
        label.isEditable = false
        label.isBordered = false
        label.isSelectable = true
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        // Align user messages to the right, AI to the left
        if role == "user" {
            translatesAutoresizingMaskIntoConstraints = false
        }
    }

    func updateText(_ text: String) {
        label.stringValue = text
    }

    private func backgroundColor(for role: String) -> NSColor {
        switch role {
        case "user":      return NSColor.controlAccentColor.withAlphaComponent(0.15)
        case "assistant": return NSColor.windowBackgroundColor.withAlphaComponent(0.05)
        case "error":     return NSColor.systemRed.withAlphaComponent(0.12)
        default:          return NSColor.secondarySystemFill
        }
    }

    private func textColor(for role: String) -> NSColor {
        role == "error" ? .systemRed : .labelColor
    }
}
