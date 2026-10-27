# Getting started

In this tutorial you set up the environment and compile a face for the Vivoactive 6.

## Prerequisites

- Docker and VS Code with the Dev Containers extension.
- A free Garmin account.

## Steps

1. Open the repository in VS Code and run **Dev Containers: Reopen in Container**.
2. In the container terminal, run:

   ```bash
   scripts/setup-sdk.sh
   ```

   Follow the login prompt. The script installs the SDK, downloads the `vivoactive6` device files and generates a developer key in `.keys/`.
3. Put the SDK on your `PATH`:

   ```bash
   export PATH="$(connect-iq-sdk-manager sdk current-path --bin):$PATH"
   monkeyc --version
   ```
4. A first face, `simple-time`, is already in `src/simple-time/`. To start another one, copy it and give the copy a new app `id` in its `manifest.xml`.
5. Build it:

   ```bash
   scripts/build.sh src/<face-name>
   ```

You now have `build/<face-name>.prg`. To install it, see [Sideload a face](../how-to/sideload-a-face.md).
