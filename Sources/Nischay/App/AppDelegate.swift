import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    var systemDelegate: NischaySystemDelegate?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // No dock icon (backup to LSUIElement in Info.plist)
        NSApplication.shared.setActivationPolicy(.accessory)

        systemDelegate = NischaySystemDelegate()
        systemDelegate?.setup()
    }

    func applicationWillTerminate(_ notification: Notification) {
        systemDelegate?.cleanup()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        // Handle OAuth callback: nischay://auth/callback
        for url in urls {
            if url.scheme == "nischay" {
                AuthManager.shared.handleCallback(url: url)
            }
        }
    }
}
