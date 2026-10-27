#!/usr/bin/env bash
# Install the Connect IQ SDK, the vivoactive6 device files and a developer key.
set -euo pipefail

SDK_VERSION="${SDK_VERSION:-latest}"
DEVICE="${DEVICE:-vivoactive6}"
KEY="${DEVELOPER_KEY:-.keys/developer_key.der}"

connect-iq-sdk-manager agreement view
connect-iq-sdk-manager agreement accept
connect-iq-sdk-manager login

if [ "$SDK_VERSION" = "latest" ]; then
  connect-iq-sdk-manager sdk set "*"
else
  connect-iq-sdk-manager sdk set "$SDK_VERSION"
fi
connect-iq-sdk-manager device download -d "$DEVICE"

if [ ! -f "$KEY" ]; then
  mkdir -p "$(dirname "$KEY")"
  openssl genrsa -out "${KEY%.der}.pem" 4096
  openssl pkcs8 -topk8 -inform PEM -outform DER -in "${KEY%.der}.pem" -out "$KEY" -nocrypt
  echo "Developer key generated: $KEY (back it up; never commit it)"
fi

echo "Add to PATH: export PATH=\"\$(connect-iq-sdk-manager sdk current-path --bin):\$PATH\""
