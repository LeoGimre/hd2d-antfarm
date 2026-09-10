#!/usr/bin/env bash
# tick.sh — run exactly one antfarm tick in a fresh Claude session.
#
# A fresh session per tick is the whole survival strategy: continuity lives on
# disk (STATE.md, ROADMAP.md, design/, JOURNAL.jsonl, git log), never in a
# context window. That makes runtime unbounded and context bounded, and it means
# a wedged tick can be killed without poisoning the run.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE="${CLAUDE_BIN:-claude}"
TIMEOUT="${TICK_TIMEOUT:-1800}"
LOGDIR="$ROOT/farm/logs"
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

wait "$pid"; code=$?
kill "$watchdog" 2>/dev/null; wait "$watchdog" 2>/dev/null

if [ $code -ne 0 ]; then
  echo "[$(date '+%H:%M:%S')] tick $N exited $code"
  tail -5 "$ERR" >&2 2>/dev/null
  exit $code
fi

# Surface cost and the closing summary so run.sh can budget and the operator can skim.
python3 - "$OUT" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception as e:
    print(f"  (unparseable tick output: {e})")
    sys.exit(0)
cost = d.get("total_cost_usd")
turns = d.get("num_turns")
result = (d.get("result") or "").strip().replace("\n", " ")
if cost is not None:
    print(f"  cost ${cost:.4f}  turns {turns}")
    with open(__import__("os").path.join(__import__("os").path.dirname(sys.argv[1]), "cost.log"), "a") as f:
        f.write(f"{cost}\n")
if result:
    print(f"  {result[:220]}")
PY

echo "[$(date '+%H:%M:%S')] tick $N done"
