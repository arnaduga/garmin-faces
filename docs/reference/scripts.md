# Scripts reference

## `scripts/setup-sdk.sh`

Installs the SDK, the device files and a developer key.

| Variable | Default | Meaning |
|---|---|---|
| `SDK_VERSION` | `latest` | Version passed to `sdk set` |
| `DEVICE` | `vivoactive6` | Device whose files are downloaded |
| `DEVELOPER_KEY` | `.keys/developer_key.der` | Signing key path (generated if missing) |

## `scripts/build.sh <project-dir> [device]`

Compiles `<project-dir>/monkey.jungle` for `device` (default `vivoactive6`) into `build/<project-name>.prg`.

## `scripts/simulate.sh <project-dir> [device]`

Builds the face, starts a virtual display (Xvfb + VNC + noVNC) and the Connect IQ simulator, then loads the face. View it at <http://localhost:6080/vnc.html>. Must be run inside `scripts/shell.sh`, which publishes port 6080.

## `scripts/shell.sh [command...]`

Builds `.devcontainer/Dockerfile` and runs `command` (default `bash`) in it, with the repository mounted at `/workspace` and the same volumes as the devcontainer. Needs only Docker.

## Devcontainer

| Item | Value |
|---|---|
| Base image | Ubuntu 22.04 (`devcontainers/base`) |
| Installed | OpenJDK 17 JRE, `connect-iq-sdk-manager`, Xvfb, x11vnc, noVNC, fluxbox, WebKitGTK 4.0 |
| Volumes | `garmin-faces-sdk`, `garmin-faces-sdk-manager` (persist SDK and login) |
| VS Code extension | `garmin.monkey-c` |
