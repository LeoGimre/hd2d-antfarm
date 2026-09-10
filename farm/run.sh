#!/usr/bin/env bash
# run.sh — the antfarm runner. Ticks until told to stop.
#
#   farm/run.sh                 # run until state/STOP appears
#   MAX_TICKS=5 farm/run.sh     # or until a tick budget is spent
#   BUDGET_USD=20 farm/run.sh   # or until a dollar budget is spent
#
# Capture needs a real rendering context, so this must run inside a logged-in
# GUI session. Wrap it in caffeinate so the Mac does not sleep mid-clip:
#   caffeinate -dims farm/run.sh
#
# To stop it: touch state/STOP
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COOLDOWN="${COOLDOWN:-60}"
FAIL_BACKOFF="${FAIL_BACKOFF:-300}"
MAX_TICKS="${MAX_TICKS:-0}"          # 0 = unlimited
BUDGET_USD="${BUDGET_USD:-0}"        # 0 = unlimited
STOP="$ROOT/state/STOP"
COSTLOG="$ROOT/farm/logs/cost.log"

spent() {
  [ -f "$COSTLOG" ] || { echo 0; return; }
  awk '{s+=$1} END {printf "%.4f", s+0}' "$COSTLOG"
}

if [ -f "$STOP" ]; then
  echo "run: state/STOP exists — remove it to start."
  exit 0
fi

echo "run: antfarm starting"
echo "run: cooldown ${COOLDOWN}s | max ticks ${MAX_TICKS:-unlimited} | budget \$${BUDGET_USD}"
echo "run: stop with  touch state/STOP"

n=0
while true; do
  if [ -f "$STOP" ]; then
    echo "run: STOP found — halting before tick $((n + 1))"
    break
  fi

  if [ "$MAX_TICKS" -gt 0 ] && [ "$n" -ge "$MAX_TICKS" ]; then
    echo "run: reached MAX_TICKS=$MAX_TICKS — halting"
    break
  fi

  if [ "$(echo "$BUDGET_USD" | cut -d. -f1)" -gt 0 ] 2>/dev/null; then
    used=$(spent)
    if awk "BEGIN {exit !($used >= $BUDGET_USD)}"; then
      echo "run: spent \$$used of \$$BUDGET_USD budget — halting"
      break
    fi
  fi

  n=$((n + 1))
  if "$ROOT/farm/tick.sh"; then
    sleep_for="$COOLDOWN"
  else
    echo "run: tick failed — backing off ${FAIL_BACKOFF}s"
    sleep_for="$FAIL_BACKOFF"
  fi

  # Check STOP again during the cooldown so a stop lands promptly.
  slept=0
  while [ "$slept" -lt "$sleep_for" ]; do
    [ -f "$STOP" ] && break
    sleep 5
    slept=$((slept + 5))
  done
done

echo "run: stopped after $n tick(s); total spend \$$(spent)"
