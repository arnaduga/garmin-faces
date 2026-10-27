# garmin-faces

Watch faces for the **Garmin Vivoactive 6**, written in Monkey C with the Connect IQ SDK.
Everything runs in a devcontainer so nothing but Docker is installed on the host.

## Quick start

1. Open the folder in VS Code and choose **Reopen in Container** (or use the `devcontainer` CLI).
2. In the container, run `scripts/setup-sdk.sh` (Garmin account required).
3. Build a face: `scripts/build.sh src/<face-name>`.

Full walkthrough: [docs/tutorials/getting-started.md](docs/tutorials/getting-started.md).

## Documentation

| Section | Purpose |
|---|---|
| [Tutorials](docs/tutorials/) | Learn by doing, step by step |
| [How-to guides](docs/how-to/) | Solve a specific task |
| [Reference](docs/reference/) | Look up facts: scripts, layout, config |
| [Explanation](docs/explanation/) | Understand the design choices |

## Project layout

```
.devcontainer/   container definition
scripts/         SDK setup and build helpers
src/             one directory per watch face
docs/            Diátaxis documentation
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md).
