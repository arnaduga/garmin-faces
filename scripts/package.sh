#!/usr/bin/env bash
# Usage: scripts/package.sh <project-dir>
# Builds the .iq package to upload to the Connect IQ Store (build/<face-name>.iq).
set -euo pipefail

PROJECT="${1:?usage: package.sh <project-dir>}"
KEY="${DEVELOPER_KEY:-.keys/developer_key.der}"

export PATH="$(connect-iq-sdk-manager sdk current-path --bin):$PATH"
mkdir -p build
monkeyc -e -f "$PROJECT/monkey.jungle" -y "$KEY" -o "build/$(basename "$PROJECT").iq" -r -w
