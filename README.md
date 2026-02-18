# OpenClaw Control (macOS Menu Bar)

A minimalist macOS menu bar application to manage the OpenClaw Gateway daemon.

## Features
- 🟢/🔴 Status indicator
- Start/Kill/Restart OpenClaw Gateway
- Live Log viewer (Terminal popup)

## Requirements
- macOS
- OpenClaw installed (`openclaw` command in PATH)
- Swift installed (for compilation)

## Compilation
\`\`\`bash
swiftc main.swift -o OpenClawControl -framework Cocoa
\`\`\`

## Installation
Run the compiled \`OpenClawControl\` executable. Add it to your Login Items for persistence.
