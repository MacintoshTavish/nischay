import AppKit

/// Monitors a global backslash keypress (\) to toggle the app UI.
/// Mirrors the "\ to toggle/hide the interface" shortcut string found in the binary.
@MainActor
class GlobalShortcutManager {

    private var globalMonitor: Any?
    var onToggle: (() -> Void)?

    func startMonitoring() {
        // keyCode 42 = backslash (\) on US ANSI layout
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 42 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                DispatchQueue.main.async { self?.onToggle?() }
            }
        }
    }

    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

}
