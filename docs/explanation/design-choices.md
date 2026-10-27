# Design choices

## Why a devcontainer

The Connect IQ toolchain (Java, SDK, device files) is large and version-sensitive. Keeping it in a container leaves the host clean and makes the setup reproducible.

## Why the SDK is not baked into the image

Garmin requires a licence agreement and a login to download the SDK and device files. They are fetched at first setup into named Docker volumes, so they survive image rebuilds but are never redistributed.

## Simulator in a browser

The simulator is a GUI application. The image bundles a virtual display (Xvfb) exported over VNC and noVNC, so the simulator is viewed in a browser tab at `localhost:6080` and nothing graphical is installed on the host. Real-device testing works through [sideloading](../how-to/sideload-a-face.md).
