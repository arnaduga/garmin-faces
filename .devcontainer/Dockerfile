FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# Connect IQ compiler (monkeyc) is a Java program; the SDK manager is a static Go binary.
RUN apt-get update \
    && apt-get install -y --no-install-recommends openjdk-17-jre-headless libusb-1.0-0 \
       xvfb x11vnc novnc websockify fluxbox libwebkit2gtk-4.1-0 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/lindell/connect-iq-sdk-manager-cli/master/install.sh \
    | BINDIR=/usr/local/bin sh

# Pre-create the volume mount points so Docker initialises them owned by vscode.
RUN mkdir -p /home/vscode/.Garmin /home/vscode/.connect-iq-sdk-manager \
    && chown -R vscode:vscode /home/vscode/.Garmin /home/vscode/.connect-iq-sdk-manager
