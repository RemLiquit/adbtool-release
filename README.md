# adbtool

Android device management for **macOS, Windows and Linux**, with a desktop app and a standalone **MCP server for AI agents**.

[Download the latest release](https://github.com/RemLiquit/adbtool-release/releases/latest)

This repository distributes compiled applications and installation helpers. The application source is maintained privately.

**Quick install — macOS and Linux:**

```sh
curl -fsSL https://raw.githubusercontent.com/RemLiquit/adbtool-release/main/install.sh | bash
```

This installs the desktop and its bundled MCP server, selects your architecture and verifies the download. Open **Agent setup** in the app to copy your MCP configuration.

## Latest release: v0.1.3

Fixes wireless pairing and reconnection on macOS and recent Android: code pairing fills in the
phone's address by itself, the title bar shows the adb version actually running (with restart and
update actions), macOS Local Network permission is requested, and reconnect no longer misreports
network errors or leaves stale failures on screen. MAC addresses are learned even on hardened ROMs.

## What it does

- Connect over USB or WiFi, pair by QR or code, discover Android devices and save names.
- Recover wireless connections across changing addresses and ports, with optional automatic reconnection.
- Mirror the screen, record MP4 video, take screenshots, control physical screen power and inspect logcat.
- Diagnose adb, mDNS, VPN interfaces and local network reachability.
- Give agents 20 MCP tools for connection, inspection, Android shell, screenshots, UI hierarchy, media and diagnostics, plus an embedded LLM wiki.
- Check for signed app updates automatically and install them from the app's **Updates** button.
- Follow the system language in English or Spanish, or choose **System / English / Español** in the top bar. Changes apply immediately and persist across launches. Other system languages use English.

## Download

| System | Desktop asset | MCP asset |
| --- | --- | --- |
| macOS Apple Silicon | `adbtool-macos-arm64.zip` | `adbtool-mcp-aarch64-apple-darwin.zip` |
| macOS Intel | `adbtool-macos-x64.zip` | `adbtool-mcp-x86_64-apple-darwin.zip` |
| Windows x64 | `adbtool-windows-x64-setup.exe` | `adbtool-mcp-x86_64-pc-windows-msvc.zip` |
| Linux x64 | `adbtool-linux-x64.AppImage` or `adbtool-linux-x64.deb` | `adbtool-mcp-x86_64-unknown-linux-gnu.zip` |

macOS: extract the ZIP and move `adbtool.app` into Applications. Windows: run the installer. Linux: make the AppImage executable and run it, or install the Debian package with `sudo apt install ./adbtool-linux-x64.deb`. Linux desktop packages need WebKit2GTK 4.1; AppImage execution may also require your distribution's FUSE compatibility package. MCP excludes the desktop/webview dependencies.

The macOS build is ad-hoc signed, without Apple notarization; if macOS blocks the downloaded app, use **System Settings → Privacy & Security → Open Anyway** after attempting to open it. Windows installers do not have a publisher certificate. Update signatures are verified separately by the app.

## Install from a terminal

Install the desktop app **with MCP included** in one command on macOS or Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/RemLiquit/adbtool-release/main/install.sh | bash
# For the standalone agent server:
curl -fsSL https://raw.githubusercontent.com/RemLiquit/adbtool-release/main/install.sh | bash -s -- mcp
```

The script selects the exact OS/architecture asset and verifies its SHA-256 checksum. The macOS desktop always installs in `/Applications/adbtool.app`, using `sudo` if that directory needs administrator access. Reinstalling replaces the same application; a failed copy restores the previous version. Linux defaults to `~/.local/share/adbtool/adbtool.AppImage`. MCP defaults to `~/.local/bin/adbtool-mcp`. `ADBTOOL_VERSION=v0.1.0` pins a release; `ADBTOOL_INSTALL_DIR` overrides the Linux desktop directory and `ADBTOOL_BIN` the launcher/MCP directory. No compiler or source access is needed.

On Windows, in PowerShell:

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/RemLiquit/adbtool-release/main/install.ps1 -OutFile install-adbtool.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-adbtool.ps1
# For MCP:
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-adbtool.ps1 -Component mcp
```

Windows MCP installs under `%LOCALAPPDATA%\adbtool\bin`. `-Version v0.1.0` pins a version and `-InstallDir` overrides the MCP directory. The desktop command opens the normal installer.

## Requirements

Install **Android SDK Platform-Tools (`adb`)**. Install **scrcpy 3.x with its matching server** for mirroring, recording and physical screen-power changes. These tools are external dependencies, not included in the downloads. Enable Android developer options and authorize USB debugging, or use Android 11+ wireless debugging pairing. Automatic discovery requires a reachable local network with multicast support.

## Automatic updates

The desktop checks after startup and every six hours. **Updates** also checks manually; when a newer release exists, the button shows its version. **Install and restart** downloads it, verifies its signature, finalizes active recordings, stops mirrors and logcat, and restarts the app. Failed downloads leave active media running. Settings and adb pairing credentials are preserved.

Updates support macOS, Windows installers and Linux AppImage installations. Debian installations use new `.deb` packages. The standalone MCP executable is upgraded by rerunning the installer and restarting its client session; it does not replace itself during an agent operation.

## MCP setup

**The desktop installer includes the MCP server.** Open **Agent setup** in adbtool and copy the generated configuration into your agent client. The app and its bundled MCP update together. Stop MCP client sessions before installing an app update, then restart them afterward.

On macOS the server is inside `adbtool.app/Contents/MacOS/adbtool-mcp`; on Windows it is beside `adbtool.exe`; Debian installs it under `/usr/bin`. AppImage users get a stable `path/to/adbtool.AppImage --mcp` command, which starts the server without opening the desktop. The separate MCP downloads below are optional for machines that only need agent access.


Extract the MCP archive or use the installer, then add its absolute executable path to your client's MCP configuration:

```json
{
  "mcpServers": {
    "adbtool": {
      "command": "/absolute/path/to/adbtool-mcp",
      "args": []
    }
  }
}
```

On Windows, use a path such as `C:\\Users\\you\\AppData\\Local\\adbtool\\bin\\adbtool-mcp.exe`. The transport is local stdio. Start with `list_devices` and pass an explicit target to device operations. Read [MCP.md](MCP.md) for the full tool catalog, resources and examples.

## Verification and limitations

Releases are built and tested on native macOS ARM64/Intel, Linux x64 and Windows x64 runners. Tests use fake Android tools; phone/ROM-specific behavior still needs device testing. The desktop translates its own interface and messages; device names, raw tool output and Android logs remain verbatim. MCP protocol prose and documentation are English. Downloads include `SHA256SUMS`, signed updater assets and `latest.json`. The GitHub-generated source archives contain only this distribution repository.
