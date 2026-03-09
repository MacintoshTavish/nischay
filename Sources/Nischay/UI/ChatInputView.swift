import AppKit

/// The chat input bar at the bottom of the app.
/// Mirrors ChatInputView from the RE class dump:
///   inputContainer, textField (FocusableTextField), sendButton
class ChatInputView: NSView {

    weak var delegate: ChatInputDelegate?

    private let textField   = NSTextField()
    private let sendButton  = NSButton()
    private let container   = NSView()

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // Text field
        textField.placeholderString = "Ask anything about your screen…"
        textField.bezelStyle = .roundedBezel
        textField.font = .systemFont(ofSize: 13)
        textField.focusRingType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.target = self
        textField.action = #selector(submitOnReturn)

        // Send button
        sendButton.title = "↑"
        sendButton.bezelStyle = .rounded
        sendButton.font = .boldSystemFont(ofSize: 15)
        sendButton.target = self
        sendButton.action = #selector(sendTapped)
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(textField)
        addSubview(sendButton)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -6),

            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            sendButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 34),
            sendButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    @objc private func sendTapped()    { submit() }
    @objc private func submitOnReturn() { submit() }

    private func submit() {
        let query = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        delegate?.didSubmitQuery(query)
        textField.stringValue = ""
    }
}
