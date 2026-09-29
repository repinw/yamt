#!/usr/bin/env bash
# Runs one integration test on emulator-5554 with the APK that CI built
# before, for .github/workflows/ci.yml.
#
# flutter drive sometimes cannot connect to the app's VM Service through the
# adb port forward and retries forever, although the app runs. Each attempt
# therefore ends after 4 minutes. A timed-out attempt is retried; a test
# failure is not. On failure the device log is written to logcat.txt.
#
# Usage: tool/ci_integration_drive.sh <integration test file>
set -uo pipefail

target="$1"
apk=build/app/outputs/flutter-apk/app-debug.apk

for attempt in 1 2 3; do
  timeout 4m flutter drive \
    --driver=test_driver/integration_test.dart \
    --target="$target" \
    --use-application-binary="$apk" \
    -d emulator-5554
  status=$?
  if [ "$status" -ne 124 ]; then
    break
  fi
  echo "flutter drive timed out on attempt $attempt." >&2
  pkill -f -- "--target=$target" || true
done

if [ "$status" -ne 0 ]; then
  adb -s emulator-5554 logcat -d >logcat.txt || true
fi
exit "$status"
