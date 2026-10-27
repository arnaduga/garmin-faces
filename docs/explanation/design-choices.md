# Design choices

## Why a devcontainer

The Connect IQ toolchain (Java, SDK, device files) is large and version-sensitive. Keeping it in a container leaves the host clean and makes the setup reproducible.

## Why the SDK is not baked into the image

Garmin requires a licence agreement and a login to download the SDK and device files. They are fetched at first setup into named Docker volumes, so they survive image rebuilds but are never redistributed.

## Simulator limitation

The Connect IQ simulator is a GUI application and is not installed in the container. The container compiles; to preview, install the SDK on the host or add a virtual display (Xvfb/noVNC) to the image later. Real-device testing works through [sideloading](../how-to/sideload-a-face.md).
