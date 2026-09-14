# STATE.md — the loop's working memory

Rewritten by the loop at the end of every tick. This is how a fresh session picks up where the last
one left off. Keep it short: it is read every tick, so bloat here costs tokens forever.

## Design status
**`design/README.md` is the reading guide** — what each document decides, in order, with
dependencies and a "what to distrust" section. A new design doc must be added to it or
`agreements.py` fails. The site leads the `/design` index with it.


Every roadmap box through **M5** now has a design document behind it. M6 is content and balance
passes; M7 is save/load and the slice. **The bottleneck is not design — it is that no tick since
tick 9 has had an engine.** Prefer building, checking or correcting over writing a fourteenth
document.

## Current milestone
M3 — First blood. **Four of five boxes done**; the fourth closed in the merged branch's tick 10,
in the engine, on the *unpaired* roster. Box 5 (combat logic under unit test) is untouched, and
`design/combat_tests.md` plus the 74 generated cases in `design/proto/combat_cases.json` are
waiting for it.

## Current focus
**The engine works here now, and forty-four ticks of design are waiting to land.** Work the queue
below in order. Start with item 1, because everything after it reads the encounter data.

**The re-pairing is still the recommendation, and it is not what the engine ships.** The merged
branch closed M3's fourth box on the *unpaired* roster by finding a seven-decision winning line
exhaustively. That result is real and it is not the same claim as this line's: a fight can have a
winning line and still have no winning *plan*, and on the unpaired roster no explainable policy
wins and random play wins 0.4%. `design/first_blood_balance.md` prescribes **Player Rootshell
(Front) + Tidalpup (Back) vs Enemy Emberling (Front) + Galewing (Back)**, where every correct
target is diagonal, naive loses, correct targeting wins, and hoarding Charges loses by 10 HP.
Landing it is item 2 of the queue. Do not treat box 4 as reopened — it is closed; this improves
the fight it closed with.

**The two searches agree exactly** (tick 54). `battle_sim.gd` (GDScript, in-engine, exhaustive)
and `design/proto/combat_solver.py --no-capture` (Python, off-engine) both report no win at six
decisions and a win at seven on the unpaired roster, and produce the same line move for move:
Emberling melee, **Rootshell ranged at the enemy Back slot**, Emberling melee, Rootshell melee ×3,
Rootshell melee +Charge. Two implementations, two sessions, one answer. Anything that makes them
disagree is a bug in one of them, and finding out which is now a five-minute job.

## Queued for the next engine tick
None of these needs re-deciding; all need building. Work them in order.

1. ~~`design/encounters.md` — move the roster to `game/data/encounters.json`.~~ **Done, tick 55.**
   `EncounterDB` reads it, `battle.gd` has an exported `encounter_id`, `build_battle.gd` takes one
   on the command line, and both `TEAM` tables are deleted. `the_ridge` stays in
   `design/proto/encounters.json` only until Ashmoth and Ridgewalk have stats in
   `game/data/creatures.json`; an agreement check will say so the moment they do.
2. `design/first_blood_balance.md` — apply the re-pairing. **This is now one line**: set
   `encounter_id` to `first_blood` in `build_battle.gd`/`battle.gd` and rebuild. Then re-script
   `battle_demo.gd`'s `LINE` (the re-paired board is a different tree, so the seven-decision line
   does not transfer) and confirm against `battle_sim.gd --search`. Box 4 is already ticked; this
   improves the fight it was ticked with, it does not reopen it. **Also apply the retune recorded there**: `CHARGE_MULTIPLIER` 1.5 → 2.0,
   `BROKEN_TAKES_MORE_DAMAGE` 1.5 → 1.0 (deleting that clause), `FRONT_DAMAGE_BONUS` 2.0 → 1.0.
   Validated on **both** encounters: exactly one of seven scripted lines wins and it is the
   correct one; bands +75/+40 and +75/+50; random play 9.2% and 4.8%. Update the solver's constants in the same commit or `agreements.py` will fail —
   that is deliberate.
3. `design/combat_tests.md` — `game/tests/` + `farm/test.sh`, three tiers, tick M3's fifth box.
   **Tiers 1 and 2 are already generated**: copy `design/proto/combat_cases.json` to
   `game/tests/cases.json` and write a runner that walks its sections (74 cases + a golden
   trace). Regenerate with `python3 design/proto/gen_test_cases.py` — `agreements.py` fails if it
   is stale, and the fixture records the constants *as shipped*, so applying the retune means
   regenerating in the same commit.
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
   **It carries a hard UI requirement**: the capture window is 0–2 decisions wide in *every*
   encounter measured (`combat_solver.py window`), and in the two-a-side fights it shuts because
   the player wins. So the battle UI must announce the Offer the instant it becomes legal — a
   state change that cannot be missed, not a button that quietly ungreys. Nothing else queued
   depends on the UI this much.

7. `design/battle_hud.md` — **build the battle HUD against the mockups, not from scratch.**
   `design/proto/battle_hud.py` draws the board from live solver state and the frames are
   committed under `design/proto/mockups/`. The Offer banner rides the target cursor (one at a
   time), creatures anchor by their feet, and an encounter marked `tutorial` hides the empty slot
   markers. `agreements.py` fails if the committed frames drift from the generator.

8. `design/tutorial.md` — the Kiln Yards duel (`kiln_duel` in `design/proto/encounters.json`,
   `tutorial: true`). A side of **one** creature: `build_battle.gd` already draws all four slot
   markers regardless of occupancy, so the loader from item 1 must tolerate a missing slot rather
   than assume two per side.

## The tick ritual
Run **`python3 farm/test.py`** as well as `./farm/verify.sh`. It runs the combat model's
self-check and the twenty-two cross-file agreements, and *loudly skips* the GDScript suite until
`game/tests/run_tests.gd` exists. A skipped stage is a check that is not happening — the summary
says so. (It is `.py`, not the `.sh` `combat_tests.md` first named: the loop cannot `chmod` and
has no allowlisted way to invoke a shell script it just created.)

## Open blockers
- **`farm/publish.py` cannot run in a cloud container.** It needs `AWS_ENDPOINT_URL_S3` and keys
  from `farm/.env`, which is gitignored and so does not exist in a fresh container. A cloud tick's
  devlog entry is text-only even when the clip is fine. Fix is credentials in the environment, not
  code.
- ~~**No Godot in the container.**~~ **Solved by the merge (tick 54).**
  `.claude/hooks/session-start.sh` installs Godot (version read from `project.godot`), ffmpeg and
  `mesa-vulkan-drivers`; lavapipe gives software Vulkan so Forward+ and its depth of field still
  render, and `farm/capture.sh` re-execs under Xvfb when `DISPLAY` is unset. **The hook only runs
  at session start**, and it was committed without the executable bit — fixed in tick 54, but if a
  session ever finds `GODOT_BIN` unset, run `./.claude/hooks/session-start.sh` by hand and export
  what it writes. Rendering costs ~390 ms/frame, so a 24s clip is a ~6 minute render: check things
  headlessly first.
- The hook still needs registering in `.claude/settings.json`, which is frozen by the pre-commit
  hook and not the loop's to edit. The three lines to paste are in the README.

## Recent decisions
- **Prove a refactor inert with `battle_sim.gd`'s node counts** (tick 55). The iterative-deepening
  search prints how many nodes it expanded at each depth, and that is a fingerprint of the rules
  and the board together. `4, 20, 93, 457, 1675, 4701, WIN at 7 in 78` before and after means no
  rule moved. Much stronger than a green gate and it costs one command. Corollary: a change that
  is *meant* to alter the fight cannot be checked this way, so do not land one in the same commit.
- **Encounters live in `game/data/encounters.json`** (tick 55). Node names are derived
  (`side.capitalize() + slot.capitalize()`), never listed. `battle.gd`'s `encounter_id` is exported
  and always set explicitly by the builder — Godot does not serialise an exported property equal
  to the script's default, so a defaulted scene would store nothing and follow any later change to
  that default.
- **Two lines of work merged at tick 54.** A parallel session branched from tick 9, taught the farm
  to run in a cloud container, and closed M3's fourth box in the engine. Both branches numbered
  their next tick 10, so `JOURNAL.jsonl` has two tick-10 rows (`0011-search-the-line` from theirs,
  `0011-solving-first-blood` from this line) sitting next to each other. Renumbering 44 published
  devlog URLs to tidy a counter would trade a real asset for a cosmetic one, so the collision
  stays and this note explains it. This line's numbering continues.

### From the merged branch (its tick 9 and 10)
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
- `farm/capture.sh`'s Movie Maker path drops/coalesces frames on long captures — tick 10's 24s
  capture came out at exactly 720 frames, so the ceiling is higher than the 12–16s previously
  assumed, but check `ffprobe` frame count when going long.
- `battle.gd`'s `turn_interval` is exported so the demo can turn it down (0.7) to fit a whole fight
  in one capture. Nothing else should change it.

### From this line
- **Design questions about a screen get drawn, not written** (tick 53). `design/proto/battle_hud.py`
  renders the board from live solver state; run it with no arguments to redo every frame. It
  corrected two layout decisions within an hour that prose had not caught in two ticks — an Offer
  banner on every offerable enemy (two at once in `first_blood`), and a target cursor anchored to
  the sprite box rather than the body inside it. Commit the frames; `agreements.py` checks them.
- **Capture costs no tempo and the window is 0–2 decisions wide, everywhere** (tick 52).
  `cap+win` equals `win` in all three encounters, so `capture.md`'s tempo retraction now holds on
  three fights rather than one. But the Offer opens and shuts inside a couple of decisions,
  because the hits that bank Charges are the hits that end the fight — and in a two-a-side fight
  it shuts because the player *wins*, which gives them no feedback at all. `combat_solver.py
  window --encounter <id>` prints the table.
- **`capture_window()` used to walk to the wrong state** (tick 52). It stopped before the line's
  last decision, which is the Offer only in a duel. Now it stops at the first state where
  `offer_ok` is true. If a measurement here looks implausible, suspect the walk before the rules.
- **A tutorial gets the opposite contract from a tactical fight, and its own check** (tick 51).
  `encounters.md`'s checklist wants naive play to lose; a tutorial must not be losable. An
  encounter marked `"tutorial": true` in `encounters.json` skips the discrimination and
  Charge-economy rules and is held to three others instead, checked in `agreements.py`: naive
  wins, the enemy is capturable, and mashing attack costs you the creature. The exemption without
  the replacement rule would have been a hole. `python3 design/proto/combat_solver.py tutorial
  --encounter kiln_duel` prints the numbers.
- **The capture window is one decision wide and nobody tuned it** (tick 51). Two weak hits bank
  the two Charges an Offer costs; three hits kill. Six of the eight capturable duels in the
  roster have zero spare attacks. Do not "fix" this by repricing `OFFER_COST` (measured: cost 1
  gives one spare attack, and retunes the whole capture system) or by giving a tutorial creature
  bespoke HP (measured: +50% gives two). The recovery is that the region keeps producing the
  encounter.
- **The solver supports sides of one creature** (tick 51), and the fix was in the *readers*, not
  the state layout: tick 50 made `unpack`/`pack` variable-width and left the policy functions
  indexing enemies at 2 and 3 and `melee_charge` reading Charge off `s[4]`. Use `slot_index(side,
  slot)`, `enemy_slots()` and `s[len(TEAM)]`; never a literal offset. `parties` now refuses to
  answer for an encounter that fixes the player's side.
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
- **One save, written by the game** (tick 45): `design/save.md`. No slots, no manual save —
  autosaves on region transitions, after battles, after any dialogue that sets a flag. A story
  whose consequences do not reverse cannot ship a load button. The deal that makes it fair: **never
  ask for an irreversible decision under time pressure or without information** (the game already
  has no hidden rolls anywhere). Two open consequences: losing a battle must mean something in the
  fiction, and the autosave decision changes how party/regions/dialogue are *built*, not just
  stored.
- **The story is about attention** (tick 22): `design/narrative.md`. Derived from the mechanics,
  not pasted on — combat cracks a performance, Charge is banked understanding, capture is seeing
  and sparing. Antagonist is an institution with a method for taking creatures *without* breaking
  their composure; escalation is that practice spreading, visible as regions going quiet, and it
  does not reverse. Told through places first (revisiting is the mechanic), people second, combat
  third. Two consequences for other systems: **encounter tables must be able to differ between
  visits** (a requirement on `design/encounters.md`'s format), and dialogue must remember what the
  player has done. Flagged, not designed: how an unbroken creature fights differently — that goes
  to the solver, not a paragraph.
- **Discrimination and openness are independent** (tick 50): an encounter can reward skill
  perfectly and admit exactly one party, which is a key check rather than a fight. Run
  **`combat_solver.py parties`** — it is the fifth item on `encounters.md`'s checklist. The Ridge
  was retuned 2→8 viable parties and 1→4 workable Fronts by making its *Front* enemy **slower**
  (Ashmoth speed 12→8, Ridgewalk 14→16). **A slow Front enemy is what opens a fight**; slow and
  dangerous beats uniformly quick.
- **Party choice is decisive and unpredictable** (tick 49): 2 of 12 pairs can beat The Ridge at
  all. It is the **types, not the stats** — transplanting Rootshell's HP/Guard/speed onto
  Emberling or Galewing saves neither. And **no simple rule predicts it**: "front resists an
  enemy" and tick 38's "both can break something" are necessary-not-sufficient filters; two other
  candidates are wrong. Consequence: **a party UI must never show a coverage score** — show the
  matchup grid and let the player be right.
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
- **Always run `constants --all-encounters`** (tick 40): a value counts as safe only if it holds on
  every balanced encounter. Current conservative answer — **fixed**: `MELEE_REACH`=front,
  `RESIST_HEAL`=2. **Bounded**: `FRONT_DAMAGE_BONUS` 1–2, `BACK_TARGET_MULTIPLIER` ≤0.75,
  `CHARGE_MULTIPLIER` ≥1.5, `GUARD_REGEN` ≥1. **Free**: `BROKEN_TAKES_MORE_DAMAGE`, `SWAP_MODE`.
  `RESIST_HEAL` was called decorative on one encounter and breaks the Ridge at 0 — of the two
  rules nominated as inert, only Broken's damage half survives.
- **A one-encounter measurement is wrong in one direction: "this rule does nothing"** (tick 39).
  `FRONT_DAMAGE_BONUS` looked like slack for three ticks; on the Ridge, zeroing it means the fight
  **does not work at all**. Slack in one fight is not slack everywhere. **Read `position.md`'s
  classification as "on the proof battle", and re-run it per encounter** — the tool takes
  `--encounter`. Final answer: +1, best on both.
- **Every enemy line must give each player creature something it can break** (tick 38):
  `design/second_encounter.md`. A one-type enemy line **cannot** make a pillar-2 encounter — 0 of
  192 stat settings — because a creature whose attacks are all resisted does 0 Guard damage,
  never banks a Charge, and is absent from the economy the fight is about. Constrains
  `regions.md`, which pushes toward one type per region: a region may be predominantly one type,
  but an *encounter* must be mixed, deliberately.
- **The diagonal requirement is structural** (tick 38): confirmed on a second encounter with
  different creatures and stats — straight arrangement 0 of 180, diagonal 7 of 180. And the tick-37
  retune **generalises**: 7→12 workable settings, band +0/+75 → +75/+75, random 15.6% → 6.3%.
  Second encounter reproducible: `combat_solver.py lines --encounter ridge`.
- **Use `constants --band`, not the pass/fail classification** (tick 37): the binary says
  `BROKEN_TAKES_MORE_DAMAGE` is "free"; the band says it moves the fight from +20% to +75%. **A
  constant can be free by the binary and still be the most important dial in the file.** Mechanism
  worth remembering: Charge is the only resource unskilled play cannot reach, so its multiplier is
  the direct lever on pillar 2 — and the Broken damage bonus was subsidising naive play (removing
  it leaves correct play *identical* and makes naive strictly worse).
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
- **Creatures have a two-frame idle; animate AFTER shading** (tick 44): frame B shifts everything
  above the silhouette midpoint down one row. Do **not** animate parametrically — shading is a
  global pass, so nudging a proportion re-shades the whole sprite and reads as shimmer.
  **Pixel-diff count measures change, not coherence**: the 21-px version looked wrong and the
  98-px one looks right. Site layering verified; the CSS animation itself is **unverified** —
  headless does not advance animation time.
- **Prototype sprites are committed and published** (tick 33): `design/proto/sprites/*.png`,
  copied into the site by `build.mjs` and shown in `design/roster.md` via plain markdown images.
  Regenerate with `FORGE_OUT=design/proto/sprites python3 design/proto/creature_forge.py`;
  `agreements.py` compares bytes, so a stale sprite fails. They are **not** game assets — real
  ones need `godot --headless --import`. **Habit worth keeping: when a tick creates a new way for
  two things to disagree, add the check in the same tick.**
- **Region data is written and validated** (tick 47): `design/proto/regions.json` — three regions,
  ready to copy to `game/data`. `agreements.py` enforces exit reciprocity (mark deliberate
  one-way exits `"one_way": true`) and, importantly, that a region's `look` sets **only** sky /
  ambient_energy / key_color / key_energy / fog. The key **angle** is house style and is rejected
  by name. The Ridge's `quiet` encounter list is empty *on purpose* — that is narrative.md's
  escalation with no new content.
- **Regions: Ground / Work / Attention** (tick 32): `design/regions.md`, `game/data/regions.json`.
  Attention decides the creatures, creatures decide the types, types decide the palette — so a
  reskin cannot fill in line three, which is the free check against a world of palette swaps.
  Geometry is code (`build_region_<id>.gd`, hand-authored, comments are the valuable part);
  look/encounters/conversations/exits are data. **Only `hd2d_look.md`'s permitted knobs may vary
  per region — never the key angle**, which is baked into every sprite. Build the Ridge first: the
  emptiest, so the cheapest geometry and the hardest test of "distinct". For `agreements.py` once
  regions exist: every exit's destination must exist and have an exit back.
- **Three NPCs written and checked** (tick 48): `design/proto/conversations.json`.
  `agreements.py` enforces dialogue.md's rules — unconditional last node, at least one line
  conditioned on something the player *did*, **no templating** (a `{` fails), **no signposts** (a
  line matching `<Type>-type` or `weak to <Type>` fails and quotes GAME.md). New rule the checker
  produced on its first run: **`party_has` may only name a creature that has stats**, not merely
  one in the roster — otherwise the condition can never fire.
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
55
