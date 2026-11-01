# Getting started

In this tutorial you set up the environment and compile a face (the examples use the Vivoactive 6, the default device).

## Prerequisites

- Docker.
- VS Code with the Dev Containers extension, **or** any editor (e.g. VSCodium) plus `scripts/shell.sh`.
- A free Garmin account.

## Steps

1. Enter the container: run **Dev Containers: Reopen in Container** in VS Code, or `scripts/shell.sh` from a host terminal (VSCodium users: see [Use VSCodium](../how-to/use-vscodium.md)).
2. In the container shell, run:

   ```bash
   scripts/setup-sdk.sh
   ```

   Follow the login prompt. The script installs the SDK, downloads the device files of every device listed in the `manifest.xml` files under `src/`, and generates a developer key in `.keys/`.
3. Put the SDK on your `PATH`:

   ```bash
   export PATH="$(connect-iq-sdk-manager sdk current-path --bin):$PATH"
   monkeyc -v
   ```
4. A first face, `submarine-24h`, is already in `src/submarine-24h/`. To start another one, copy it and give the copy a new app `id` in its `manifest.xml`.
5. Build it:

   ```bash
   scripts/build.sh src/<face-name>
   ```

You now have `build/<face-name>.prg`. To install it, see [Sideload a face](../how-to/sideload-a-face.md).
