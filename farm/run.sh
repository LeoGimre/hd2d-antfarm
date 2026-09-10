#!/usr/bin/env bash
# run.sh — the antfarm runner. Ticks until told to stop.
#
#   farm/run.sh                   # run until state/STOP appears
#   MAX_TICKS=200 farm/run.sh     # or until a tick budget is spent
#   BUDGET_USD=50 farm/run.sh     # or until a dollar budget is spent
#
# Capture needs a real rendering context, so this must run inside a logged-in
# GUI session. Wrap it in caffeinate so the Mac does not sleep mid-clip:
#   MAX_TICKS=200 caffeinate -dims farm/run.sh
#
# To stop it: touch state/STOP
#
# Usage limits are expected, not exceptional. A blocked tick never got to work,
# so it does not count against MAX_TICKS and does not trigger failure backoff —
# the runner simply sleeps until the window resets and picks up where it was.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COOLDOWN="${COOLDOWN:-60}"
FAIL_BACKOFF="${FAIL_BACKOFF:-300}"
MAX_TICKS="${MAX_TICKS:-0}"          # 0 = unlimited
BUDGET_USD="${BUDGET_USD:-0}"        # 0 = unlimited
MAX_FAILS="${MAX_FAILS:-5}"          # consecutive real failures before giving up
MIN_LIMIT_WAIT="${MIN_LIMIT_WAIT:-60}"       # floor on a usage-limit sleep
LIMIT_BACKOFF_BASE="${LIMIT_BACKOFF_BASE:-900}"  # escalation base for repeat limits
LIMIT_BACKOFF_MAX="${LIMIT_BACKOFF_MAX:-14400}"  # ...and its ceiling
STOP="$ROOT/state/STOP"
LOGDIR="$ROOT/farm/logs"
COSTLOG="$LOGDIR/cost.log"
RESUME_AT="$LOGDIR/.resume_at"
# Overridable so the runner's decision logic can be exercised without
# spending real ticks on it.
TICK_CMD="${TICK_CMD:-$ROOT/farm/tick.sh}"
# As an array, so the default single path survives spaces in $ROOT while a
# test can still pass something like "bash /tmp/faketick.sh".
if [ "$TICK_CMD" = "$ROOT/farm/tick.sh" ]; then
  TICK_ARGV=("$TICK_CMD")
else
  read -r -a TICK_ARGV <<<"$TICK_CMD"
fi

fmt_dur() {
  local s="$1"
  if   [ "$s" -lt 60 ];   then echo "${s}s"
  elif [ "$s" -lt 3600 ]; then echo "$((s / 60))m"
  else echo "$((s / 3600))h$(printf '%02d' $(((s % 3600) / 60)))m"
  fi
}

spent() {
  [ -f "$COSTLOG" ] || { echo 0; return; }
  awk '{s+=$1} END {printf "%.4f", s+0}' "$COSTLOG"
}

# Sleep in short steps so `touch state/STOP` lands promptly even mid-wait.
# Returns 1 if it was interrupted by STOP.
nap() {
  local total="$1" label="${2:-}" slept=0 step=5
  [ "$total" -le 0 ] && return 0
  [ "$total" -lt 30 ] && step=1
  [ -n "$label" ] && echo "run: $label"
  while [ "$slept" -lt "$total" ]; do
    if [ -f "$STOP" ]; then
      echo "run: STOP found while waiting"
      return 1
    fi
    sleep "$step"
    slept=$((slept + step))
  done
  return 0
}

if [ -f "$STOP" ]; then
  echo "run: state/STOP exists — remove it to start."
  exit 0
fi

mkdir -p "$LOGDIR"
started=$(date +%s)
echo "run: antfarm starting"
echo "run: cooldown ${COOLDOWN}s | max ticks $([ "$MAX_TICKS" -gt 0 ] && echo "$MAX_TICKS" || echo unlimited) | budget \$${BUDGET_USD}"
echo "run: stop with  touch state/STOP"

n=0            # ticks that actually ran
blocked=0      # times a usage limit sent us to sleep
fails=0        # consecutive real failures
limit_streak=0 # consecutive limits, to escalate if a reset time was optimistic

while true; do
  [ -f "$STOP" ] && { echo "run: STOP found — halting"; break; }

  if [ "$MAX_TICKS" -gt 0 ] && [ "$n" -ge "$MAX_TICKS" ]; then
    echo "run: reached MAX_TICKS=$MAX_TICKS — halting"
    break
  fi

  if awk "BEGIN {exit !($BUDGET_USD > 0)}"; then
    used=$(spent)
    if awk "BEGIN {exit !($used >= $BUDGET_USD)}"; then
      echo "run: spent \$$used of \$$BUDGET_USD budget — halting"
      break
    fi
  fi

  "${TICK_ARGV[@]}"
  code=$?

  case $code in
    0)
      n=$((n + 1)); fails=0; limit_streak=0
      nap "$COOLDOWN" || break
      ;;

    42)
      # Blocked by a usage limit. Not a tick, not a failure.
      blocked=$((blocked + 1))
      limit_streak=$((limit_streak + 1))
      fails=0

      now=$(date +%s)
      target=$(cat "$RESUME_AT" 2>/dev/null || echo 0)
      wait_for=$(( target - now ))
      [ "$wait_for" -lt "$MIN_LIMIT_WAIT" ] && wait_for=$MIN_LIMIT_WAIT

      # If the stated reset time keeps proving optimistic, back off harder
      # rather than hammering the limit every couple of minutes.
      if [ "$limit_streak" -gt 1 ]; then
        escalated=$(( LIMIT_BACKOFF_BASE * (1 << (limit_streak - 2)) ))
        [ "$escalated" -gt "$LIMIT_BACKOFF_MAX" ] && escalated=$LIMIT_BACKOFF_MAX
        [ "$escalated" -gt "$wait_for" ] && wait_for=$escalated
      fi

      resume_at=$(date -r "$(( now + wait_for ))" '+%H:%M' 2>/dev/null || echo "?")
      nap "$wait_for" "usage limit — sleeping $(fmt_dur "$wait_for"), resuming ~${resume_at} (block #$blocked)" || break
      ;;

    *)
      fails=$((fails + 1)); limit_streak=0
      n=$((n + 1))
      if [ "$fails" -ge "$MAX_FAILS" ]; then
        echo "run: $fails consecutive failures — halting so someone can look"
        break
      fi
      nap "$FAIL_BACKOFF" "tick failed ($fails/$MAX_FAILS) — backing off $(fmt_dur "$FAIL_BACKOFF")" || break
      ;;
  esac
done

elapsed=$(( $(date +%s) - started ))
printf 'run: stopped after %d tick(s), %d limit wait(s), %dh%02dm elapsed; total spend $%s\n' \
  "$n" "$blocked" "$((elapsed / 3600))" "$(((elapsed % 3600) / 60))" "$(spent)"
