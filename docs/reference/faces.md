# Watch faces

| Face | Directory | Description |
|---|---|---|
| Simple Time | `src/simple-time` | Digital `HH:MM` and date |
| Submarine 24h | `src/submarine-24h` | Analog 24-hour dial (one hour-hand turn per day), minute hand, red seconds hand |

## Submarine 24h

Inspired by Russian submarine watches.

- Midnight (24) is at the top, noon (12) at the bottom.
- Even hours are large white numerals; odd hours are small, dark grey, each marked by a thick orange tick on the minute track.
- The red seconds hand is only drawn in high-power mode (not while the display is dimmed).
- Battery: a small gauge ring (like the steps one) toward hour 5 of the 24 h dial (75° clockwise from the top), with the percentage in the middle and a lightning bolt in its gap. The arc is green by default, orange and red below the configured thresholds.
- Steps: a small blue ring above the center (steps / daily goal), running clockwise from 335° to 285° (degrees clockwise from the top), with the step count in the middle and a footprint icon in its gap. Tunable through the `STEPS_*` constants in `Submarine24View.mc`.
- Date: weekday, then day and month in full (no year), on two lines under the center. French by default, or English (setting). The names are in `resources/strings/date.xml`, not taken from the watch language.
- Fonts: the numerals and small texts use vector fonts (`RobotoCondensedBold` for even hours, `RobotoCondensedRegular` for the rest, sizes relative to the screen width), with a built-in font as fallback. The face names available on a device are listed in its `simulator.json`, in the SDK folder (`Devices/<device>/`).

### Settings (Submarine 24h)

| Setting | Type | Default |
|---|---|---|
| Hands color | color | silver |
| Seconds hand color | color | red |
| Odd-hour marks color | color | orange |
| Steps ring color | color | blue |
| Battery ring color | color | green |
| Battery orange below / red below (%) | number | 30 / 15 |
| Show seconds hand, date, steps, battery, odd-hour numerals | on/off | on |
| Show day/night ring | on/off | on |
| Day / night color | color | yellow / navy |
| Midnight (24) at the top | on/off | on |
| Date language | French / English | French |

The settings screen is in English. Values are read by `Config` (`source/Config.mc`).

### Hand styles (Submarine 24h)

The `Hand style` setting applies to both the hour and the minute hand.

| Value | Name | Look |
|---|---|---|
| 0 | Classic | Tapered kite with a short tail |
| 1 | Baton | Plain rectangle |
| 2 | Lozenge | Diamond, widest at a quarter of the length |
| 3 | Dauphine | Kite with a dark ridge down the middle (two facets) |
| 4 | Skeleton | Outline only |
| 5 | Alpha | Thin stem swelling into a leaf near the tip |
| 6 | Breguet | Thin stem with a ring near the tip |
| 7 | Syringe | Thin needle with a wide section on the stem |
| 8 | Arrow | Thin shaft with a square-shouldered arrowhead |
| 9 | Leaf | Lens shape (sine profile) |
| 10 | Pencil | Rectangle ending in a point |

### Day/night ring (Submarine 24h)

The outermost ring shows the day (sunrise to sunset, in the day color) against the night (night color) on the 24 h scale. Sun times come from `Weather.getSunrise`/`getSunset` at the last known position (the `Positioning` permission), remembered in storage; they are recomputed once a day. Without any known position the ring is only the night color.

