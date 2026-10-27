# garmin-faces

Watch faces for the Garmin Vivoactive 6 (Connect IQ, Monkey C), developed inside the devcontainer.

- Documentation, code comments and user-facing strings are written in English.
- Docs follow Diátaxis: `docs/tutorials`, `docs/how-to`, `docs/reference`, `docs/explanation`.
- Every user-visible change is recorded in `CHANGELOG.md` (Keep a Changelog).
- One face per directory under `src/<face-name>/` (with its own `manifest.xml` and `monkey.jungle`).
- Never commit `.keys/` (developer signing key).
- Build: `scripts/build.sh src/<face-name>`.
- Exception: the date of `submarine-24h` is French by default (user setting: French or English). The settings screen is in English.

