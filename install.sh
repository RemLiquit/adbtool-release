#!/usr/bin/env bash
# Install published binaries. No source checkout, Rust, Node.js or GitHub login required.
set -euo pipefail
component="${1:-desktop}"
if [[ "$component" == '--help' ]]; then
  echo 'Usage: bash install.sh [desktop|mcp]'
  echo 'Optional: ADBTOOL_VERSION=vX.Y.Z, ADBTOOL_INSTALL_DIR=/path, ADBTOOL_BIN=/path'
  exit 0
fi
[[ "$component" == desktop || "$component" == mcp ]] || { echo 'Choose desktop or mcp.' >&2; exit 1; }
repo='RemLiquit/adbtool-releases'
host_os="$(uname -s)"
arch="$(uname -m)"
case "$host_os/$arch" in
  Darwin/arm64) label=macos-arm64; target=aarch64-apple-darwin ;;
  Darwin/x86_64)
    # Prefer the native build when this shell is running under Rosetta.
    if [[ "$(sysctl -n hw.optional.arm64 2>/dev/null || true)" == 1 ]]; then
      label=macos-arm64; target=aarch64-apple-darwin
    else label=macos-x64; target=x86_64-apple-darwin; fi ;;
  Linux/x86_64) label=linux-x64; target=x86_64-unknown-linux-gnu ;;
  *) echo "No published build for $host_os/$arch." >&2; exit 1 ;;
esac
command -v curl >/dev/null || { echo 'curl is required.' >&2; exit 1; }
version="${ADBTOOL_VERSION:-}"
if [[ -z "$version" ]]; then
  version="$(curl --fail --silent --show-error --location --retry 3 "https://api.github.com/repos/$repo/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')"
fi
[[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Could not resolve a stable release version.' >&2; exit 1; }
if [[ "$component" == mcp ]]; then asset="adbtool-mcp-$target.zip"
elif [[ "$host_os" == Darwin ]]; then asset="adbtool-$label.zip"
else asset="adbtool-$label.AppImage"; fi
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
base="https://github.com/$repo/releases/download/$version"
echo "Downloading $component $version for $label…"
curl --fail --silent --show-error --location --retry 3 "$base/$asset" -o "$work/$asset"
curl --fail --silent --show-error --location --retry 3 "$base/SHA256SUMS" -o "$work/SHA256SUMS"
expected="$(awk -v name="$asset" '$2 == name {print $1}' "$work/SHA256SUMS")"
[[ "$expected" =~ ^[a-f0-9]{64}$ ]] || { echo 'Missing or ambiguous checksum.' >&2; exit 1; }
if command -v sha256sum >/dev/null; then actual="$(sha256sum "$work/$asset")"
else actual="$(shasum -a 256 "$work/$asset")"; fi
[[ "${actual%% *}" == "$expected" ]] || { echo 'Checksum verification failed.' >&2; exit 1; }
bin="${ADBTOOL_BIN:-$HOME/.local/bin}"
if [[ "$component" == mcp ]]; then
  if [[ "$host_os" == Darwin ]]; then ditto -x -k "$work/$asset" "$work/unpacked"
  else unzip -q "$work/$asset" -d "$work/unpacked"; fi
  mkdir -p "$bin"
  # Rename replaces the file without modifying an already running process's inode.
  install -m 755 "$work/unpacked/adbtool-mcp" "$bin/adbtool-mcp.new"
  mv -f "$bin/adbtool-mcp.new" "$bin/adbtool-mcp"
  echo "Installed: $bin/adbtool-mcp"
  echo 'Set this absolute path as your MCP client command. Restart the MCP session after upgrading.'
elif [[ "$host_os" == Darwin ]]; then
  if pgrep -x adbtool >/dev/null; then echo 'Quit adbtool before installing so recordings can finish.' >&2; exit 1; fi
  ditto -x -k "$work/$asset" "$work/unpacked"
  codesign --verify --deep --strict "$work/unpacked/adbtool.app"
  destination="${ADBTOOL_INSTALL_DIR:-$HOME/Applications}"
  mkdir -p "$destination"
  backup="$destination/adbtool.app.previous-$(date +%Y%m%d%H%M%S)-$$"
  if [[ -e "$destination/adbtool.app" ]]; then mv "$destination/adbtool.app" "$backup"; fi
  if ! ditto "$work/unpacked/adbtool.app" "$destination/adbtool.app"; then
    echo "Installation failed; previous version, if present: $backup" >&2; exit 1
  fi
  echo "Installed: $destination/adbtool.app"
else
  destination="${ADBTOOL_INSTALL_DIR:-$HOME/.local/share/adbtool}"
  mkdir -p "$destination" "$bin" "$HOME/.local/share/applications"
  install -m 755 "$work/$asset" "$destination/adbtool.AppImage.new"
  mv -f "$destination/adbtool.AppImage.new" "$destination/adbtool.AppImage"
  ln -sfn "$destination/adbtool.AppImage" "$bin/adbtool"
  escaped="$(printf '%s' "$destination/adbtool.AppImage" | sed 's/\\/\\\\/g; s/"/\\"/g; s/`/\\`/g; s/\$/\\$/g')"
  cat > "$HOME/.local/share/applications/adbtool.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=adbtool
Comment=Android device tools
Exec="$escaped"
Terminal=false
Categories=Development;Utility;
EOF
  echo "Installed: $destination/adbtool.AppImage (launcher: $bin/adbtool)"
fi
echo 'Runtime dependencies: adb; scrcpy 3.x with its matching server for media and screen power.'
