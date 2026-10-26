#!/usr/bin/env bash
# Prints a POSIX TZ value like Europe/Berlin (UTC+1, +2 in summer) whose
# clock change falls on today plus <offset> days, so tests that run today
# meet the change at any time of the year.
#
#   tool/clock_change_tz.sh fall -1   # yesterday had 25 hours
#   tool/clock_change_tz.sh spring 0  # today has 23 hours
set -euo pipefail

kind=$1
offset=$2

# Day of the year in the POSIX Jn form, which never counts 29 February.
# shortcut: a change day on 29 February lands on 1 March; fine for a test run.
julian() {
  local date year day month
  date=$(TZ=$run_zone date -d "today $1 days" +%Y-%j-%m)
  IFS=- read -r year day month <<<"$date"
  day=$((10#$day))
  if ((10#$month > 2)) && date -d "$year-02-29" >/dev/null 2>&1; then
    day=$((day - 1))
  fi
  echo "$day"
}

# The tests count today in the generated zone, so today is taken at the
# offset that zone has on the run day: summer time (UTC+2) while its change
# is still ahead for fall or already behind for spring, else winter time.
if [[ $kind == fall && $offset -ge 1 || $kind == spring && $offset -le 0 ]]; then
  run_zone=UTC-2
else
  run_zone=UTC-1
fi

change=$(julian "$offset")
case "$kind" in
  # Summer time ends on the change day, so that day has 25 hours.
  fall) echo "CET-1CEST,J$(julian $((offset - 150)))/2,J$change/3" ;;
  # Summer time starts on the change day, so that day has 23 hours.
  spring) echo "CET-1CEST,J$change/2,J$(julian $((offset + 150)))/3" ;;
  *)
    echo "usage: $0 fall|spring <day offset>" >&2
    exit 64
    ;;
esac
