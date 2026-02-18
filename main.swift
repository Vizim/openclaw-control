import Cocoa
import Foundation

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
    
    func updateStatus() {
        let isRunning = checkDaemonStatus()
        if let button = statusItem?.button {
            // Green Circle for Running, Red Circle for Stopped
            button.title = isRunning ? "🟢" : "🔴"
        }
        constructMenu(isRunning: isRunning)
    }
    
    func checkDaemonStatus() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/pgrep"
        task.arguments = ["-f", "openclaw"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return !data.isEmpty
    }
    
    func constructMenu(isRunning: Bool) {
        let menu = NSMenu()
        
        let statusLabel = isRunning ? "OpenClaw: Online 🟢" : "OpenClaw: Offline 🔴"
        menu.addItem(NSMenuItem(title: statusLabel, action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        if isRunning {
            menu.addItem(NSMenuItem(title: "Kill OpenClaw", action: #selector(stopClaw), keyEquivalent: "k"))
        } else {
            menu.addItem(NSMenuItem(title: "Start OpenClaw", action: #selector(startClaw), keyEquivalent: "s"))
        }
        
        menu.addItem(NSMenuItem(title: "Restart", action: #selector(restartClaw), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        
        // Keep the Live Logs option as requested
        menu.addItem(NSMenuItem(title: "View Live Logs", action: #selector(viewLogs), keyEquivalent: "l"))
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Toggle App", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func startClaw() { runClawCommand(arg: "start") }
    @objc func stopClaw() { runClawCommand(arg: "stop") }
    @objc func restartClaw() { runClawCommand(arg: "restart") }
    
    @objc func viewLogs() {
        // Use osascript to open a new terminal window tailing the logs
        let script = "tell application \"Terminal\" to do script \"tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log\""
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        task.launch()
    }
    
    func runClawCommand(arg: String) {
        let task = Process()
        task.launchPath = "/bin/bash"
        let cmd = "if [ -f ~/claw ]; then ~/claw \(arg); else $(echo $HOME)/.nvm/versions/node/v22.22.0/bin/openclaw gateway \(arg); fi"
        task.arguments = ["-c", cmd]
        task.launch()
        task.waitUntilExit()
        updateStatus()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
