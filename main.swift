import Cocoa
import Foundation

let ollamaPath = "/opt/homebrew/bin/ollama"

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatus()

        // Refresh status every 3 seconds
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.updateStatus()
        }
    }

    // MARK: - Status Checks

    func checkDaemonStatus() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/pgrep"
        task.arguments = ["-f", "openclaw-gateway"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return !data.isEmpty
    }

    func checkOllamaStatus() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/pgrep"
        task.arguments = ["-f", "/opt/homebrew/bin/ollama"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return !data.isEmpty
    }

    func updateStatus() {
        let clawRunning = checkDaemonStatus()
        let ollamaRunning = checkOllamaStatus()

        if let button = statusItem?.button {
            if clawRunning && ollamaRunning {
                button.title = "🟢"
            } else if clawRunning && !ollamaRunning {
                button.title = "🟡"
            } else {
                button.title = "🔴"
            }
        }
        constructMenu(isRunning: clawRunning, ollamaRunning: ollamaRunning)
    }

    // MARK: - Menu

    func constructMenu(isRunning: Bool, ollamaRunning: Bool) {
        let menu = NSMenu()

        // Status header
        let clawStatus = isRunning ? "OpenClaw: Online 🟢" : "OpenClaw: Offline 🔴"
        menu.addItem(NSMenuItem(title: clawStatus, action: nil, keyEquivalent: ""))

        let ollamaStatus = ollamaRunning ? "Ollama: Running 🟢" : "Ollama: Stopped 🔴"
        menu.addItem(NSMenuItem(title: ollamaStatus, action: nil, keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        if isRunning {
            menu.addItem(NSMenuItem(title: "Kill OpenClaw", action: #selector(stopClaw), keyEquivalent: "k"))
        } else {
            menu.addItem(NSMenuItem(title: "Start OpenClaw", action: #selector(startClaw), keyEquivalent: "s"))
        }

        menu.addItem(NSMenuItem(title: "Restart", action: #selector(restartClaw), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())

        // Launch at Login toggle
        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.state = isLoginItemEnabled() ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "View Live Logs", action: #selector(viewLogs), keyEquivalent: "l"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Toggle App", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    // MARK: - OpenClaw Actions

    @objc func startClaw() {
        startOllama()
        runClawCommand(arg: "start")
    }

    @objc func stopClaw() {
        runClawCommand(arg: "stop")
        stopOllama()
    }

    @objc func restartClaw() {
        stopOllama()
        runClawCommand(arg: "restart")
        startOllama()
    }

    func runClawCommand(arg: String) {
        let task = Process()
        task.launchPath = "/bin/bash"
        let cmd = "if [ -f ~/claw ]; then ~/claw \(arg); else $(echo $HOME)/.nvm/versions/node/v22.22.0/bin/openclaw gateway \(arg); fi"
        task.arguments = ["-c", cmd]
        task.launch()
        task.waitUntilExit()

        // If stopping, give the process time to die then force-kill if still alive
        if arg == "stop" || arg == "restart" {
            Thread.sleep(forTimeInterval: 2.0)
            if checkDaemonStatus() {
                let kill = Process()
                kill.launchPath = "/usr/bin/pkill"
                kill.arguments = ["-9", "-f", "openclaw-gateway"]
                kill.launch()
                kill.waitUntilExit()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        updateStatus()
    }

    // MARK: - Ollama Actions

    func startOllama() {
        // Reuse existing instance if already running
        if checkOllamaStatus() { return }

        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "\(ollamaPath) serve >> /tmp/ollama.log 2>&1 &"]
        task.launch()

        // Give Ollama a moment to initialise
        Thread.sleep(forTimeInterval: 2.0)
    }

    func stopOllama() {
        let task = Process()
        task.launchPath = "/usr/bin/pkill"
        task.arguments = ["-9", "-f", "/opt/homebrew/bin/ollama"]
        task.launch()
        task.waitUntilExit()
        Thread.sleep(forTimeInterval: 0.5)
    }

    // MARK: - Login Item (LaunchAgent)

    var launchAgentPlistPath: String {
        "\(NSHomeDirectory())/Library/LaunchAgents/com.openclaw.control.plist"
    }

    func isLoginItemEnabled() -> Bool {
        FileManager.default.fileExists(atPath: launchAgentPlistPath)
    }

    @objc func toggleLoginItem() {
        if isLoginItemEnabled() {
            // Unload and remove the LaunchAgent
            let unload = Process()
            unload.launchPath = "/bin/launchctl"
            unload.arguments = ["unload", launchAgentPlistPath]
            unload.launch()
            unload.waitUntilExit()
            try? FileManager.default.removeItem(atPath: launchAgentPlistPath)
        } else {
            // Get this binary's path
            let executablePath = ProcessInfo.processInfo.arguments[0]

            let plist = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.control</string>
    <key>ProgramArguments</key>
    <array>
        <string>\(executablePath)</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
"""
            do {
                try plist.write(toFile: launchAgentPlistPath, atomically: true, encoding: .utf8)
                let load = Process()
                load.launchPath = "/bin/launchctl"
                load.arguments = ["load", launchAgentPlistPath]
                load.launch()
                load.waitUntilExit()
            } catch {
                print("Failed to write LaunchAgent plist: \(error)")
            }
        }

        // Refresh menu to show updated checkmark
        updateStatus()
    }

    // MARK: - Logs

    @objc func viewLogs() {
        let script = "tell application \"Terminal\" to do script \"tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log\""
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        task.launch()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // No Dock icon, no terminal window
let delegate = AppDelegate()
app.delegate = delegate
app.run()
