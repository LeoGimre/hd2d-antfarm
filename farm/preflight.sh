#!/usr/bin/env bash
# preflight.sh — is the antfarm ready to run unattended?
#
# Reports every prerequisite with the exact command to fix it. Run it any time;
# it changes nothing.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
ok=0; bad=0

pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; ok=$((ok+1)); }
fail() { printf '  \033[31m✗\033[0m %-34s %s\n' "$1" "$2"; bad=$((bad+1)); }

echo "antfarm preflight"
echo
echo "toolchain"
[ -x "$GODOT" ]            && pass "godot $($GODOT --version 2>/dev/null | head -1)" || fail "godot"  "brew install --cask godot"
command -v ffmpeg >/dev/null && pass "ffmpeg $(ffmpeg -version 2>/dev/null | head -1 | cut -d' ' -f3)" || fail "ffmpeg" "brew install ffmpeg"
command -v node   >/dev/null && pass "node $(node -v)"                              || fail "node"   "brew install node"
command -v claude >/dev/null && pass "claude $(claude --version 2>/dev/null)"        || fail "claude" "npm i -g @anthropic-ai/claude-code"
command -v gh     >/dev/null && pass "gh $(gh --version 2>/dev/null | head -1 | cut -d' ' -f3)" || fail "gh" "brew install gh"

echo
echo "credentials"
# Do not test this with the exit code: `claude -p` exits non-zero for plenty of
# reasons that have nothing to do with auth (max turns, a denied tool). Look for
# what an unauthenticated CLI actually says instead.
probe=$(claude -p "reply with the single word ok" --max-turns 3 2>&1)
if grep -qiE "not logged in|please run /login|invalid api key|authentication_error" <<<"$probe"; then
  fail "claude not logged in" "run 'claude' once, then /login"
else
  pass "claude logged in"
fi
gh auth status >/dev/null 2>&1 && pass "gh authenticated" || fail "gh not authenticated" "gh auth login"
if [ -f "$ROOT/farm/.env" ] && grep -q AWS_ACCESS_KEY_ID "$ROOT/farm/.env" 2>/dev/null; then
  pass "storage credentials in farm/.env"
else
  fail "no storage credentials" "neon auth && neon env pull --file farm/.env"
fi

echo
echo "repo"
git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 && pass "git repo" || fail "not a git repo" "git init"
if git -C "$ROOT" remote get-url origin >/dev/null 2>&1; then
  pass "remote: $(git -C "$ROOT" remote get-url origin)"
else
  fail "no git remote" "gh repo create hd2d-antfarm --public --source=. --push"
fi
[ -f "$ROOT/state/STOP" ] && fail "state/STOP present" "rm state/STOP  (the loop refuses to start)" \
                          || pass "no stop file"

echo
echo "pipeline"
[ -x "$ROOT/farm/verify.sh" ]  && pass "verify.sh"  || fail "verify.sh not executable"  "chmod +x farm/verify.sh"
[ -x "$ROOT/farm/capture.sh" ] && pass "capture.sh" || fail "capture.sh not executable" "chmod +x farm/capture.sh"
node "$ROOT/site/build.mjs" >/dev/null 2>&1 && pass "site builds" || fail "site build fails" "node site/build.mjs"

echo
if [ $bad -eq 0 ]; then
  printf '\033[32mready\033[0m — %d checks passed. Start with:  caffeinate -dims farm/run.sh\n' "$ok"
  exit 0
fi
printf '\033[33m%d of %d checks failed\033[0m — fix the commands above, then re-run preflight.\n' "$bad" "$((ok+bad))"
exit 1
