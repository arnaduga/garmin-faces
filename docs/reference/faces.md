# Watch faces

| Face | Directory | Description |
|---|---|---|
| Simple Time | `src/simple-time` | Digital `HH:MM` and date |
| Submarine 24h | `src/submarine-24h` | Analog 24-hour dial (one hour-hand turn per day, numerals 1–24), minute hand, date window |

## Submarine 24h

- Midnight is at the bottom and noon at the top. Change `MIDNIGHT_ANGLE` in `Submarine24View.mc` (`0` puts midnight at the top).
- Night hours (19–05) are drawn dimmed.
- Hour hand: orange, 24 h scale. Minute hand: white, 60-minute track on the outer ring.
