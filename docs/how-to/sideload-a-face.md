# Sideload a face onto the watch

1. Build the face: `scripts/build.sh src/<face-name>`.
2. Connect the Vivoactive 6 to your computer over USB.
3. Copy `build/<face-name>.prg` to `GARMIN/Apps/` on the watch.
4. Eject the watch, then select the face from the watch face picker.

> The container has no USB access by default: copy the file from the host (the repository folder is shared).
