FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Connect IQ compiler (monkeyc) is a Java program; the SDK manager is a static Go binary.
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends openjdk-17-jre-headless libusb-1.0-0 libwebkit2gtk-4.0-37 \
    && rm -rf /var/lib/apt/lists/*

# Virtual display for the simulator, viewed in a browser (noVNC pulls in Python,
# which segfaults under QEMU user emulation: use Rosetta, see docs/explanation).
RUN apt-get update \
    && apt-get install -y --no-install-recommends xvfb x11vnc novnc websockify fluxbox \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/lindell/connect-iq-sdk-manager-cli/master/install.sh \
    | BINDIR=/usr/local/bin sh

# Pre-create the volume mount points so Docker initialises them owned by vscode.
RUN mkdir -p /home/vscode/.Garmin /home/vscode/.connect-iq-sdk-manager \
    && chown -R vscode:vscode /home/vscode/.Garmin /home/vscode/.connect-iq-sdk-manager
