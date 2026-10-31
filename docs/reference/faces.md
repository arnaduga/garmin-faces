# Watch faces

| Face | Directory | Description |
|---|---|---|
| Submarine 24h | `src/submarine-24h` | Analog 24-hour dial (one hour-hand turn per day), minute hand, red seconds hand |
| Submariner 24 | `src/submariner-24` | 24-hour dial over a submarine-hatch background, luminous hands, day/night ring, three round gauges |

## Submarine 24h

Inspired by Russian submarine watches.

Supported devices (round AMOLED, 360, 390, 416 or 454 px): vívoactive 5 and 6, Venu 2S, Venu 2 Plus, 3, 3S and 4 (41 mm, 45 mm), Forerunner 70, 165, 165 Music, 170, 265, 570 (42 mm, 47 mm), 965 and 970, epix (Gen 2), epix Pro (Gen 2) 42 mm and 47 mm, fēnix 8 43 mm, 47 mm / 51 mm, fēnix 9 43 mm, 47 mm / 51 mm, fēnix 9 Pro 43 mm and 47 mm, fēnix E, Instinct 3 AMOLED 45 mm and 50 mm, MARQ (Gen 2), MARQ (Gen 2) Aviator and D2 Air X10. The exact ids are in `manifest.xml`. Pen widths and pictograms are tuned for 390 px and scaled with the screen width (`REFERENCE_WIDTH` and `px()` in `Submarine24View.mc`). Adding a device means listing it in `manifest.xml` and downloading its files (`DEVICES` in `scripts/setup-sdk.sh`); it must be round, have an AMOLED display and support API level 5.0.0.

- Midnight (24) is at the top, noon (12) at the bottom.
- Even hours are large white numerals; odd hours are small, dark grey, each marked by a thick amber tick on the minute track.
- The red seconds hand is only drawn in high-power mode (not while the display is dimmed).
- Low-power mode (display asleep): only the hour ticks, the even numerals and the hour/minute hands are drawn. The day/night ring, gauges, date, odd hours and minute ticks are hidden, to limit AMOLED burn-in.
- Battery: a small gauge ring (battery level, green / orange / red by threshold) with the percentage in the middle and a bolt icon in its gap.
- Steps: a small ring (steps / daily goal) with the step count in the middle and a walking-figure icon in its gap.
- Heart rate: a ring whose range is the day's heart rate, from the lowest bpm since midnight (0%) to the highest (100%); the current bpm fills it accordingly (empty when it is the only sample). The current bpm is in the middle (`--` when unknown) with a heart icon in the gap. Hidden in low-power mode.
- Stress: a ring filled by the stress score (0-100, last measurement), the score in the middle (`--` when unknown) and a zigzag icon in the gap.
- Active minutes: a ring filled by the week's active (intensity) minutes against the weekly goal, the minutes in the middle and a stopwatch icon in the gap.
- Gauge slots: there are three slots (top, right = hour 5 of the 24 h dial, left = the mirror position of the right one). Each has its own setting (`Top gauge`, `Right gauge`, `Left gauge`) to pick the gauge shown there: none, battery, steps, heart rate, stress or active minutes (default: heart top, steps right, battery left). Set a slot to `None` to show fewer than three gauges; picking the same gauge twice draws it twice. Every gauge has the same shape, with its gap and icon at the same place. Slot positions are tunable through `SLOT_ANGLE` / `SLOT_DISTANCE` in `Submarine24View.mc`.
- Date: weekday, then day and month in full (no year), on two lines under the center. French by default, or English (setting). The names are in `resources/strings/date.xml`, not taken from the watch language.
- Fonts: the numerals and small texts use vector fonts (`RobotoCondensedBold` for even hours, `RobotoCondensedRegular` for the rest, sizes relative to the screen width), with a built-in font as fallback. The face names available on a device are listed in its `simulator.json`, in the SDK folder (`Devices/<device>/`).

### Settings (Submarine 24h)

| Setting | Type | Default |
|---|---|---|
| Hands color | color | silver |
| Seconds hand color | color | red |
| Odd-hour marks color | color | amber |
| Steps ring color | color | blue |
| Heart icon color | color | red |
| Top / right / left gauge | list (none, battery, steps, heart rate, stress, active minutes) | heart / steps / battery |
| Stress ring color | color | orange |
| Active minutes ring color | color | magenta |
| Battery ring color | color | green |
| Battery orange below / red below (%) | number | 30 / 15 |
| Show seconds hand, date, odd-hour numerals | on/off | on |
| Show day/night ring | on/off | on |
| Day / night color | color | amber (same as the odd-hour marks) / dark grey |
| Midnight (24) at the top | on/off | on |
| Date language | French / English | French |

The settings screen is in English. Values are read by `Config` (`source/Config.mc`).

#### Gauge values (`GaugeTop`, `GaugeRight`, `GaugeLeft`)

These three properties in `properties.xml` take the same integer values. The default is 3 for `GaugeTop`, 2 for `GaugeRight` and 1 for `GaugeLeft`. A value outside 0-5 is ignored and the slot's default is used.

| Value | Gauge |
|---|---|
| 0 | None |
| 1 | Battery |
| 2 | Steps |
| 3 | Heart rate |
| 4 | Stress |
| 5 | Active minutes (week) |

### Hand styles (Submarine 24h)

The `Hand style` setting applies to both the hour and the minute hand. Transparency effects are simulated by shading colors towards black, which is exact on the black dial.

| Value | Name | Look |
|---|---|---|
| 0 | Classic | Tapered kite with a short tail |
| 1 | Baton | Plain rectangle |
| 2 | Lozenge | Diamond, widest at a quarter of the length |
| 3 | Dauphine | Kite with a dark ridge down the middle (two facets) |
| 4 | Skeleton | Outline only |
| 5 | Alpha | Thin stem swelling into a leaf near the tip |
| 6 | Breguet | Thin stem with a ring near the tip |
| 7 | Arrow | Thin shaft with a square-shouldered arrowhead |
| 8 | Leaf | Lens shape (sine profile) |
| 9 | Pencil | Rectangle ending in a point |
| 10 | Ghost | Translucent look: dimmed body inside a full-color outline |
| 11 | Glass | Tinted glass lozenge with a bright reflection line |
| 12 | Neon | Glowing stroke in the odd-hour mark color with a white core |
| 13 | Two-tone | Kite split lengthwise: one half bright, the other shaded |
| 14 | Sword | Blade with a cross-guard and a round pommel |
| 15 | Mercedes | Ring with a three-pointed star, thin stem, pointed blade |
| 16 | Pearls | String of beads shrinking towards the tip |
| 17 | Comet | Faked gradient: brighter and thinner towards the tip |
| 18 | Bubble | Magnifier: the stem is the handle, a lens placed near the dial numerals (clear of the gauges) shows the hour (hour hand) or the minutes (minute hand) in bold digits |

### Day/night ring (Submarine 24h)

The outermost ring shows the day (sunrise to sunset, in the day color) against the night (night color) on the 24 h scale. Sun times come from `Weather.getSunrise`/`getSunset` at the last known position (the `Positioning` permission), remembered in storage; they are recomputed once a day. Without any known position the ring is only the night color.


## Submariner 24

A second 24-hour face with a different look: a submarine hatch (plate, bolts, periscope, bronze gear) in the middle, luminous hands and round gauges at the bottom. It has no settings yet.

- Dial: midnight (`00`) at the top, `06` on the right, `12` at the bottom, `18` on the left. Long amber ticks mark the even hours, grey ones the odd hours, short ones the half hours.
- Hands: luminous hour hand (one turn per day) and minute hand, red seconds hand (high-power mode only).
- Day/night ring: light blue from sunrise to sunset, black for the night, around the hatch. Same sun-time logic as Submarine 24h (`Positioning` permission).
- Gauges (bottom): battery on the left (green / orange / red below 30 / 15 %), steps in the middle (steps / daily goal), heart rate on the right (current bpm between today's lowest and highest). Each ring fills clockwise from the top.
- Name plate: `SUBMARINER 24H`, right of the gear.
- Low-power mode: only the even-hour ticks, the numerals and the hour/minute hands are drawn.
- No date is shown.
