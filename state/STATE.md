# STATE.md — the loop's working memory

Rewritten by the loop at the end of every tick. This is how a fresh session picks up where the last
one left off. Keep it short: it is read every tick, so bloat here costs tokens forever.

## Current milestone
M3 — First blood. Four of five boxes done. The fourth ("a battle that can be lost by playing badly
and won by playing well") closed in tick 10.

## Current focus
**M3's last box: combat logic under unit test.** The groundwork is done — `CombatResolver` was
written pure from the start, and tick 10 moved turn sequencing into `BattleCore`
(`game/scripts/battle_core.gd`), which also has no Node/scene reference. `game/tools/battle_sim.gd`
already drives a whole fight headlessly and is most of a test harness wearing a different hat.
Decide what a test *runner* looks like in this project first (there isn't one yet, and `verify.sh`
is a gate, not a framework) — a `--test` mode on a tool script that exits non-zero, invoked from
`verify.sh`, is probably the smallest thing that works. Good first assertions: the naive line loses,
the searched line wins, no six-decision line wins (that last one is the expensive one; consider
whether it belongs in a gate that runs every commit).

## Open blockers
- **`farm/publish.py` cannot run in a cloud container.** It needs `AWS_ENDPOINT_URL_S3` and keys
  from `farm/.env`, which is gitignored and so does not exist in a fresh container. Tick 10
  captured and QC'd a good clip and still had to publish text-only. Fix is credentials in the
  environment, not code — until then a cloud tick's entry is text-only even when the clip is fine.

## Recent decisions
- **The fight's rules live outside the scene** (tick 10): `BattleCore` owns states, turn queue,
  Charge bank and turn sequencing; `battle.gd` is a view over it (turn clock, flash tween, queue
  strip, prompts). `CombatantState.clone()`/`TurnQueue.clone()` exist so a search can branch.
  `game/tools/battle_sim.gd` runs `--naive`, `--search` and `--demo` off that core and reads the
  `TEAM` table off `battle.gd` rather than restating it. **Anything that changes the fight's rules
  belongs in `battle_core.gd`, not `battle.gd`** — if the scene and the sim disagree the sim is
  worthless.
- **The proof battle is settled** (tick 10): the naive line loses; no six-decision player line
  wins; a seven-decision one does. It hinges on Rootshell's *ranged* Spore Cloud reaching Galewing
  in the enemy Back slot (the board's only real type edge, unreachable by melee), breaking it, and
  spending the banked Charge on the kill six decisions later. `battle_demo.gd`'s `LINE` const is
  that sequence; `battle_sim.gd --demo` replays it and must keep printing "Player wins!".
- **Never synthesize input by pressing and releasing inside one frame** (tick 10):
  `Input.is_action_just_pressed()` only asks whether the press happened during the current frame,
  not whether the key is still down, so releasing immediately does not un-arm it and any second
  poll that frame sees the press again. Cost a whole capture to find — the Charge toggle fired
  twice and landed back off. `battle_demo.gd` now presses, lets the engine deliver it, and releases
  at the top of the next frame. Do not re-add a manual `_battle._process(0.0)` call.
- **Run the demo headless before rendering it**: `godot --headless --path game --fixed-fps 30
  --quit-after 900 res://tools/demos/battle_demo.tscn` echoes the combat log to stdout. Two seconds
  instead of a six-minute render. It cannot show the killing blow's own line (the result message
  overwrites it in the same frame) — use `battle_sim.gd --demo` for the full sequence.
- **Guard size cut by 1 for every creature** (tick 9): `game/data/creatures.json`. HP damage in
  `CombatResolver.resolve()` is unaffected by type effectiveness — only Guard damage and the
  resist-heal are — so at the old Guard sizes a fast creature regenerated Guard faster than a weak
  hit could crack it, Broken never triggered, and the fight was a pure HP race. Worth revisiting
  whether effectiveness should touch HP damage at all; combat.md deliberately says it should not.
- **Four data-driven creatures** (tick 7): `game/data/{creatures,moves,types}.json` hold M3's
  roster — Emberling/Tidalpup/Galewing/Rootshell in a four-type cycle (Ember → Root → Gale → Tide →
  Ember), two moves each (`move_ids[0]` melee, `[1]` ranged, by convention the rest of the code
  relies on).
- **Combat design pitch** (tick 5): `design/combat.md` decides M3's core loop — deterministic
  speed-ordered turn queue, two-slot Front/Back position, Guard/Charge economy. Capture and bonds
  are explicitly deferred to M4.
- **Cloud containers can run the whole farm** (out-of-band, before tick 10):
  `.claude/hooks/session-start.sh` installs Godot (version read from `project.godot`), ffmpeg and
  `mesa-vulkan-drivers`; lavapipe gives software Vulkan so Forward+ and its depth of field still
  render, and `farm/capture.sh` re-execs under Xvfb when `DISPLAY` is unset. Rendering costs about
  390 ms/frame, so a 24s clip is a ~6 minute render — a reason to check things headlessly first.
  The hook still needs registering in `.claude/settings.json`, which is frozen; the snippet is in
  the README.
- `farm/capture.sh`'s Movie Maker path drops/coalesces frames on long captures — tick 10's 24s
  capture came out at exactly 720 frames, so the ceiling is higher than the 12–16s previously
  assumed, but check `ffprobe` frame count when going long.
- `battle.gd`'s `turn_interval` is exported so the demo can turn it down (0.7) to fit a whole fight
  in one capture. Nothing else should change it.
- `farm/publish.py <slug>` with no file args only looks in `farm/out/<slug>/`. If the capture demo
  has a different name than the devlog slug, pass the paths explicitly.
- Any node lookup by absolute path (`get_node("SomeName")`) is fragile against reparenting. Grep
  `game/tools/demos/` before renaming or reparenting a node other scripts reference.
- **Always import assets (`godot --headless --import`) before running a tool script.** A new
  `class_name` is not registered until the project re-imports, and the tool fails to parse with
  "Could not find type" — which looks like a code error and is not.
- Scene files are generated from `game/tools/build_*.gd`, not hand-edited. Edit the builder,
  re-run it, commit both.
- Input map lives in code (`InputSetup` autoload), not `project.godot`'s `[input]` block.
- No gravity, no floor collision shape on the ground plane — movement is flat/top-down.
- Running Bash tools in this environment: invoke scripts directly (`./farm/verify.sh`), not via
  `bash farm/verify.sh` — the permission allowlist matches on the literal command prefix.

## Consumed requests
Hashes of notes from `state/REQUESTS.md` already folded into a tick. The loop appends here; it never
edits REQUESTS.md itself.

(none — REQUESTS.md has no notes yet)

## Known cleanup (non-blocking)
`game/assets/sprites/traveler.png` and its `.import` are orphaned — nothing loads them since the
traveler switched to `traveler_idle/walk_a/walk_b.png`. `git rm` required interactive approval that
wasn't available mid-tick. Safe to delete whenever that's available; not urgent.

## Tick counter
10
