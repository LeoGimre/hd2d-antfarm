# The roster

Twenty creatures, authored from `design/creatures.md`'s **place / habit / tell**
template. This is M4's "roster passes 20" box as content, and it is also the
first real test of whether that template *generates* or merely sounds good.

Every entry's type comes from its place, its body plan from its habit, and its
Guard — what breaking it reveals — from its tell. The shapes are rendered by
`design/proto/creature_forge.py`; run it with `--sheet` to look at them.

## Ember — hearths, kilns, burnt ground

| | place | habit | tell | plan |
|---|---|---|---|---|
| **Emberling** | banked hearths | goes back to the warm spot | pretends it is not cold | quadruped |
| **Stokewake** | kiln yards still ticking as they cool | wakes whenever anything is lit | pretends it was already awake | insectoid |
| **Lastcoal** | burnt ground the year after | sits on the one warm spot in a cold field | pretends the fire is coming back | blob |
| **Bellowsback** | forge yards | breathes in time with work that stopped years ago | pretends it is still needed | brawler |
| **Ashmoth** | chimney flues | goes toward light and is disappointed | pretends it meant to | avian |

![Emberling](/sprites/emberling.png) ![Stokewake](/sprites/stokewake.png) ![Lastcoal](/sprites/lastcoal.png) ![Bellowsback](/sprites/bellowsback.png) ![Ashmoth](/sprites/ashmoth.png)

## Tide — tidelines, wells, gutters

| | place | habit | tell | plan |
|---|---|---|---|---|
| **Tidalpup** | the line the water keeps returning to | comes back with the tide | pretends to be leaving | serpent |
| **Wellmouth** | a covered well | answers | pretends it is only an echo | serpent |
| **Slackwater** | the hour the tide stops | does nothing, precisely | pretends stillness is a choice | blob |
| **Riverbend** | where a river gave up going straight | takes the long way | pretends it is not lost | quadruped |
| **Downspout** | gutters and eaves | only appears when it rains | pretends it lives there | insectoid |

![Tidalpup](/sprites/tidalpup.png) ![Wellmouth](/sprites/wellmouth.png) ![Slackwater](/sprites/slackwater.png) ![Riverbend](/sprites/riverbend.png) ![Downspout](/sprites/downspout.png)

## Gale — ridgelines, towers, thresholds

| | place | habit | tell | plan |
|---|---|---|---|---|
| **Galewing** | ridgelines and updrafts | never lands | pretends nothing can reach it | avian |
| **Doorslam** | thresholds and passes | arrives just as you leave | pretends it was going that way anyway | avian |
| **Bellhang** | bell-towers | rings things that should not ring | pretends someone else did it | insectoid |
| **Ridgewalk** | the last hundred feet of a ridge | never comes down | pretends it has somewhere to be | brawler |
| **Draughtcatch** | the gap under a door | fills any gap | pretends it is keeping the cold out | blob |

![Galewing](/sprites/galewing.png) ![Doorslam](/sprites/doorslam.png) ![Bellhang](/sprites/bellhang.png) ![Ridgewalk](/sprites/ridgewalk.png) ![Draughtcatch](/sprites/draughtcatch.png)

## Root — old growth, foundations, orchards

| | place | habit | tell | plan |
|---|---|---|---|---|
| **Rootshell** | old growth that outlived the wood around it | does not move | pretends the shell is the whole of it | quadruped |
| **Holdfast** | foundations of houses that fell | holds | pretends the house is still there | brawler |
| **Windfall** | orchards | waits under a tree | pretends it is not waiting | quadruped |
| **Gravebind** | graveyard hedges | grows over anything left alone | pretends it is tidying | serpent |
| **Stumpsit** | cut stumps | sits where a tree was | pretends to be the tree | brawler |

Five per type, spread across all six body plans.

![Rootshell](/sprites/rootshell.png) ![Holdfast](/sprites/holdfast.png) ![Windfall](/sprites/windfall.png) ![Gravebind](/sprites/gravebind.png) ![Stumpsit](/sprites/stumpsit.png)

## Did the template work?

Yes, and more usefully than expected: **the tells produced the silhouettes.**

Not by rule — nothing forces a tell to imply a shape. But writing "fills any
gap" and then reaching for proportions produced a wide, flat, short-tendrilled
thing that reads as something under a door. "Never comes down" produced the
tallest, thinnest creature on the sheet. "Sits where a tree was" produced a
squat immovable lump. "The one warm spot in a cold field" produced a single
small round coal. In each case the shape was chosen after the sentence, and the
sentence did the work.

That is the property worth having, because it is the one that survives to tick
two hundred. Anyone can fill in three blanks; the template earns its place if
the blanks then tell you what to build.

Two second-order effects worth recording:

**Type fell out of place, not the other way round.** Writing the place first
meant the type was already decided by the time it was needed. That is the right
dependency order — a roster authored type-first drifts toward one animal per
element, which is what the four original creatures were.

**Naming got easier, not harder.** The rule from `creatures.md` — name for the
habit or the tell, never the element — looked like a constraint and behaved like
a prompt. *Draughtcatch*, *Slackwater*, *Holdfast*, *Doorslam* all came directly
off the habit line. Compare the four originals, which are element plus a suffix
and say nothing.

## What did not work

Two of twenty do not read at sprite size, and both hit limits already recorded
in `design/creature_sprites.md` rather than new ones:

- **Lastcoal** is a plain lump with no feature breaking its outline. That is the
  "only the silhouette reads" rule from tick 16 — a blob with no lobes, no
  tendrils and nothing else is a circle. Fictionally a lump is right; visually
  it needs one thing to hook the eye. Unsolved.
- **Stumpsit** is a torso 6.8 wide carrying arms 3.0 wide, which is exactly the
  case `creature_sprites.md` names as beyond saving by edging. The proportions
  are wrong, not the renderer. Also unsolved, and easier: give it narrower arms.

## Not decided here

- **Stats.** No HP, Guard, speed or moves for the sixteen new creatures.
  `design/progression.md` showed how narrow the pillar-2 band is, and
  `design/encounters.md` now carries a four-step checklist for measuring one.
  Statting sixteen creatures without running that on the encounters they appear
  in would be inventing numbers, which is what tick 8 and tick 9 did.
- **Renaming the original four.** `design/creatures.md` says not until M3's
  fourth box is ticked, because four documents reference those ids and one of
  them is the balance solve. The rule they violate is recorded; the change is
  not urgent.
- **Where each one lives.** Place is written as a *kind* of place, not a region.
  Regions are M5 and do not exist.
