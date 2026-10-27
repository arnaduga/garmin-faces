# Change the SDK version

```bash
SDK_VERSION=8.2.0 scripts/setup-sdk.sh
```

Replace `8.2.0` with any version accepted by `connect-iq-sdk-manager sdk set` (semver ranges such as `^8.0.0` work). Update `minApiLevel` in the face's `manifest.xml` if needed.
