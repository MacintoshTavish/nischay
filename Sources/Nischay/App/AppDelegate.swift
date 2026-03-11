import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    var systemDelegate: NischaySystemDelegate?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Make app visible in Dock for debugging
        NSApplication.shared.setActivationPolicy(.regular)

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
