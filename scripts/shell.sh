#!/usr/bin/env bash
# Open a shell (or run a command) in the dev image without the Dev Containers extension.
# Usage: scripts/shell.sh [command...]
set -euo pipefail

cd "$(dirname "$0")/.."
IMAGE=garmin-faces-dev

# The Connect IQ simulator is x86_64 only: emulate it on Apple Silicon.
LOG="$(mktemp)"
if ! docker build --progress=plain --platform linux/amd64 -t "$IMAGE" .devcontainer >"$LOG" 2>&1; then
  tail -n 60 "$LOG" >&2
  echo "Image build failed (full log: $LOG)" >&2
  exit 1
fi
rm -f "$LOG"

# Same timezone as the host, so the simulator shows the local time.
TZ_NAME="${TZ:-$(readlink /etc/localtime | sed 's|.*/zoneinfo/||')}"

TTY=()
[ -t 0 ] && TTY=(-it)

exec docker run --rm --platform linux/amd64 "${TTY[@]}" \
  -p 6080:6080 \
  -v "$PWD":/workspace -w /workspace \
  -v garmin-faces-sdk:/home/vscode/.Garmin \
  -v garmin-faces-sdk-manager:/home/vscode/.connect-iq-sdk-manager \
  -e TZ="$TZ_NAME" \
  -e DEVELOPER_KEY=/workspace/.keys/developer_key.der \
  --user vscode "$IMAGE" "${@:-bash}"
