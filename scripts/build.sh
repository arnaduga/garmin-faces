#!/usr/bin/env bash
# Usage: scripts/build.sh <project-dir> [device]
set -euo pipefail

PROJECT="${1:?usage: build.sh <project-dir> [device]}"
DEVICE="${2:-vivoactive6}"
KEY="${DEVELOPER_KEY:-.keys/developer_key.der}"

export PATH="$(connect-iq-sdk-manager sdk current-path --bin):$PATH"
mkdir -p build
monkeyc -f "$PROJECT/monkey.jungle" -d "$DEVICE" -y "$KEY" -o "build/$(basename "$PROJECT").prg" -w
