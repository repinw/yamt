# yamt

A new Flutter project.

## Android integration tests

Use a headless Android emulator snapshot for native `flutter drive` runs:

```bash
rtk tool/android_integration_emulator.sh prepare-snapshot
rtk tool/android_integration_emulator.sh run
```

The default snapshot is `yamt-clean-ready` on the `Pixel_9` AVD. The snapshot
is saved after uninstalling `de.yamt.app`, and each test run removes the app
again before `flutter drive` installs the current build on `emulator-5554`.
