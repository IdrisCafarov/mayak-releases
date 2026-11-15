#!/usr/bin/env bash
# Mayak installer for macOS and Linux.
# Downloads the latest release from GitHub over HTTPS, verifies its SHA-256 checksum, installs it.
set -euo pipefail
REPO="IdrisCafarov/mayak-releases"
API="https://api.github.com/repos/$REPO/releases/latest"

os="$(uname -s)"; arch="$(uname -m)"
case "$os-$arch" in
  Darwin-arm64)  pattern='_aarch64\.dmg$' ;;
  Darwin-x86_64) pattern='_x64\.dmg$' ;;
  Linux-x86_64)  pattern='\.AppImage$' ;;
  *) echo "Sorry, no Mayak build for $os $arch yet." >&2; exit 1 ;;
esac

echo "Finding the latest Mayak release…"
json="$(curl -fsSL "$API")"
urls="$(printf '%s' "$json" | grep -o '"browser_download_url": *"[^"]*"' | sed 's/.*"\(https[^"]*\)"/\1/')"
url="$(printf '%s\n' "$urls" | grep -E "$pattern" | head -n1)"
sums="$(printf '%s\n' "$urls" | grep -E '/SHA256SUMS\.txt$' | head -n1)"
case "$url" in https://github.com/$REPO/releases/download/*) ;; *) echo "Unexpected download URL." >&2; exit 1 ;; esac
[ -n "$sums" ] || { echo "Checksum file missing from the release; refusing to install." >&2; exit 1; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
file="$tmp/$(basename "$url")"
echo "Downloading $(basename "$url")…"
curl -fL --progress-bar "$url" -o "$file"
curl -fsSL "$sums" -o "$tmp/SHA256SUMS.txt"

expected="$(grep " $(basename "$url")\$" "$tmp/SHA256SUMS.txt" | cut -d' ' -f1)"
if command -v sha256sum >/dev/null; then actual="$(sha256sum "$file" | cut -d' ' -f1)"; else actual="$(shasum -a 256 "$file" | cut -d' ' -f1)"; fi
[ -n "$expected" ] && [ "$expected" = "$actual" ] || { echo "Checksum mismatch! Not installing." >&2; exit 1; }
echo "Checksum OK."

if [ "$os" = Darwin ]; then
  mnt="$(hdiutil attach -nobrowse -readonly "$file" | awk -F'\t' '/\/Volumes\//{print $NF}')"
  dest="/Applications"; [ -w "$dest" ] || { dest="$HOME/Applications"; mkdir -p "$dest"; }
  rm -rf "$dest/Mayak.app"
  cp -R "$mnt/Mayak.app" "$dest/"
  hdiutil detach "$mnt" -quiet
  xattr -dr com.apple.quarantine "$dest/Mayak.app" 2>/dev/null || true  # skip the one-time "unidentified developer" prompt
  echo "Installed to $dest/Mayak.app. Opening…"
  open "$dest/Mayak.app"
else
  dest="$HOME/.local/bin"; mkdir -p "$dest" "$HOME/.local/share/applications"
  install -m 755 "$file" "$dest/Mayak.AppImage"
  cat > "$HOME/.local/share/applications/mayak.desktop" <<DESK
[Desktop Entry]
Name=Mayak
Comment=Systematic crypto trading for Hyperliquid
Exec=$dest/Mayak.AppImage
Terminal=false
Type=Application
Categories=Finance;
DESK
  echo "Installed to $dest/Mayak.AppImage (also in your applications menu)."
fi
