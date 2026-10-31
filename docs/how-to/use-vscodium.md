# Use VSCodium

The Dev Containers extension is proprietary and not available for VSCodium (Open VSX), so there is no *Reopen in Container*. Edit on the host and run the tools in the container instead:

```bash
scripts/shell.sh                              # interactive shell
scripts/shell.sh scripts/setup-sdk.sh         # one-off command
scripts/shell.sh scripts/build.sh src/submarine-24h
```

The repository is mounted at `/workspace`, so files edited in VSCodium are immediately visible in the container.

The `garmin.monkey-c` extension is published on the Microsoft Marketplace only; without it you get no Monkey C highlighting or simulator integration, but building works the same.
