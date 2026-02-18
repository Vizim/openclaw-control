# OpenClaw Control (macOS Menu Bar)

A minimalist macOS menu bar application to manage the OpenClaw Gateway daemon and its Ollama dependency.

## Features

- 🟢 Both OpenClaw and Ollama running
- 🟡 OpenClaw running, Ollama stopped
- 🔴 OpenClaw offline
- **Start / Kill / Restart** OpenClaw Gateway
- **Automatic Ollama lifecycle** — starts Ollama when OpenClaw starts, kills it when OpenClaw stops
- **Launch at Login** toggle — registers/unregisters a LaunchAgent for auto-start at login
- **Live Log viewer** — tails the OpenClaw log in a Terminal window
- Proper `.app` bundle — no Dock icon, no terminal window on launch (`LSUIElement`)

## Requirements

- macOS 12+
- [OpenClaw](https://github.com/openclaw/openclaw) installed via NVM at `~/.nvm/versions/node/v22.22.0/bin/openclaw`
- [Ollama](https://ollama.com) installed via Homebrew at `/opt/homebrew/bin/ollama`
- Swift compiler (`swiftc`) for building from source

## Build

```bash
bash build.sh
```

This compiles `main.swift` and packages a proper `.app` bundle (`OpenClawControl.app`).

## Install

```bash
cp -r OpenClawControl.app /Applications/
open /Applications/OpenClawControl.app
```

Then use the **Launch at Login** menu item to register it as a login item — no manual setup needed.

## How It Works

### Start OpenClaw
1. Checks if Ollama is already running — reuses the existing instance if so
2. Starts `ollama serve` in the background (logs to `/tmp/ollama.log`) if not running
3. Starts the OpenClaw gateway

### Kill OpenClaw
1. Gracefully stops the OpenClaw gateway via `openclaw gateway stop`
2. Force-kills `openclaw-gateway` if still alive after 2s
3. Force-kills the Ollama process (`/opt/homebrew/bin/ollama`)

### Status
| Icon | Meaning |
|------|---------|
| 🟢 | OpenClaw + Ollama both running |
| 🟡 | OpenClaw running, Ollama stopped |
| 🔴 | OpenClaw stopped |

## Screenshot

![OpenClaw Control in Action](app_action.png)
