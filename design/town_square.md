# Town square — the last M2 box

M2 needs "one hand-built town square that is worth standing still in." Everything built so far
(back wall, pillars, crates, a bench) was staged as depth-of-field dressing for the M1 diorama
shot — it reads as props scattered for the camera, not a place with a layout a player would
recognize as somewhere. This is the decision for turning that into an actual square.

## What "worth standing in" means here

Not size, not prop count — legibility. In ten seconds of video a viewer should be able to say
"this is a plaza, that's a well, those are shops" without being told. Three things do that work:

1. **A floor that reads as a place, not a road.** The existing stone path is a corridor (5 wide,
   70 long) — it says "walk through here," not "stop here." A square plaza slab, wider than the
   path that feeds it, is the difference between a hallway and a room.
2. **A centerpiece.** Plazas organize around something — a well, a fountain, a statue. Without one,
   any arrangement of boxes reads as storage, not a town. A well is the cheapest to build honestly
   (a cylinder rim reads immediately, no need for water shaders) and gives the traveler a reason to
   stand near the middle instead of walking through it.
3. **Buildings with faces, not walls with backs.** `WallBack` and its pillars were a backdrop —
   flat, no door, nothing to imply an interior. Two facades flanking the plaza, each with a
   roof-cap and a door-shaped inset, imply the square is *surrounded*, which a single back wall
   never could.

## Rejected alternatives

- **Scatter more crates and pillars.** Cheapest option, and what the last two ticks already did.
  Rejected because it doesn't change what the space *reads as* — more DOF furniture, still no
  center, still no sense of enclosure. The milestone box asks for a square, not more clutter.
- **A literal walled courtyard (four sides, a gate).** Considered and rejected for scope: fully
  enclosing the plaza means rebuilding the south entrance the path already establishes, and risks
  boxing the camera's sharp band in on itself. Two facades plus the existing back wall imply
  enclosure without redoing the traversal demo's whole approach.
- **Custom peaked-roof geometry.** Godot has no wedge primitive on hand and the project has no
  modeling step in its pipeline (`build_diorama.gd` only ever emits primitives). A second,
  wider, contrasting-color box stacked on the building reads as a roof cap at diorama-camera
  distance without needing real roof geometry — consistent with how the lantern head is just an
  emissive box, not a lamp mesh.

## Layout

Plaza floor: a stone slab wider than the path, centered where the path already meets the back
wall, so the existing traversal demo's "walk north into the dressing" beat now walks into an
actual room instead of a strip.

- **Well**, off-center so it never sits on the traveler's spawn point, rim + a darker recessed
  "water" cylinder inside it.
- **Two shop facades**, one each side of the plaza, mirrored: a building block, a roof-cap block
  in a contrasting warm color, and a darker door-shaped inset on the face pointed at the plaza.
- **A market stall**, built from the same crates the last tick already placed (repurposed as
  stall goods) plus a counter and a two-post awning, so old set dressing gets a job instead of
  being thrown away.
- **A second lantern post**, mirrored across the plaza from the existing one, so the practical
  light source from M1 doesn't read as a lopsided accident once there's an actual room for it to
  light.

No new textures. Everything is `stone.png` for masonry, or flat `StandardMaterial3D` colors for
roofs, doors, and awnings — the same trick the lantern head already used to avoid the project's
"only two textures exist" limit.
