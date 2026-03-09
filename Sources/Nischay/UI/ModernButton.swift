import AppKit

/// Styled NSButton with hover tracking.
/// Mirrors ModernButton from the RE class dump: style, trackingArea, isHovered, isRecording.
class ModernButton: NSButton {

    private var trackingArea: NSTrackingArea?
    private(set) var isHovered = false

    convenience init(title: String) {
        self.init(frame: .zero)
        self.title = title
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        styleButton()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); styleButton() }

    private func styleButton() {
        bezelStyle = .rounded
        font = .systemFont(ofSize: 12, weight: .medium)
        wantsLayer = true
        layer?.cornerRadius = 6
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let t = trackingArea { removeTrackingArea(t) }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInActiveApp],
            owner: self, userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        animator().alphaValue = 0.75
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        animator().alphaValue = 1.0
    }
}
