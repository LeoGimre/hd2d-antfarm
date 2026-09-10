#!/usr/bin/env bash
# tick.sh — run exactly one antfarm tick in a fresh Claude session.
#
# A fresh session per tick is the whole survival strategy: continuity lives on
# disk (STATE.md, ROADMAP.md, design/, JOURNAL.jsonl, git log), never in a
# context window. That makes runtime unbounded and context bounded, and it means
# a wedged tick can be killed without poisoning the run.
#
# Exit codes are how run.sh tells the three outcomes apart:
#   0   the tick ran
#   42  a usage limit blocked it — it never got to work; resume time is in
#       farm/logs/.resume_at
#   1   anything else went wrong
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE="${CLAUDE_BIN:-claude}"
TIMEOUT="${TICK_TIMEOUT:-2700}"
LOGDIR="$ROOT/farm/logs"
RESUME_AT="$LOGDIR/.resume_at"
mkdir -p "$LOGDIR"

N=$(printf '%04d' "$(( $(ls "$LOGDIR"/tick-*.json 2>/dev/null | wc -l | tr -d ' ') + 1 ))")
OUT="$LOGDIR/tick-$N.json"
ERR="$LOGDIR/tick-$N.err"

echo "[$(date '+%H:%M:%S')] tick $N starting (timeout ${TIMEOUT}s)"

cd "$ROOT"
"$CLAUDE" -p "/antfarm-tick" \
  --permission-mode acceptEdits \
  --output-format json \
  --max-turns 300 \
  >"$OUT" 2>"$ERR" &
pid=$!

# macOS has no coreutils `timeout`, so run our own watchdog.
( sleep "$TIMEOUT"; kill -TERM "$pid" 2>/dev/null ) &
watchdog=$!

wait "$pid"
kill "$watchdog" 2>/dev/null; wait "$watchdog" 2>/dev/null

# The CLI's exit code does not distinguish "hit a usage limit" from "broke".
# Both are non-zero, and a limit even reports subtype "success". Classify from
# the payload instead.
verdict=$(python3 "$ROOT/farm/limit.py" "$OUT")
kind=${verdict%%|*}
rest=${verdict#*|}

case "$kind" in
  OK)
    cost=${rest%%|*}; rest=${rest#*|}
    turns=${rest%%|*}; summary=${rest#*|}
    echo "$cost" >>"$LOGDIR/cost.log"
    printf '  cost $%s  turns %s\n' "$cost" "$turns"
    [ -n "$summary" ] && echo "  ${summary:0:200}"
    echo "[$(date '+%H:%M:%S')] tick $N done"
    exit 0
    ;;
  LIMIT)
    epoch=${rest%%|*}; rest=${rest#*|}
    human=${rest%%|*}; message=${rest#*|}
    echo "$epoch" >"$RESUME_AT"
    echo "  usage limit — $message"
    echo "[$(date '+%H:%M:%S')] tick $N blocked (resets $human); not counted"
    exit 42
    ;;
  *)
    echo "  $rest"
    [ -s "$ERR" ] && tail -5 "$ERR" >&2
    echo "[$(date '+%H:%M:%S')] tick $N failed"
    exit 1
    ;;
esac
