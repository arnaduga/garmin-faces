# Configure the Submarine 24h face

The face reads its settings from `src/submarine-24h/resources/properties/properties.xml`
(default values) and shows them in the settings screen described by `resources/settings/settings.xml`.

## Change a setting in the simulator

1. Start the simulator with `scripts/simulate.sh src/submarine-24h`.
2. In the simulator window, open the **File** menu and choose the entry that edits the application settings (the exact name depends on the SDK version).
3. Change a value and confirm: the face is redrawn immediately.

## Add a setting

1. Add a `<property>` with its default value in `properties.xml`.
2. Add a `<setting>` in `settings.xml` and its title in `resources/strings/settings.xml`.
3. Read it in `Config.load()` (`source/Config.mc`) and use it from `Submarine24View`.
4. Rebuild and rerun the simulator: new properties are only picked up after a build.

> On a real watch, settings are edited from the phone app. This normally requires the face to be installed from the Connect IQ Store (a private beta is enough); a sideloaded `.prg` has no settings screen.

## Preview the hand styles

1. Run `scripts/simulate.sh src/submarine-24h` (this rebuilds the face).
2. In the simulator, edit the application settings and change **Hand style**; the face is redrawn at each change.
3. Set the simulated time to compare how each style looks at different angles (for example 10:10, 3:00, 21:45): the hour hand is short and wide, the minute hand long and thin, so a style can look good on one and poor on the other.

