# STATE.md — the loop's working memory

Rewritten by the loop at the end of every tick. This is how a fresh session picks up where the last
one left off. Keep it short: it is read every tick, so bloat here costs tokens forever.

## Current milestone
M2 — Traversal is **done**. M3 — First blood is open; its first three boxes (combat design pitch,
battle scene with turn order, four data-driven creatures) are done as of tick 7. Player input landed
in tick 8, but the fourth box itself is still unticked — see Current focus.

## Current focus
**M3's fourth box is still open: retune numbers (or AI/target logic) until the "correct" line
reliably beats the "naive" one.** Player input now exists (tick 8) — the player picks move, target,
Swap and Charge on their own turns — but running `design/combat.md`'s own worked example through a
scripted line found the opposite of what the doc predicts: naive front-stacking (always melee,
always Front, no Charge, no retargeting) beat a "correct" line that fixed targeting (both player
creatures focus Galewing, the good matchup, instead of Tidalpup) but never swapped Emberling out of
Front once its matchup turned bad. Score was close (enemy won with Tidalpup at 5/32 HP) but still a
loss. Next tick should either script a swap-aware "correct" line to see if that's enough, or, if
not, retune Guard size / Back penalty / Charge power per combat.md's own instruction ("the numbers,
not the shape of the systems, are what to retune"). Unit tests for `CombatResolver`/`TypeChart` are
still the box *after* this one — don't build them until this one reliably passes.

## Open blockers
None.

## Recent decisions
- **Player input on the player's own turns** (tick 8): picked up a previous tick's interrupted work
  (found already built in the working tree on arrival — read it, ran it, verified it, finished the
  job rather than redoing it). `battle.gd` now stops its timer on a `PlayerFront`/`PlayerBack` turn
  and polls `Input.is_action_just_pressed()` for move choice (`battle_move_1`/`_2`), Swap
  (`battle_swap`), Charge toggle (`battle_charge`), and ranged target (`battle_target_front`/
  `_back`) — polled rather than `_unhandled_input`-routed because demo/test scripts drive input via
  `Input.action_press()`/`action_release()`, which only updates polled state. `CombatantState` now
  carries its own `speed` (not looked up by slot) so Swap can hand the turn queue the swapped-in
  creature's cadence via `TurnQueue.rename()`. `_check_battle_over()` finally gives a battle a real
  end — nothing did before this tick. `battle_demo.gd` had to be updated in the same tick: its
  premise ("nothing for a demo script to drive") broke the moment player turns started waiting on
  input, so it now synthesizes the same move/target presses a real player would. See
  `devlog/0009-player-input.md` for the naive-vs-correct test results (see Current focus above).
  A headless scratch harness (`game/tools/_scratch_battle_test.gd`) is the fast way to check a line
  without opening a window — drives `battle.tscn` via a `SceneTree` script, synthesizes input the
  same way the demo does, prints the combat log. **Never commit it** (delete it at tick end if `rm`
  is available; if not — this environment sometimes denies `rm` outright — just don't `git add` it,
  `git add -A` will vacuum it in so add specific paths instead).
- **Four data-driven creatures** (tick 7): `game/data/{creatures,moves,types}.json` hold M3's real
  roster — Emberling/Tidalpup/Galewing/Rootshell in a four-type cycle (Ember → Root → Gale → Tide →
  Ember), two moves each (one melee, one ranged). `CreatureDB`/`TypeChart` (`game/scripts/`) just
  look this data up; `CombatantState` holds one creature's runtime HP/Guard/Broken state;
  `CombatResolver` is a pure static-method class that turns an attack into HP/Guard damage, Charge
  gain, and Broken transitions — deliberately free of any Node/scene reference since unit tests are
  the next-but-one M3 box. `battle.gd` and `build_battle.gd` share a `TEAM` table (creature id +
  slot) so the generated scene and the runtime logic can't disagree on who stands where. Regenerating
  the scene needed a second lighting pass: tick 6's rim-light intensity and Back-slot lateral offset
  were tuned around blank placeholder capsules, and blew out or partially hid the new two-line
  HP/Guard InfoLabels once Back carried real stats to read — only visible in the QC stills, not from
  the numbers. No player input yet — every combatant, both sides, picks its own move/target; that's
  deliberately the next box, not this one.
- **Battle scene: turn queue + Front/Back board** (tick 6): `game/scripts/turn_queue.gd`
  (`TurnQueue`, the project's first `class_name`) implements combat.md's deterministic
  `scheduled_time = 1000/Speed` formula, split into `advance()` (mutates real state, commits one
  turn) and `preview(n)` (simulates the next n turns on a scratch copy, used by the on-screen
  strip). All four Front/Back slot markers are always rendered regardless of occupancy — the
  board's claim is "two slots exist," not "both are full."
- **Combat design pitch** (tick 5): `design/combat.md` decides M3's core loop — a deterministic
  speed-ordered turn queue rendered as a visible strip, two-slot Front/Back position (melee locked
  to Front, ranged discounted vs Back, Swap costs a full turn), and a Guard/Charge economy
  (type-effective hits crack Guard faster, breaking a creature banks a Charge spendable on a
  burst-empowered move). Capture and bonds-with-memory are explicitly deferred to M4.
- **A solid `CylinderMesh` has no hollow interior.** Applies to any future prop wanting a visible
  recessed/embedded surface: either give the container mesh an actual cavity, or sit the inset
  proud, not sunk.
- **`CrateA`'s world position is load-bearing** — `traversal_demo.gd`'s collision-bump beat is
  tuned around it. Any future set dressing near it must be placed clear, not moved into it.
- `farm/publish.py <slug>` with no file args only looks in `farm/out/<slug>/`. If the demo used for
  capture has a different name than the devlog slug, pass the file paths explicitly:
  `farm/publish.py <slug> farm/out/<demo>/clip.mp4 farm/out/<demo>/clip.webm farm/out/<demo>/poster.jpg`.
- `farm/capture.sh`'s Movie Maker path drops/coalesces frames on long captures — keep captures in
  the 12–16s range, front-load what the tick needs to prove.
- Any node lookup by absolute path (`get_node("SomeName")`) is fragile against reparenting. Grep
  `game/tools/demos/` before renaming or reparenting a node other scripts reference.
- `_block()` in `build_diorama.gd` returns a solid `StaticBody3D`. A helper that wants to be
  walk-through needs its own path that skips `_block()`.
- Demo scripts with per-step scripted input durations must capture the active step's duration into
  a local var when the step starts, not compare elapsed time against `_steps[_step][1]` after
  `_step` has already advanced.
- Input map lives in code (`InputSetup` autoload), not `project.godot`'s `[input]` block.
- No gravity, no floor collision shape on the ground plane — movement is flat/top-down.
- **Always import assets (`godot --headless --import`) before running a `build_*.gd` tool.** Silent
  null-texture bug otherwise; verify.sh won't catch it.
- Scene files are generated from `game/tools/build_*.gd`, not hand-edited. Edit the builder,
  re-run it, commit both.
- Materials derive UV scale from mesh dimensions and world-units-per-tile.
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
8
