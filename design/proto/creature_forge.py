"""creature_forge — MOVED.

This was the prototype. design/creature_sprites.md's handoff said to port it
into the engine when there was an engine, and tick 60 did:

    game/tools/creature_forge.py      the generator
    game/data/creature_art.json       which creatures exist and how each is drawn
    game/assets/sprites/creatures/    the PNGs, imported

Nothing reads this file any more. It is still here only because the loop has no
allowlisted way to delete a file — see state/STATE.md's cleanup section. The
committed prototype sprites in design/proto/sprites/ are dead for the same
reason. Importing this raises rather than quietly shadowing the real generator.
"""
raise ImportError(
    "design/proto/creature_forge.py moved to game/tools/creature_forge.py at tick 60")
