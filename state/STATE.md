# STATE.md — the loop's working memory

Rewritten by the loop at the end of every tick. This is how a fresh session picks up where the last
one left off. Keep it short: it is read every tick, so bloat here costs tokens forever.

## Design status
Every roadmap box through **M5** now has a design document behind it. M6 is content and balance
passes; M7 is save/load and the slice. **The bottleneck is not design — it is that no tick since
tick 9 has had an engine.** Prefer building, checking or correcting over writing a fourteenth
document.

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

Next tick with an engine, in order: (1) move the encounter into `game/data/encounters.json` —
the format is already decided in `design/encounters.md`, including the finding that
`build_battle.gd`'s copy of `TEAM` can just be deleted rather than replaced; (2) apply the new
pairing;
(3) re-run both lines and confirm the model (the doc lists the exact `battle_*` input sequences —
6 decisions to win, 3 to lose); (4) drop `TURN_INTERVAL` to ~0.85 so the 16-event fight fits a
12–16s capture; (5) then tick box 4. Box 5 comes after, and its plan is decided in
`design/combat_tests.md` — note the constraint it turns on: **the loop may not edit
`farm/verify.sh`**, so tests go in `game/tests/`, run via a loop-owned `farm/test.sh`, and are a
tick-ritual discipline rather than a gate until Leo wires them in.

## Queued for the next engine tick
Four design documents are waiting, in this order. None needs re-deciding; all need building.
1. `design/encounters.md` — move the roster to `game/data/encounters.json`, delete
   `build_battle.gd`'s `TEAM` copy outright.
2. `design/first_blood_balance.md` — apply the re-pairing, confirm both scripted lines, tick M3's
   fourth box.
3. `design/combat_tests.md` — `game/tests/` + `farm/test.sh`, three tiers, tick M3's fifth box.
4. `design/creature_sprites.md` — port `design/proto/creature_forge.py` into `game/tools/`,
   generate, **`godot --headless --import`**, look at the frames. M4's second box. The prototype
   now carries six body plans and twenty placeholder entries, validated at roster scale — but
   author real creatures from `design/creatures.md`'s place/habit/tell template rather than
   shipping those placeholder names.

5. `design/hd2d_look.md` — remediation list at the bottom: battle scene has no fog, its
   tilt-shift brackets nothing (board is 22–25 units out; near blur ends at 17, far starts at 50),
   and its camera is wider *and* closer than the diorama's. **Look at a frame before and after
   each.** House key-light angle is now `(-44, -118, 0)` everywhere, because baked sprite shading
   forces every scene to agree.

6. `design/capture.md` — M4's capture box. Needs the encounter/party work above first.

## Open blockers
**No Godot in the container.** `verify.sh` fails at the smoke stage with exit 127 —
`/Applications/Godot.app/...` does not exist here and `curl`/`wget` are denied, so it cannot be
installed. If a tick sees exit 127, it is running in the remote container and not on Leo's Mac:
**nothing in `game/` may be committed.** Do design, devlog or `site/` work instead; both remaining
M3 boxes have real off-engine work available (see above). Note the first two verify stages pass
vacuously when the binary is missing — only the smoke stage catches it.

## Recent decisions
- **`design/*.md` is published at `/design/<slug>`** (tick 19): the site renders every design
  document, and backticked `design/foo.md` references in devlog entries auto-link to them. So a
  new design doc needs no site change — but it does need a `# Title` heading and a real first
  paragraph, since the index card uses both. Also fixed in `md.mjs`: list items may now wrap
  (lazy continuation). Before that, any wrapped item became a stray paragraph and bold spanning
  the wrap leaked literal `**` onto the page.
- **One key-light angle for the whole game: `(-44, -118, 0)`** (tick 18): generated sprites bake
  their shading from a fixed direction and billboards carry it everywhere, so scenes that key from
  different angles light the creatures wrong. `design/hd2d_look.md` has the full recipe and the
  side-by-side audit of the two builders. Rule for any new scene: copy the diorama's environment
  block, change only sky / ambient energy / key colour+energy, FOV stays 18 (move the camera back,
  never widen), and **check the DOF band's arithmetic** — a band that brackets nothing looks
  identical, in the file, to one that works.
- **Correct a stale document by addendum, not by editing** (tick 25): half a design document's
  value is the record of what was believed when the decision was made, and one silently updated
  to match today has never been wrong — the same fiction the standing rules forbid in devlogs.
  Also: **a random-play figure is meaningless without its rule set** (`--no-capture` reproduces
  the pre-capture rules). And the re-paired encounter is *not* centred in its tolerance band — it
  takes a 15% weaker player but only a 5% stronger one.
- **An encounter is atomic; region state is a region's problem** (tick 24): `encounters.md` now
  reconciles the requirements `capture.md`, `progression.md` and `narrative.md` put on it. **Do
  not add a condition field to an encounter entry** — a quieter version of a fight is a second
  encounter with its own id, owned by a region's per-state list. Consequence recorded there:
  baking `encounter_id` into the scene is right for one battle and wrong once a region picks at
  runtime. There is now a four-step checklist to run before any encounter ships (self-check →
  lines → tolerance → capture). **The design corpus is big enough to contradict itself — when a
  document imposes something on an older one, go and reconcile it.**
- **The combat solver is committed** (tick 23): `design/proto/combat_solver.py`, runs here (no
  engine needed). `--self-check` replays tick 9's committed naive result; **if it fails, the file
  is wrong and none of its numbers count.** Subcommands: `lines` (policy battery), `trace`,
  `search` (shortest forcing win), `tolerance` (an encounter's stat-tolerance band), `capture`.
  `--encounter current|repaired`, plus `SEEN_MODE`/`OFFER_COST` env vars for capture variants.
  **Use iterative deepening, never plain depth-first, for any decision count** — a depth-first
  search returns *a* line, not the shortest, and its length depends on the order `legal_choices()`
  lists moves in. That error put two wrong numbers into `design/capture.md`.
- **The story is about attention** (tick 22): `design/narrative.md`. Derived from the mechanics,
  not pasted on — combat cracks a performance, Charge is banked understanding, capture is seeing
  and sparing. Antagonist is an institution with a method for taking creatures *without* breaking
  their composure; escalation is that practice spreading, visible as regions going quiet, and it
  does not reverse. Told through places first (revisiting is the mechanic), people second, combat
  third. Two consequences for other systems: **encounter tables must be able to differ between
  visits** (a requirement on `design/encounters.md`'s format), and dialogue must remember what the
  player has done. Flagged, not designed: how an unbroken creature fights differently — that goes
  to the solver, not a paragraph.
- **Progression adds options, never magnitude** (tick 21): `design/progression.md`, measured.
  Scaling *both* sides changes nothing up to x3 — magnitude is free — but relative advantage has a
  tolerance of only about **-15% to +5%**: +5% player HP, +3 move power, or **+1 Guard** each flip
  the proof battle to a naive win. So: creatures learn moves, the roster is the progression, bonds
  give conditional traits and never percentages, **Guard never grows**, and difficulty comes from
  enemy composition rather than enemy stats.
- **HP-remaining is a bad closeness metric** (tick 21): naive loses the proof battle with the enemy
  on 24 of 52 HP, and +5% player HP reverses it — surviving one more hit buys a turn, and turns
  compound. Ticks 9 and 10 both used HP margin and were both misled. Measure an encounter's
  **stat-tolerance band** instead.
- **Capture: Seen + a two-Charge Offer** (tick 20): `design/capture.md`. Breaking a creature's
  Guard makes it *Seen* for the rest of the battle (persistent, not a window); Offer replaces an
  attack, costs **two** banked Charges, reaches either slot, and lands on anything Seen and alive.
  Deterministic, no refusal roll. Two earlier versions died in the solver — a one-turn Broken
  window makes speed-14 creatures *uncapturable*, and a one-Charge cost lets the break that makes
  a creature Seen pay for taking it (2 decisions, 14% by accident). Authoring constraint for
  encounters: every creature must be capturable by a party the player can plausibly have.
- **Guard is composure, not armour** (tick 17): `design/creatures.md`. A creature's Guard is what
  it is *pretending*; Breaking it is the pretence failing and the creature being seen. No rule in
  `combat.md` changes — this is the fiction those rules already described. Authoring template for
  every future creature: **place, habit, tell**. Naming rule: name for the habit or tell, never
  the element (the sprite hue already says the element). **Do not rename the existing four ids
  until M3's fourth box is ticked** — four design docs reference them.
- **`combat_solver.py constants` classifies every constant** (tick 36): fixed / bounded / free,
  recomputed on demand. Current: **fixed** `MELEE_REACH`=front. **Bounded** `FRONT_DAMAGE_BONUS`
  0–2, `BACK_TARGET_MULTIPLIER` ≤0.75, `CHARGE_MULTIPLIER` ≥1.5, `RESIST_HEAL` ≤2, `GUARD_REGEN`
  ≥1. **Free** `BROKEN_TAKES_MORE_DAMAGE`, `SWAP_MODE`. Two rules are **decorative** — Broken's
  50%-more-damage half and the resist heal both change no outcome (do not delete on that alone).
  Run this before and after any balance change.
- **Two positional constants are structural; one is a free knob** (tick 35, refined by 36): `design/position.md`.
  **Melee-locked-to-Front** is load-bearing (remove it and correct play *loses*, random 0.7%).
  **`BACK_TARGET_MULTIPLIER`** is load-bearing (remove it and `typed_hoard` wins, so Charge stops
  mattering). **`FRONT_DAMAGE_BONUS` changes none of the three outcomes** — reach for that dial
  first. Changing either of the first two invalidates every balance number in
  `first_blood_balance.md`, `capture.md` and `progression.md`. Solver flags: `FRONT_BONUS`,
  `BACK_MULT`, `MELEE_REACH`.
- **A swapped-in creature arrives with full Guard** (tick 34): `design/swap.md`. Measured, the
  full-action Swap in `combat.md` is a *trap* — removing it leaves the shortest win unchanged and
  raises random play from 13.0% to 20.5%. Cause: **Front is where every melee attack lands, from
  both enemies**, so Swap moves a creature into danger uncomposed. The fix restores the
  swapped-in creature's Guard, which is what `creatures.md` already said Guard means. Verified it
  breaks nothing (naive still loses, Charge stays load-bearing, band unchanged, random 13.2%).
  Solver flags: `NO_SWAP=1`, `SWAP_MODE=full|guard`.
- **Prototype sprites are committed and published** (tick 33): `design/proto/sprites/*.png`,
  copied into the site by `build.mjs` and shown in `design/roster.md` via plain markdown images.
  Regenerate with `FORGE_OUT=design/proto/sprites python3 design/proto/creature_forge.py`;
  `agreements.py` compares bytes, so a stale sprite fails. They are **not** game assets — real
  ones need `godot --headless --import`. **Habit worth keeping: when a tick creates a new way for
  two things to disagree, add the check in the same tick.**
- **Regions: Ground / Work / Attention** (tick 32): `design/regions.md`, `game/data/regions.json`.
  Attention decides the creatures, creatures decide the types, types decide the palette — so a
  reskin cannot fill in line three, which is the free check against a world of palette swaps.
  Geometry is code (`build_region_<id>.gd`, hand-authored, comments are the valuable part);
  look/encounters/conversations/exits are data. **Only `hd2d_look.md`'s permitted knobs may vary
  per region — never the key angle**, which is baked into every sprite. Build the Ridge first: the
  emptiest, so the cheapest geometry and the hardest test of "distinct". For `agreements.py` once
  regions exist: every exit's destination must exist and have an exit back.
- **Dialogue: ordered nodes, first match wins** (tick 31): `design/dialogue.md`,
  `game/data/conversations.json`. The bar that makes M5's "worth talking to twice" checkable: **an
  NPC is not finished until it has at least one line that only appears because of something the
  player did.** Visit count is recorded automatically so `talked: ">0"` is free. **No templating,
  ever** — conditions exist to make specific lines affordable, not generic ones parameterisable.
  Last node must be unconditional (a check `agreements.py` should gain). Do not *build* it before
  the party exists, or half the conditions are untestable.
- **Screenshot the furniture, not just the thing you built** (tick 30): tick 19 added a fifth nav
  item, screenshotted the page body at 420px, and left "Glass" falling off the right edge for
  eleven ticks. The habit has caught four real bugs, all invisible in source and obvious on
  screen — it only works if the shot includes what you were not thinking about. Also: the front
  page hero now leads with the newest *tick*, not the newest *clip*.
- **`farm/agreements.py` checks cross-file consistency** (tick 29): eleven agreements — data
  integrity, the two hand-synced `TEAM` tables, input actions vs the autoload, solver constants vs
  `combat_resolver.gd`, and the published record (every devlog commit sha resolves; devlog and
  JOURNAL agree). **Run it alongside `verify.sh` in the tick ritual.** It caught a devlog citing an
  invented commit sha and a missing tick-0 journal line. Note: the TEAM check is *meant* to start
  failing once `encounters.md` is built — update the check, not the code.
- **Screen-space light: house angle = 130 deg, battle scene currently 114** (tick 28): computed,
  not assumed. `creature_forge.py` now *derives* its baked light from `HOUSE_KEY_EULER` + camera
  tilt, so changing the house angle changes the sprites. Both cameras project the house angle to
  130 within a degree, so one bake serves both — luck, not law: they tilt about X only and neither
  is yawed. **Standing suspicion: several documents assert that two systems must agree about
  something, and this is the first time one was checked. It was wrong. Check the others.**
- **Twenty real creatures exist, in `design/roster.md`** (tick 27): authored from place/habit/tell,
  five per type across all six body plans, shapes in `design/proto/creature_forge.py`. Finding: the
  *tell* decides the silhouette — write the sentence first and the proportions follow. Type falls
  out of place, so author place-first or the roster drifts to one animal per element.
  **Deliberately unstatted** — no HP/Guard/speed/moves for the sixteen new ones, because statting
  them without running `encounters.md`'s tolerance checklist is what ticks 8 and 9 did.
- **Shade from a local surface normal, never from the centroid** (tick 26): the thin-limb problem
  that beat three attempts. A centroid-relative "how much does this face the light" puts every leg
  below the centroid, so both sides of a limb read as unlit and there is no lit edge to find.
  `normals()` estimates a real per-pixel normal from nearby empty space; a 3px limb then gets a lit
  edge, a base spine and a shadowed edge. Fixed every plan, not just the broken one. Open: the
  roster is lighter overall now, and the shadow threshold wants revisiting against a real scene's
  key light rather than a flat swatch.
- **Only the silhouette reads** (tick 16): the one rule the sprite technique turns on. Anything
  drawn *inside* another part's outline is invisible — it must be drawn a pixel fatter in the
  outline colour first (`taper_edged`). Rootshell's vanishing shell and the brawler plan rendering
  three creatures as identical beans are the same bug. Limit: a part nearly as wide as what it
  sits on cannot be saved by an edge; those proportions are just wrong. Roster variety comes from
  **plan count**, not entry count — six plans carry twenty; sixty wants ten to twelve.
- **Creature sprites are (body plan, proportions, palette, features)** (tick 15):
  `design/creature_sprites.md`, proven by `design/proto/creature_forge.py` (runs here — it is
  Python; `python3 design/proto/creature_forge.py --sheet`). A body plan is a *function* of
  proportions, never a stored map. Three mechanical passes do the art: auto-outline,
  distance-field shading under **one** global light (must match `build_battle.gd`'s `Key` at
  `(-50, -140, 0)`), and drawing order as depth via a flat-dark `FAR` channel. Known unsolved: a
  thin part has no interior, so edge-based shading swallows it — Emberling's legs.
- **Combat tests are a discipline, not a gate** (tick 14): `farm/verify.sh` is on the loop's deny
  list, so the loop can write tests but cannot make them block a commit. Plan in
  `design/combat_tests.md`: `game/tests/run_tests.gd` (a `SceneTree` script, no framework), run by
  `farm/test.sh`, invoked next to `verify.sh` in the tick ritual. Three tiers — rules, outcomes
  (naive loses / correct wins / correct-but-hoarding-Charge loses, which makes M3's *fourth* box
  permanent), and one golden trace. Assert outcomes, never margins.
- **Encounters become `game/data/encounters.json`** (tick 13): format decided in
  `design/encounters.md`. The key finding: `build_battle.gd`'s `TEAM` copy exists only to bake
  `InfoLabel` text that `battle.gd._ready()` overwrites before frame one, so the generated scene
  never needed the roster — delete the second table rather than replace it. Also noted there:
  **nothing in `verify.sh` loads `battle.tscn`** (the gate smoke-runs the diorama), so a malformed
  encounters.json passes green and fails only in the battle demo.
- **The site scrapes this file, so its prose is load-bearing** (tick 12): `loadState()` in
  `site/build.mjs` lifts `Current milestone`, `Current focus` and `Open blockers` onto the front
  page. Its section regex used to carry an `m` flag, under which `$` matches every line end, so
  every section collapsed to its first line — fixed by anchoring as `(?:^|\n)## ` with no flag.
  The scraped text now goes through a markdown flattener and a sentence-wise summariser with a
  character cap, so **wording this file freely can no longer break the page**. Write for the next
  tick, not for the site. (Splitting sentences: match a terminator *followed by whitespace*, or
  `first_blood_balance.md` gets cut in half.)
- **The site's bestiary reads `game/data/*.json` directly** (tick 11): it had guessed a
  `game/data/creatures/` one-file-per-creature directory that the game never adopted, so it
  reported an empty roster for four ticks while shipping four creatures. Two lessons worth keeping:
  a *graceful* fallback for a state you have left does not surface as an error, so re-read the
  empty-state copy on any generated page whose data has since arrived; and `site/dist` can be
  served with `python3 -m http.server` and screenshotted with
  `/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell --no-sandbox
  --screenshot=... --window-size=W,H <url>` — the stylesheet is root-relative, so `file://` renders
  unstyled. CSS trap: `article.post h2` outranks a bare `.beast h2`.
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
36
