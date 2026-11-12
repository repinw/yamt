#!/usr/bin/env bash
# Runs a command in one of two test slots, so at most two sessions on this
# PC run Flutter tests at the same time. Takes whichever slot is free, else
# waits until one frees up, then runs the command once and returns its exit
# code.
#
#   tool/test_slot.sh rtk test flutter test -j 1 -d flutter-tester <paths>
#
# Slot 1 is the lock file of the former one-run lock
# (`flock -o ~/.cache/yamt-flutter-test.lock …`), so runs that still use that
# command count as slot 1.
set -uo pipefail

if (($# == 0)); then
  echo "usage: tool/test_slot.sh <command> [args…]" >&2
  exit 64
fi

lock_dir=${YAMT_TEST_LOCK_DIR:-$HOME/.cache}
slots=("$lock_dir/yamt-flutter-test.lock" "$lock_dir/yamt-flutter-test-2.lock")
mkdir -p "$lock_dir"

# The lock stays on this shell's descriptor. The command runs without it
# (like `flock -o`), so a daemon it leaves behind cannot keep the slot.
take_slot() {
  local slot
  for slot in "${slots[@]}"; do
    if ! exec {lock_fd}>>"$slot"; then
      echo "test_slot: cannot open lock file $slot" >&2
      exit 69
    fi
    if flock -n "$lock_fd"; then
      return 0
    fi
    exec {lock_fd}>&-
  done
  return 1
}

announced=
until take_slot; do
  if [[ -z $announced ]]; then
    echo "test_slot: both test slots are busy, waiting…" >&2
    announced=1
  fi
  sleep 1
done

# The trap is set before the start, so a signal never leaves the command
# running without its slot. `<&0` keeps stdin, which bash would otherwise
# replace with /dev/null for a background command.
child=
trap '[[ -n $child ]] && kill -TERM "$child" 2>/dev/null' TERM INT HUP
"$@" <&0 {lock_fd}>&- &
child=$!

# `wait` returns early when a trapped signal arrives; wait again for the
# command's own exit code.
wait "$child"
status=$?
while kill -0 "$child" 2>/dev/null; do
  wait "$child"
  status=$?
done
exit "$status"
