#!/usr/bin/env bash
# Runs one integration test on emulator-5554 with the APK that CI built
# before, for .github/workflows/ci.yml.
#
# flutter drive sometimes cannot connect to the app's VM Service through the
# adb port forward and retries forever, although the app runs. Each attempt
# therefore ends after 4 minutes. A timed-out attempt is retried; a test
# failure is not. On failure the device log is written to logcat.txt.
#
# The emulator sometimes goes offline during a run. flutter drive then fails
# with "Service has disappeared" or "device offline". In that case this
# script creates the file emulator-crashed, and the workflow runs the test
# again on a fresh emulator.
#
# Usage: tool/ci_integration_drive.sh <integration test file>
set -uo pipefail

target="$1"
apk=build/app/outputs/flutter-apk/app-debug.apk
log=drive.log

rm -f emulator-crashed

for attempt in 1 2 3; do
  timeout 4m flutter drive \
    --driver=test_driver/integration_test.dart \
    --target="$target" \
    --use-application-binary="$apk" \
    -d emulator-5554 2>&1 | tee "$log"
  status=${PIPESTATUS[0]}
  if [ "$status" -ne 124 ]; then
    break
  fi
  echo "flutter drive timed out on attempt $attempt." >&2
  pkill -f -- "--target=$target" || true
done

if [ "$status" -ne 0 ]; then
  state=$(timeout 10s adb -s emulator-5554 get-state 2>/dev/null || true)
  if [ "$state" != "device" ] ||
    grep -qE 'Service has disappeared|device offline' "$log"; then
    echo "The emulator went offline during the run (state: ${state:-none})." >&2
    touch emulator-crashed
  fi
  timeout 30s adb -s emulator-5554 logcat -d >logcat.txt || true
fi
exit "$status"
