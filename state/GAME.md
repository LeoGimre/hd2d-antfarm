# GAME.md — the pillars

> **This file is immutable to the antfarm loop.** The loop may read it every tick and may never
> edit it. Only Leo changes this document. Everything the loop is free to invent lives in `design/`.

## What this is

A creature-collecting **tactical** turn-based RPG, rendered in **HD-2D** — pixel-art sprites
billboarded inside a real 3D scene, tilt-shift depth of field, heavy bloom, dramatic lighting,
diorama camera. Octopath Traveler's look, Pokémon's shape, with tactics that are actually tactics.

## Pillars — immutable

1. **A large and growing roster.** Collect and field creatures. The roster keeps growing; the
   architecture must never make adding a creature expensive.
2. **Battles are tactical, not stat-checks.** A skilled player beats an over-levelled one. If a fight
   can be won by holding the confirm button, the design has failed.
3. **A grand narrative.** A throughline with escalation and consequence — not a badge checklist.
4. **A large, explorable world.** Distinct regions worth crossing, with reasons to cross them.
5. **Characters with voice.** People the player remembers. Dialogue that sounds written, not
   generated. Signposts in human clothing are a failure.
6. **HD-2D, always.** Every frame should read as a lit diorama. Visual identity is a pillar, not
   a polish pass to be deferred.

## Seeds — starting points, not requirements

The loop may adopt, combine, extend, or discard any of these. They exist so tick 1 has traction, not
to constrain the design. Whatever it chooses, the reasoning belongs in `design/combat.md`.

- **Positional tactics.** Lanes or a small grid: which of your active creatures stands where matters,
  and moves have shape and reach.
- **Break economy.** Creatures carry guards that must be cracked; cracking them banks a resource
  spent on burst turns. Gives battles rhythm.
- **Capture as a tactical act.** Not a coin flip — engineer a board state that makes a creature
  willing. The setup is the fun.
- **Bonds with memory.** Creatures fielded together develop traits, so a team accretes history
  instead of being a spreadsheet.

## Non-goals

Out of scope. Do not build these, do not plan for them, do not leave hooks for them.

- Multiplayer of any kind
- Procedural world generation (the world is authored)
- 3D character models (sprites only — this is what makes it HD-2D)
- Mobile or console targets (desktop only)
- Voice acting, cutscene cinematics

## The standard

This project is watched while it is built. Prefer the version of a thing that is legible in ten
seconds of video over the version that is technically purer and shows nothing.
