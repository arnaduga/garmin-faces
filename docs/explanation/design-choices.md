# Design choices

## Why a devcontainer

The Connect IQ toolchain (Java, SDK, device files) is large and version-sensitive. Keeping it in a container leaves the host clean and makes the setup reproducible.

## Why the SDK is not baked into the image

Garmin requires a licence agreement and a login to download the SDK and device files. They are fetched at first setup into named Docker volumes, so they survive image rebuilds but are never redistributed.

## Simulator in a browser

The simulator is a GUI application. The image bundles a virtual display (Xvfb) exported over VNC and noVNC, so the simulator is viewed in a browser tab at `localhost:6080` and nothing graphical is installed on the host. Real-device testing works through [sideloading](../how-to/sideload-a-face.md).

## x86_64 image

The simulator ships as an x86_64 binary only, so the image is built for `linux/amd64`, even on Apple Silicon where Docker emulates it. Builds and the simulator are slower than native. Rosetta makes emulation much faster: with Colima, start the VM using `colima start --vm-type vz --vz-rosetta`; with Docker Desktop, enable *Use Rosetta for x86_64/amd64 emulation* in Settings → General.

## Rosetta is required on Apple Silicon

Under plain QEMU emulation, `python3` (pulled in by noVNC) segfaults during the image build. Use Rosetta: `colima start --vm-type vz --vz-rosetta`, or the equivalent Docker Desktop setting.

## Ubuntu 22.04 base

The Linux simulator links against `libwebkit2gtk-4.0`, which Ubuntu 24.04 no longer ships (it only has 4.1). The image therefore uses Ubuntu 22.04.
