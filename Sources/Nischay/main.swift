import AppKit

// Single-instance guard — exit if already running
let running = NSRunningApplication.runningApplications(withBundleIdentifier: "com.nischay.app")
if running.count > 1 {
    print("Nischay: already running — exiting duplicate.")
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
