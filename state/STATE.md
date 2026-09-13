# STATE.md — the loop's working memory

Rewritten by the loop at the end of every tick. This is how a fresh session picks up where the last
one left off. Keep it short: it is read every tick, so bloat here costs tokens forever.

## Current milestone
M3 — First blood. Boxes 1–3 done. Box 4 (a battle that can be lost badly, won well) is **solved on
paper but not in the engine**; box 5 (combat logic under unit test) is untouched.

## Current focus
**Land the re-pairing from `design/first_blood_balance.md`, in-engine.** Tick 10 searched the proof
battle exhaustively off-engine and found that ticks 8 and 9 were chasing the wrong variable: no
stat and no resolver constant needs changing. The four creatures are paired onto the wrong sides.
The type chart is a four-cycle and the roster was split *along* it, so the player's only type
advantage points at Galewing — already resisted against the player's survivor, so the enemy it
least needs to kill. Every explainable line loses; random play wins 0.4%.

The fix: **Player Rootshell (Front) + Tidalpup (Back) vs Enemy Emberling (Front) + Galewing
(Back).** Every creature then has exactly one correct target and every correct target is diagonal,
so reaching it goes through the Front/Back reach rule. Naive loses; correct targeting wins with 34
HP left; correct targeting that never spends a banked Charge *loses by 10 HP* — the first time
Break/Charge has been load-bearing here. Skill gradient 100/80/59/36/8% as decisions are randomised.

Next tick with an engine, in order: (1) move the encounter out of the duplicated `const TEAM` in
`battle.gd` and `build_battle.gd` into `game/data/encounters.json` — who fights whom is content, and
right now changing it is a two-file code edit against pillar 1; (2) apply the new pairing;
(3) re-run both lines and confirm the model (the doc lists the exact `battle_*` input sequences —
6 decisions to win, 3 to lose); (4) drop `TURN_INTERVAL` to ~0.85 so the 16-event fight fits a
12–16s capture; (5) then tick box 4. Box 5's unit tests come after.

## Open blockers
**No Godot in the container.** `verify.sh` fails at the smoke stage with exit 127 —
`/Applications/Godot.app/...` does not exist here and `curl`/`wget` are denied, so it cannot be
installed. If a tick sees exit 127, it is running in the remote container and not on Leo's Mac:
**nothing in `game/` may be committed.** Do design, devlog or `site/` work instead; both remaining
M3 boxes have real off-engine work available (see above). Note the first two verify stages pass
vacuously when the binary is missing — only the smoke stage catches it.

## Recent decisions
- **The proof battle was solved exhaustively off-engine** (tick 10): a port of `TurnQueue` +
  `battle.gd`'s turn loop + `CombatResolver`, validated by reproducing tick 9's committed naive
  result move for move (16 consecutive events, Galewing untouched at 24/24). Watch GDScript's
  `round()` — halves away from zero, where Python rounds half to even; `int(round(4.5))` is 5 in
  the engine and 4 in naive Python, which is worth real damage. Findings in
  `design/first_blood_balance.md`; `design/combat.md` now points at it.
- **HP damage is type-blind and that is deliberate**, per combat.md: effectiveness reaches Guard
  damage and the resist heal only, so a resisted hit lands for full HP. The re-pairing makes the
  fight work without touching it. Do not "fix" it pre-emptively.
- **Swap is unproven, not disproven.** Every scripted swap-first line lost and the searcher never
  used one, but the heuristics behind them were crude. Revisit when M4 gives Swap more than one
  possible partner.
- **Guard size cut by 1 for every creature** (tick 9): `max_guard` 3→2 for Emberling/Tidalpup/
  Galewing, 4→3 for Rootshell. Still correct — at the old sizes a fast creature regenerated Guard
  faster than a weak hit could crack it, so nothing ever Broke and Guard/Charge never engaged.
- **Player input on the player's own turns** (tick 8): `battle.gd` stops its timer on a
  `PlayerFront`/`PlayerBack` turn and *polls* `Input.is_action_just_pressed()` — polled rather than
  `_unhandled_input`-routed because demo/test scripts drive input via `Input.action_press()`, which
  only updates polled state. `CombatantState` carries its own `speed` so Swap can hand the queue the
  swapped-in creature's cadence via `TurnQueue.rename()`.
- **Four data-driven creatures** (tick 7): `game/data/{creatures,moves,types}.json` hold M3's roster
  in a four-type cycle (Ember → Root → Gale → Tide → Ember), two moves each. `CreatureDB`/`TypeChart`
  only look data up; `CombatResolver` is pure static methods with no Node reference, so box 5's unit
  tests are cheap when they come.
- **`CrateA`'s world position is load-bearing** — `traversal_demo.gd`'s collision-bump beat is tuned
  around it. Place new set dressing clear of it, never into it.
- `farm/publish.py <slug>` with no file args only looks in `farm/out/<slug>/`. If the capture demo's
  name differs from the devlog slug, pass paths explicitly.
- `farm/capture.sh`'s Movie Maker path drops frames on long captures — keep captures 12–16s and
  front-load what the tick needs to prove.
- Any node lookup by absolute path (`get_node("SomeName")`) is fragile against reparenting. Grep
  `game/tools/demos/` before renaming or reparenting a referenced node.
- `_block()` in `build_diorama.gd` returns a solid `StaticBody3D`; a walk-through helper needs its
  own path that skips it. A solid `CylinderMesh` has no hollow interior — sit an inset proud, not sunk.
- Demo scripts with per-step scripted input must capture the active step's duration into a local when
  the step starts, not read `_steps[_step][1]` after `_step` has advanced.
- Input map lives in code (`InputSetup` autoload), not `project.godot`'s `[input]` block.
- No gravity, no floor collision shape on the ground plane — movement is flat/top-down.
- **Always import assets (`godot --headless --import`) before running a `build_*.gd` tool.** Silent
  null-texture bug otherwise; verify.sh won't catch it.
- Scene files are generated from `game/tools/build_*.gd`, not hand-edited. Edit the builder, re-run
  it, commit both. Materials derive UV scale from mesh dimensions and world-units-per-tile.
- Run scripts directly (`./farm/verify.sh`), not via `bash farm/verify.sh` — the permission allowlist
  matches on the literal command prefix.

## Consumed requests
Hashes of notes from `state/REQUESTS.md` already folded into a tick. The loop appends here; it never
edits REQUESTS.md itself.

(none — REQUESTS.md has no notes yet)

## Known cleanup (non-blocking)
`game/assets/sprites/traveler.png` and its `.import` are orphaned — nothing loads them since the
traveler switched to `traveler_idle/walk_a/walk_b.png`. `rm`/`git rm` are denied by the allowlist, so
this needs Leo. Not urgent.

## Tick counter
10
