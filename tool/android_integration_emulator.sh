#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

cd "${repo_root}"

avd_name="${AVD_NAME:-Pixel_9}"
device_id="${DEVICE_ID:-emulator-5554}"
snapshot_name="${SNAPSHOT_NAME:-yamt-clean-ready}"
app_id="${APP_ID:-de.yamt.app}"
driver="${DRIVER:-test_driver/integration_test.dart}"
target="${TARGET:-integration_test/calories/calorie_onboarding_visible_flow_test.dart}"
keep_emulator="${KEEP_EMULATOR:-0}"
emulator_log="${EMULATOR_LOG:-/tmp/yamt-android-emulator.log}"

emulator_bin="${EMULATOR_BIN:-${ANDROID_HOME:-${HOME}/Android/Sdk}/emulator/emulator}"
adb_bin="${ADB_BIN:-adb}"
flutter_bin="${FLUTTER_BIN:-flutter}"

started_emulator=0

usage() {
  cat <<USAGE
Usage:
  tool/android_integration_emulator.sh prepare-snapshot
  tool/android_integration_emulator.sh run [extra flutter drive args]

Environment:
  AVD_NAME       Android virtual device name. Default: Pixel_9
  DEVICE_ID      Device id used by adb/flutter. Default: emulator-5554
  SNAPSHOT_NAME  Clean ready snapshot name. Default: yamt-clean-ready
  APP_ID         App package removed before tests. Default: de.yamt.app
  TARGET         Integration test target. Default: ${target}
  DRIVER         Flutter drive driver. Default: ${driver}
  KEEP_EMULATOR  Set to 1 to leave an emulator started by this script running.
USAGE
}

cleanup() {
  if [[ "${started_emulator}" == "1" && "${keep_emulator}" != "1" ]]; then
    "${adb_bin}" -s "${device_id}" emu kill >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

device_is_running() {
  "${adb_bin}" -s "${device_id}" get-state >/dev/null 2>&1
}

start_emulator_from_snapshot() {
  echo "Starting ${avd_name} headless from snapshot ${snapshot_name}..."
  "${emulator_bin}" \
    "@${avd_name}" \
    -snapshot "${snapshot_name}" \
    -no-snapshot-save \
    -no-window \
    -gpu swiftshader_indirect \
    -no-audio \
    -no-boot-anim \
    >"${emulator_log}" 2>&1 &
  started_emulator=1
}

start_emulator_for_snapshot_creation() {
  echo "Starting ${avd_name} headless for clean snapshot creation..."
  "${emulator_bin}" \
    "@${avd_name}" \
    -no-snapshot-load \
    -no-snapshot-save \
    -no-window \
    -gpu swiftshader_indirect \
    -no-audio \
    -no-boot-anim \
    >"${emulator_log}" 2>&1 &
  started_emulator=1
}

wait_for_boot() {
  echo "Waiting for ${device_id} to boot..."
  "${adb_bin}" -s "${device_id}" wait-for-device

  local boot_completed=""
  for ((attempt = 1; attempt <= 180; attempt++)); do
    boot_completed="$(
      "${adb_bin}" -s "${device_id}" shell getprop sys.boot_completed \
        2>/dev/null | tr -d '\r'
    )"
    if [[ "${boot_completed}" == "1" ]]; then
      break
    fi
    sleep 1
  done

  if [[ "${boot_completed}" != "1" ]]; then
    echo "Emulator did not finish booting. Log: ${emulator_log}" >&2
    exit 1
  fi

  "${adb_bin}" -s "${device_id}" shell input keyevent KEYCODE_WAKEUP \
    >/dev/null 2>&1 || true
  "${adb_bin}" -s "${device_id}" shell wm dismiss-keyguard \
    >/dev/null 2>&1 || true
}

remove_app_packages() {
  for package_name in "${app_id}" "${app_id}.test"; do
    if "${adb_bin}" -s "${device_id}" uninstall "${package_name}" \
      >/dev/null 2>&1; then
      echo "Removed ${package_name}."
    else
      echo "${package_name} is not installed."
    fi
  done
}

prepare_snapshot() {
  if ! device_is_running; then
    start_emulator_for_snapshot_creation
  else
    echo "Using already running ${device_id}."
  fi

  wait_for_boot
  remove_app_packages
  "${adb_bin}" -s "${device_id}" shell input keyevent KEYCODE_HOME \
    >/dev/null 2>&1 || true

  echo "Saving snapshot ${snapshot_name}..."
  "${adb_bin}" -s "${device_id}" emu avd snapshot save "${snapshot_name}"
  echo "Snapshot ${snapshot_name} is ready without ${app_id} installed."
}

run_integration_test() {
  if ! device_is_running; then
    start_emulator_from_snapshot
  else
    echo "Using already running ${device_id}."
  fi

  wait_for_boot
  remove_app_packages

  "${flutter_bin}" drive \
    --driver="${driver}" \
    --target="${target}" \
    -d "${device_id}" \
    "$@"
}

command="${1:-run}"
if [[ "$#" -gt 0 ]]; then
  shift
fi

case "${command}" in
  prepare-snapshot)
    prepare_snapshot "$@"
    ;;
  run)
    run_integration_test "$@"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "Unknown command: ${command}" >&2
    usage >&2
    exit 2
    ;;
esac
