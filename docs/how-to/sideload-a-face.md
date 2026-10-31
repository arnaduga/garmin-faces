# Sideload a face onto the watch

Install a face directly over USB, without the Connect IQ Store (for example before a store beta).

1. Build the face: `scripts/build.sh src/<face-name>`. The result is `build/<face-name>.prg`, signed with your developer key (`.keys/developer_key.der`), which is enough for a local install.
2. Connect the Vivoactive 6 to your computer over USB.
3. Copy `build/<face-name>.prg` to `GARMIN/Apps/` on the watch (the folder may be spelled `GARMIN/APPS/`).
4. Eject the watch. It takes a few seconds to load the face; then pick it in the watch face picker (long-press the watch face, or the watch face settings of the watch).

> The container has no USB access: copy the file from the host. The repository folder is shared, so `build/<face-name>.prg` is already on the host.

## On macOS: the watch is not in the Finder

The Vivoactive 6 appears as an MTP device, not as a disk. Use an MTP transfer app such as OpenMTP or Android File Transfer to copy the file. These are the usual tools for recent Garmin watches; they have not been verified with this model in this project.

## What to expect

- **Settings are not editable.** Without a Connect IQ Store install, the settings screen does not appear in the Garmin Connect app, so the watch uses the defaults of `resources/properties/properties.xml`. To try another hand style or gauge layout, change the default, rebuild and copy the file again (the same limitation as in the simulator).
- **Real sensors.** This is what the simulator cannot show: heart rate, steps, battery, the last known GPS position for the day/night ring, and the AMOLED sleep display. The day/night ring uses the last known position: start an outdoor activity once if it still shows the 06:00–18:00 placeholder.

## If the face does not start

When a Connect IQ app crashes, the watch writes a log file `CIQ_LOG.YML` (usually in `GARMIN/Apps/LOGS/`). Copy it to your computer and read the exception and the source line it names.
