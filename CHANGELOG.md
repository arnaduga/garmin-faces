# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Devcontainer with Java and the Connect IQ SDK manager CLI.
- Scripts to install the SDK and device files (`scripts/setup-sdk.sh`) and to build a face (`scripts/build.sh`).
- Documentation skeleton following the Diátaxis framework.
- `simple-time` watch face: HH:MM and date on a black background (`src/simple-time`).
- `scripts/shell.sh` to use the dev image without the Dev Containers extension (VSCodium).
- `scripts/simulate.sh` to run the Connect IQ simulator in the container, viewed through noVNC on port 6080.

### Fixed

- Run the dev image as `linux/amd64` so the x86_64 simulator starts on Apple Silicon.
