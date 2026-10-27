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

## Devcontainer

| Item | Value |
|---|---|
| Base image | Ubuntu 24.04 (`devcontainers/base`) |
| Installed | OpenJDK 17 JRE, `connect-iq-sdk-manager` |
| Volumes | `garmin-faces-sdk`, `garmin-faces-sdk-manager` (persist SDK and login) |
| VS Code extension | `garmin.monkey-c` |
