#!/usr/bin/env bash
# session-start.sh — make a Claude Code on the web container able to run the farm.
#
# The antfarm was built on a Mac: GODOT_BIN defaults to /Applications/Godot.app,
# FFMPEG_BIN to /opt/homebrew/bin/ffmpeg, and capture assumes a logged-in GUI
# session. A cloud container has none of that, so this hook assembles the same
# three things out of what a fresh Ubuntu image and the egress proxy can reach:
#
#   godot   — the official Linux build, matching the version in project.godot
#   ffmpeg  — apt
#   a GPU   — there isn't one. mesa-vulkan-drivers gives Godot lavapipe, a
#             software Vulkan device, which is enough to run Forward+ and so to
#             keep the depth of field the HD-2D pillar depends on. Xvfb supplies
#             the X display Movie Maker mode refuses to work without.
#
# This only installs and exports paths; farm/capture.sh finds Xvfb on its own.
set -euo pipefail

# A local Mac already has all of this, installed the way preflight.sh says.
[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
ENV_FILE="${CLAUDE_ENV_FILE:-/dev/null}"

# The engine version is not a constant worth maintaining in two places: the
# project declares it, and an editor that disagrees re-imports every asset.
VERSION="$(sed -n 's/.*config\/features=PackedStringArray("\([0-9.]*\)".*/\1/p' "$ROOT/game/project.godot")"
: "${VERSION:?could not read the Godot version out of game/project.godot}"

GODOT_DIR="/opt/godot/$VERSION"
GODOT_BIN="$GODOT_DIR/Godot_v$VERSION-stable_linux.x86_64"

echo "session-start: godot $VERSION + ffmpeg + software vulkan"

# Lavapipe's manifest is lvp_icd.json on Ubuntu and lvp_icd.x86_64.json on some
# other distributions, so glob it rather than naming one — a guard that never
# matches quietly turns every warm start back into a full apt run.
have_lavapipe() { compgen -G '/usr/share/vulkan/icd.d/lvp_icd*.json' >/dev/null; }

if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v xvfb-run >/dev/null 2>&1 || ! have_lavapipe; then
  export DEBIAN_FRONTEND=noninteractive
  # Third-party PPAs in the base image are blocked by the egress policy, which
  # makes apt-get update exit non-zero even though the Ubuntu archive itself is
  # reachable. Ignore that and let the install be the real check.
  apt-get update -qq || true
  apt-get install -y -qq --no-install-recommends ffmpeg xvfb mesa-vulkan-drivers
fi

# The container is snapshotted after this hook, so a warm start does nothing.
if [ ! -x "$GODOT_BIN" ]; then
  # godotengine.org is not on the egress allowlist. The GitHub release URL and
  # the release-assets.githubusercontent.com redirect it hands back both are.
  URL="https://github.com/godotengine/godot-builds/releases/download/$VERSION-stable/Godot_v$VERSION-stable_linux.x86_64.zip"
  ZIP="$(mktemp -d)/godot.zip"
  echo "session-start: downloading $URL"
  curl -fsSL --retry 3 --retry-delay 2 -o "$ZIP" "$URL"
  mkdir -p "$GODOT_DIR"
  unzip -o -q "$ZIP" -d "$GODOT_DIR"
  chmod +x "$GODOT_BIN"
fi

"$GODOT_BIN" --version

{
  echo "export GODOT_BIN=\"$GODOT_BIN\""
  echo "export FFMPEG_BIN=\"$(command -v ffmpeg)\""
} >> "$ENV_FILE"

echo "session-start: ready — farm/verify.sh and farm/capture.sh will find Godot"
