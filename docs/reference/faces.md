# Watch faces

| Face | Directory | Description |
|---|---|---|
| Simple Time | `src/simple-time` | Digital `HH:MM` and date |
| Submarine 24h | `src/submarine-24h` | Analog 24-hour dial (one hour-hand turn per day), minute hand, red seconds hand |

## Submarine 24h

Inspired by Russian submarine watches.

- Midnight (24) is at the top, noon (12, a hollow triangle) at the bottom.
- Even hours are large white numerals; odd hours are small, dark grey, each marked by a thick orange tick on the minute track.
- The red seconds hand is only drawn in high-power mode (not while the display is dimmed).
- Battery: a ring on the outer edge (green, orange below 30 %, red below 15 %) filling clockwise from the 1 h position (0 %) to the 23 h position (100 %), with rounded ends; the remaining charge is shown at the top, preceded by a lightning bolt.
- Steps: a small blue ring at about 2 o'clock (steps / daily goal), running clockwise from 320° to 300° (degrees clockwise from the top), with the step count in the middle and a footprint icon in its gap. Tunable through the `STEPS_*` constants in `Submarine24View.mc`.
