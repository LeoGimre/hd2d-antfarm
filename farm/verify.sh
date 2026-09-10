#!/usr/bin/env bash
# verify.sh — the hard gate. Nothing gets committed unless this exits 0.
#
# Three checks:
#   1. every asset imports
#   2. every GDScript parses (a broken .gd is silent until the scene loads)
#   3. the main scene actually boots and runs for a moment without erroring
#
# Godot's headless renderer leaks dummy resources on exit and shouts about it.
# Those messages are unconditional and unrelated to project health, so they are
# filtered rather than treated as failures — but the filter is deliberately
# narrow, so a real error still fails the gate.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
SMOKE_FRAMES="${SMOKE_FRAMES:-180}"
LOG="$ROOT/farm/logs/verify.log"
mkdir -p "$(dirname "$LOG")"

BENIGN='Pages in use exist at exit|leaked at exit|resources still in use at exit|Leaked instance dependency|did not call instance_notify_deleted|Godot 3\.x SpatialMaterial'

fail() { echo "verify: FAIL — $1" >&2; exit 1; }

real_errors() {
  grep -E '(^| )(ERROR|SCRIPT ERROR|USER ERROR|Parse Error|Failed loading)' "$1" \
    | grep -vE "$BENIGN" || true
}

echo "verify: importing assets"
"$GODOT" --headless --path "$ROOT/game" --import >"$LOG" 2>&1
[ -n "$(real_errors "$LOG")" ] && { real_errors "$LOG" | head -20 >&2; fail "asset import produced errors"; }

echo "verify: parsing scripts"
# --check-only compiles a script without running it; do every .gd in the project.
while IFS= read -r gd; do
  rel="res://${gd#"$ROOT/game/"}"
  "$GODOT" --headless --path "$ROOT/game" --check-only --script "$rel" >"$LOG.parse" 2>&1
  if [ -n "$(real_errors "$LOG.parse")" ]; then
    echo "--- $rel ---" >&2
    real_errors "$LOG.parse" | head -10 >&2
    fail "$rel does not parse"
  fi
done < <(find "$ROOT/game" -name '*.gd' -not -path '*/.godot/*')

echo "verify: smoke-running the main scene"
"$GODOT" --headless --path "$ROOT/game" --quit-after "$SMOKE_FRAMES" >"$LOG.smoke" 2>&1
code=$?
if [ -n "$(real_errors "$LOG.smoke")" ]; then
  real_errors "$LOG.smoke" | head -20 >&2
  fail "main scene errored while running"
fi
# Godot's exit code on a clean --quit-after is 0; anything else is a crash.
[ "$code" -ne 0 ] && fail "main scene exited $code"

echo "verify: OK"
exit 0
