# ROADMAP.md — milestones

> **The loop may tick checkboxes here. It may not add, remove, reorder, or reword milestones.**
> Only Leo changes the milestone list. *How* each outcome gets built is the loop's business and
> belongs in `design/`.

Milestones are phrased as outcomes, not implementations. A milestone is done when its outcome is
demonstrably true in a captured clip, not when a task list is empty.

## M1 — Diorama
The HD-2D look itself, before there is any game. Pure spectacle, deliberately front-loaded so the
antfarm has something worth watching from day one.
- [x] Pixel sprite billboarded in a 3D scene, upright, facing the camera
- [x] Sprite casts a real shadow onto 3D geometry
- [x] Diorama camera: narrow FOV, angled down, flattened perspective
- [x] Tilt-shift depth of field — sharp band, blurred near and far
- [x] Bloom and tonemapping tuned to read as HD-2D
- [x] A lit environment with at least one practical light source

## M2 — Traversal
- [ ] Character controller with 8-direction sprite animation
- [ ] Collision against 3D level geometry
- [ ] Camera follows without breaking the diorama framing
- [ ] One hand-built town square that is worth standing still in

## M3 — First blood
The tactical hook becomes playable. The loop pitches its design in `design/combat.md` before
building it.
- [ ] A combat design pitch exists, with its reasoning and rejected alternatives
- [ ] Battle scene with turn order and a readable state
- [ ] Four creatures and enough moves to make a choice matter
- [ ] A battle that can be lost by playing badly and won by playing well
- [ ] Combat logic under unit test

## M4 — Creature systems
- [ ] Creatures, moves and types fully data-driven — adding one is a data edit
- [ ] Composable creature sprite system: parts, palettes, per-species proportions
- [ ] Capture implemented as designed
- [ ] Party management and progression
- [ ] Roster passes 20 creatures

## M5 — World and voices
- [ ] A repeatable region authoring workflow
- [ ] Three distinct areas with transitions between them
- [ ] Dialogue system with branching and character voice
- [ ] NPCs worth talking to twice
- [ ] Act one of the narrative throughline playable

## M6 — Steady state
The phase this can live in indefinitely. Content ticks alternate with design ticks.
- [ ] Roster passes 60 creatures
- [ ] Balance passes driven by recorded playtest data
- [ ] The world grows past what one sitting can cross
- [ ] Story beats land in the world, not just in documents

## M7 — Slice
- [ ] Save and load
- [ ] A coherent 30–60 minute vertical slice you could hand to a stranger
