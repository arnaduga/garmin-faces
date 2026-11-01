# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- MIT license (`LICENSE`).

## [0.3.0] - 2026-10-31

### Added

- `submarine-24h`: 31 more round AMOLED watches (360, 390, 416 and 454 px) are supported, with pen widths and pictograms scaled to the screen width: vívoactive 5, Venu 2S / 2 Plus / 3 / 3S / 4, Forerunner 70 / 165 / 170 / 265 / 570 / 965 / 970, epix (Gen 2) and epix Pro, fēnix 8 / 9 / E, Instinct 3 AMOLED, MARQ (Gen 2) and D2 Air X10.
- `submarine-24h`: on devices without vector fonts (for example vívoactive 5, Venu 3 and 3S), the numerals and date use the built-in font closest to the intended size and the gauge texts use the smallest one, instead of fixed, larger fonts.
- `submarine-24h`: stress and active-minutes gauges, with their ring colors in the settings.

### Changed

- `submarine-24h`: the heart-rate gauge's daily min/max is now queried once per minute instead of on every redraw, reducing CPU work (and battery use) while the display is active.
- `submarine-24h`: the heart, steps and battery gauge icons are 1.25x larger.
- `submarine-24h`: the date text is about 20% larger.
- `submarine-24h`: hand style 14 (Lume) is removed. Sword, Mercedes, Pearls, Comet and Bubble are renumbered 14 to 18 (they were 15 to 19); a saved Lume style falls back to Sword, and a saved Bubble style to the classic hands.
- `submarine-24h`: the `Gauge layout`, `Show steps`, `Show heart rate` and `Show battery` settings are replaced by one setting per slot (`Top gauge`, `Right gauge`, `Left gauge`); each can show battery, steps, heart rate, stress, active minutes or nothing. Defaults are unchanged in look (heart top, steps right, battery left). Saved values of the old settings are not carried over.

### Removed

- The `simple-time` test face (`src/simple-time`).

## [0.1.0] - 2026-10-28

First closed beta of `submarine-24h`.

### Added

- `scripts/package.sh` exports a face as a `.iq` package for the Connect IQ Store.
- `submarine-24h`: 10 more hand styles (Ghost, Glass, Neon, Two-tone, Lume, Sword, Mercedes, Pearls, Comet, Bubble). Hand style values are now contiguous: Arrow, Leaf and Pencil are 7, 8 and 9 (they were 8, 9, 10); the new styles are 10 to 19.
- `submarine-24h`: "Gauge layout" setting to choose where the battery, steps and heart-rate gauges sit (top, right, left; 6 arrangements, default battery left / steps right / heart top).
- `submarine-24h`: heart-rate ring (current bpm, heart icon), same design as the battery gauge; settings "Show heart rate" and "Heart icon color".
- `submarine-24h`: lighter low-power (sleep) display: only the hour ticks, even numerals and the hour/minute hands are drawn (no day/night ring, gauges, date, odd hours or minute ticks).
- `submarine-24h`: the steps gauge icon is now a walking figure instead of two footprints.
- `submarine-24h`: the day/night ring defaults to amber (day) and dark grey (night, like the unfilled part of the gauges); "Amber" and "Dark grey" join the color lists.
- `submarine-24h`: the day/night ring now falls back to a local sunrise/sunset computation, and to 06:00–18:00 without any known position, so both colors always show.
- Devcontainer with Java and the Connect IQ SDK manager CLI.
- Scripts to install the SDK and device files (`scripts/setup-sdk.sh`) and to build a face (`scripts/build.sh`).
- Documentation skeleton following the Diátaxis framework.
- `simple-time` watch face: HH:MM and date on a black background (`src/simple-time`).
- `scripts/shell.sh` to use the dev image without the Dev Containers extension (VSCodium).
- `scripts/simulate.sh` to run the Connect IQ simulator in the container, viewed through noVNC on port 6080.
- `submarine-24h` watch face: analog 24-hour dial in the style of Russian submarine watches (`src/submarine-24h`), with a battery gauge, a steps gauge and the date in French.

- Settings for `submarine-24h`: colors, elements to show, midnight position, battery thresholds and date language (French or English). See `docs/how-to/configure-the-face.md`.
- 10 hand styles for `submarine-24h` (Classic, Baton, Lozenge, Dauphine, Skeleton, Alpha, Breguet, Arrow, Leaf, Pencil), selectable with the `Hand style` setting.
- Optional day/night ring (sunrise to sunset) around the dial of `submarine-24h`, with day and night color settings; needs the `Positioning` permission.

### Changed

- `submarine-24h`: all fonts (hour numerals, gauge values, date) are slightly larger, and the gauge values are light grey instead of white.
- `submarine-24h`: the default color of the odd-hour marks and of the day/night ring is now the same amber.
- `submarine-24h`: the heart rate gauge now spans the day's lowest (0%) to highest (100%) bpm and fills according to the current bpm.

### Fixed

- Run the dev image as `linux/amd64` so the x86_64 simulator starts on Apple Silicon.
