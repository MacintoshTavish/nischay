import Foundation

let task = Process()
task.launchPath = "/usr/bin/osascript"
task.arguments = ["-e", "tell application \"System Settings\" to activate\ntell application \"System Settings\" to reveal pane id \"com.apple.settings.PrivacySecurity.extension\""]
task.launch()
