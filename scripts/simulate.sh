#!/usr/bin/env bash
# Run a face in the Connect IQ simulator, displayed in the browser at http://localhost:6080/vnc.html
# Usage: scripts/simulate.sh <project-dir> [device]   (run inside scripts/shell.sh)
set -euo pipefail

PROJECT="${1:?usage: simulate.sh <project-dir> [device]}"
DEVICE="${2:-vivoactive6}"

scripts/build.sh "$PROJECT" "$DEVICE"
export PATH="$(connect-iq-sdk-manager sdk current-path --bin):$PATH"

export DISPLAY=:99
# No GPU in the container: force software rendering.
export LIBGL_ALWAYS_SOFTWARE=1
export GDK_BACKEND=x11
export WEBKIT_DISABLE_COMPOSITING_MODE=1
export NO_AT_BRIDGE=1

Xvfb :99 -screen 0 1280x800x24 +extension GLX +render -noreset >/dev/null 2>&1 &
trap 'kill $(jobs -p) 2>/dev/null' EXIT
sleep 1
fluxbox >/dev/null 2>&1 &
x11vnc -display :99 -nopw -forever -quiet >/dev/null 2>&1 &
websockify --web /usr/share/novnc 6080 localhost:5900 >/dev/null 2>&1 &

connectiq &
sleep 5
echo "Open http://localhost:6080/vnc.html and click Connect. Ctrl+C to stop."
monkeydo "build/$(basename "$PROJECT").prg" "$DEVICE"
wait
