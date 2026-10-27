#!/usr/bin/env bash
# Open a shell (or run a command) in the dev image without the Dev Containers extension.
# Usage: scripts/shell.sh [command...]
set -euo pipefail

cd "$(dirname "$0")/.."
IMAGE=garmin-faces-dev

# The Connect IQ simulator is x86_64 only: emulate it on Apple Silicon.
docker build -q --platform linux/amd64 -t "$IMAGE" .devcontainer >/dev/null

TTY=()
[ -t 0 ] && TTY=(-it)

exec docker run --rm --platform linux/amd64 "${TTY[@]}" \
  -p 6080:6080 \
  -v "$PWD":/workspace -w /workspace \
  -v garmin-faces-sdk:/home/vscode/.Garmin \
  -v garmin-faces-sdk-manager:/home/vscode/.connect-iq-sdk-manager \
  -e DEVELOPER_KEY=/workspace/.keys/developer_key.der \
  --user vscode "$IMAGE" "${@:-bash}"
