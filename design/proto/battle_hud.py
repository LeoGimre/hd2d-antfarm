#!/usr/bin/env python3
"""Draw the battle HUD from real solver state.

design/capture.md's finding is that the window in which a creature can be taken
rather than killed is nought to two decisions wide in every encounter, which
makes "does the player notice the Offer" a design question rather than a polish
one. A question about noticing cannot be settled in prose. So this renders the
board at every player decision along a real line, out of `combat_solver`'s own
state rather than out of an imagination, and the frames are the argument.

    python3 design/proto/battle_hud.py --encounter first_blood
    python3 design/proto/battle_hud.py --encounter kiln_duel --strip

Frames land in design/proto/mockups/ and the site publishes them at /mockups/.
Nothing here is engine code: it is a drawing of what game/scenes/battle.tscn has
to end up showing, made checkable by being generated from the same numbers.
"""

import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

GAME_TOOLS = os.path.join(HERE, "..", "..", "game", "tools")
sys.path.insert(0, GAME_TOOLS)

import combat_solver as S            # noqa: E402
import creature_forge as F           # noqa: E402  (game/tools/, ported at tick 60)

OUT = os.environ.get("HUD_OUT", os.path.join(HERE, "mockups"))
SPRITES = os.path.join(HERE, "..", "..", "game", "assets", "sprites", "creatures")

W, H = 360, 200                      # 16:9-ish at pixel-art scale
SCALE = 3

# ------------------------------------------------------------------ palette
# Warmed toward the Kiln Yards' key colour from design/proto/regions.json, so
# the mockup is not a grey UI study floating in nowhere.
SKY_TOP = (52, 40, 44)
SKY_BOT = (96, 62, 48)
GROUND = (44, 33, 33)
GROUND_LIT = (74, 52, 42)
INK = (22, 17, 20)
PAPER = (238, 228, 214)
DIM = (150, 138, 132)
HP_FULL = (126, 196, 120)
HP_LOW = (206, 96, 84)
GUARD = (150, 190, 224)
GUARD_GONE = (70, 66, 74)
CHARGE = (250, 206, 108)
OFFER = (250, 226, 140)
BROKEN = (232, 128, 96)

# ------------------------------------------------------------------ 3x5 font
# Small enough that a name fits under a 40px sprite, which is the constraint
# that picked the size. Unknown glyphs draw blank rather than raising: a HUD
# that crashes on a creature name is worse than one that eats it.
GLYPHS = {
    "A": "XXX,X.X,XXX,X.X,X.X", "B": "XX.,X.X,XX.,X.X,XX.",
    "C": "XXX,X..,X..,X..,XXX", "D": "XX.,X.X,X.X,X.X,XX.",
    "E": "XXX,X..,XX.,X..,XXX", "F": "XXX,X..,XX.,X..,X..",
    "G": "XXX,X..,X.X,X.X,XXX", "H": "X.X,X.X,XXX,X.X,X.X",
    "I": "XXX,.X.,.X.,.X.,XXX", "J": "..X,..X,..X,X.X,XXX",
    "K": "X.X,X.X,XX.,X.X,X.X", "L": "X..,X..,X..,X..,XXX",
    "M": "X.X,XXX,XXX,X.X,X.X", "N": "XX.,X.X,X.X,X.X,X.X",
    "O": "XXX,X.X,X.X,X.X,XXX", "P": "XXX,X.X,XXX,X..,X..",
    "Q": "XXX,X.X,X.X,XXX,..X", "R": "XXX,X.X,XX.,X.X,X.X",
    "S": "XXX,X..,XXX,..X,XXX", "T": "XXX,.X.,.X.,.X.,.X.",
    "U": "X.X,X.X,X.X,X.X,XXX", "V": "X.X,X.X,X.X,X.X,.X.",
    "W": "X.X,X.X,XXX,XXX,X.X", "X": "X.X,X.X,.X.,X.X,X.X",
    "Y": "X.X,X.X,XXX,.X.,.X.", "Z": "XXX,..X,.X.,X..,XXX",
    "0": "XXX,X.X,X.X,X.X,XXX", "1": ".X.,XX.,.X.,.X.,XXX",
    "2": "XXX,..X,XXX,X..,XXX", "3": "XXX,..X,XXX,..X,XXX",
    "4": "X.X,X.X,XXX,..X,..X", "5": "XXX,X..,XXX,..X,XXX",
    "6": "XXX,X..,XXX,X.X,XXX", "7": "XXX,..X,..X,..X,..X",
    "8": "XXX,X.X,XXX,X.X,XXX", "9": "XXX,X.X,XXX,..X,XXX",
    " ": "...,...,...,...,...", "-": "...,...,XXX,...,...",
    "/": "..X,..X,.X.,X..,X..", "!": ".X.,.X.,.X.,...,.X.",
    ".": "...,...,...,...,.X.", ":": "...,.X.,...,.X.,...",
    "+": "...,.X.,XXX,.X.,...", "?": "XXX,..X,.XX,...,.X.",
}


def text_w(s):
    return max(0, len(s) * 4 - 1)


def text(px, x, y, s, col):
    for ch in s.upper():
        g = GLYPHS.get(ch)
        if g:
            for row, bits in enumerate(g.split(",")):
                for col_i, b in enumerate(bits):
                    if b == "X":
                        put(px, x + col_i, y + row, col)
        x += 4


# ------------------------------------------------------------------ drawing
def put(px, x, y, col):
    if 0 <= x < W and 0 <= y < H:
        px[y][x] = col


def rect(px, x, y, w, h, col):
    for j in range(y, y + h):
        for i in range(x, x + w):
            put(px, i, j, col)


def frame_rect(px, x, y, w, h, col):
    for i in range(x, x + w):
        put(px, i, y, col)
        put(px, i, y + h - 1, col)
    for j in range(y, y + h):
        put(px, x, j, col)
        put(px, x + w - 1, j, col)


def mix(a, b, t):
    return tuple(int(a[k] + (b[k] - a[k]) * t) for k in range(3))


def background():
    px = [[SKY_TOP] * W for _ in range(H)]
    horizon = 96
    for y in range(H):
        if y < horizon:
            px[y] = [mix(SKY_TOP, SKY_BOT, y / horizon)] * W
        else:
            t = (y - horizon) / (H - horizon)
            px[y] = [mix(GROUND_LIT, GROUND, t)] * W
    # A soft pool of kiln light on the floor, so the board reads as a place.
    for y in range(horizon, H):
        for x in range(W):
            d = ((x - W * 0.52) / 150.0) ** 2 + ((y - 150) / 60.0) ** 2
            if d < 1.0:
                px[y][x] = mix(px[y][x], (120, 82, 58), 0.35 * (1.0 - d))
    return px


_SPRITE_CACHE = {}
_BOUNDS_CACHE = {}


def bounds(cid):
    """Opaque bounding box of a sprite, in sprite-local pixels. Everything that
    points at a creature — the cursor, the Offer tick, the quiet marker — has
    to point at its body, not at the transparent box the body was drawn in."""
    if cid not in _BOUNDS_CACHE:
        img = sprite(cid)
        if img is None:
            _BOUNDS_CACHE[cid] = (0, 0, 40, 44)
        else:
            w, h, rows = img
            xs = [x for y in range(h) for x in range(w) if rows[y][x][3]]
            ys = [y for y in range(h) for x in range(w) if rows[y][x][3]]
            _BOUNDS_CACHE[cid] = ((min(xs), min(ys), max(xs) + 1, max(ys) + 1)
                                  if xs else (0, 0, w, h))
    return _BOUNDS_CACHE[cid]


def place(cid, side, slot):
    """Sprite top-left such that the body's feet land on the slot anchor."""
    fx, fy = SLOT_FEET[(side, slot)]
    x0, _y0, x1, y1 = bounds(cid)
    return fx - (x0 + x1) // 2, fy - y1


def sprite(cid):
    if cid not in _SPRITE_CACHE:
        path = os.path.join(SPRITES, "%s.png" % cid)
        _SPRITE_CACHE[cid] = F.read_png(path) if os.path.exists(path) else None
    return _SPRITE_CACHE[cid]


def blit(px, img, ox, oy, tint=None, alpha=1.0):
    if img is None:
        return
    w, h, rows = img
    for y in range(h):
        for x in range(w):
            p = rows[y][x]
            if p[3] == 0:
                continue
            c = p[:3]
            if tint is not None:
                c = mix(c, tint, 0.45)
            if alpha < 1.0:
                c = mix(px[min(H - 1, max(0, oy + y))][min(W - 1, max(0, ox + x))], c, alpha)
            put(px, ox + x, oy + y, c)


def shadow(px, cx, cy, rx, ry):
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            if 0 <= x < W and 0 <= y < H:
                d = ((x - cx) / float(rx)) ** 2 + ((y - cy) / float(ry)) ** 2
                if d <= 1.0:
                    px[y][x] = mix(px[y][x], (20, 14, 16), 0.45 * (1.0 - d))


# ------------------------------------------------------------------ hud bits
def bar(px, x, y, w, frac, col, back=(40, 34, 38)):
    rect(px, x, y, w, 3, back)
    rect(px, x, y, max(0, int(round(w * frac))), 3, col)
    frame_rect(px, x - 1, y - 1, w + 2, 5, INK)


def pips(px, x, y, n, filled, col, empty=GUARD_GONE):
    for k in range(n):
        rect(px, x + k * 5, y, 4, 4, col if k < filled else empty)
        frame_rect(px, x + k * 5 - 1, y - 1, 6, 6, INK)


def plate(px, x, y, w, h):
    """A dark card behind text. The pixel-art background is busy enough that
    unbacked type disappears into it — found by looking, not by reasoning."""
    for j in range(y, y + h):
        for i in range(x, x + w):
            if 0 <= i < W and 0 <= j < H:
                px[j][i] = mix(px[j][i], INK, 0.72)
    frame_rect(px, x, y, w, h, mix(INK, PAPER, 0.18))


# ------------------------------------------------------------------ the board
# Player left, enemy right; Back slots pushed up and away, which is the whole
# reason the Front/Back reach rule is legible at a glance.
# Spread wider than the first pass, which put the nameplates on top of each
# other's sprites — legible in isolation and a mess on the board. Looked at,
# then moved.
# Anchors are FEET, not sprite corners. The art is drawn with headroom inside a
# 40x44 box, so anchoring by the box put the target cursor a body-length above
# the creature it was pointing at. Looked at, then fixed.
SLOT_FEET = {
    ("player", "back"): (66, 116),
    ("player", "front"): (112, 152),
    ("enemy", "back"): (300, 106),
    ("enemy", "front"): (250, 146),
}
# Back-row creatures are the same size — billboards in an HD-2D diorama do not
# shrink much over four metres — so depth is carried by height and by air.
BACK_HAZE = 0.22


def draw_creature(px, i, s, offerable, cursor):
    cs, _pc, _ec, _qs, _seen, taken = S.unpack(s)
    cid, slot, hp, guard, broken, dead, _nm = cs[i]
    side = S.side_of(i)
    if taken[i]:
        side = "player"
    c = S.CREATURES[cid]
    name = c["display_name"]
    fx, fy = SLOT_FEET[(side, slot)]
    x, y = place(cid, side, slot)
    bx0, by0, bx1, _by1 = bounds(cid)
    top = y + by0
    bw_sprite = bx1 - bx0

    if dead:
        shadow(px, fx, fy, 14, 3)
        text(px, fx - text_w(name) // 2, fy + 4, name, DIM)
        return

    shadow(px, fx, fy, 15, 4)
    tint = BROKEN if broken else (SKY_BOT if slot == "back" else None)
    blit(px, sprite(cid), x, y, tint=tint)

    # Nameplate under the feet, so the sprite is never occluded by its own HUD.
    bw = max(text_w(name) + 8, 46)
    bx = max(2, min(W - bw - 2, fx - bw // 2))
    by = fy + 4
    plate(px, bx, by, bw, 21)
    text(px, bx + 4, by + 3, name, PAPER if side == "player" else DIM)
    bar(px, bx + 4, by + 11, bw - 8, hp / float(c["max_hp"]),
        HP_FULL if hp > c["max_hp"] * 0.35 else HP_LOW)
    pips(px, bx + 4, by + 16, c["max_guard"], guard, GUARD)

    if broken:
        t = "BROKEN"
        plate(px, fx - (text_w(t) + 6) // 2, top - 13, text_w(t) + 6, 11)
        text(px, fx - text_w(t) // 2, top - 10, t, BROKEN)

    if cursor:
        # The target cursor. Two brackets rather than a box: a box around a
        # 40px sprite eats the silhouette, and design/creature_sprites.md says
        # only the silhouette reads.
        l, r_, t_, b_ = fx - bw_sprite // 2 - 4, fx + bw_sprite // 2 + 3, top - 4, fy + 3
        for k in range(6):
            put(px, l, t_ + k, PAPER); put(px, r_, t_ + k, PAPER)
            put(px, l, b_ - k, PAPER); put(px, r_, b_ - k, PAPER)
            put(px, l + k, t_, PAPER); put(px, r_ - k, t_, PAPER)
            put(px, l + k, b_, PAPER); put(px, r_ - k, b_, PAPER)

    if offerable and cursor:
        # The one thing this whole mockup exists to test. Brightest object on
        # screen, and attached to the creature rather than to a menu, because
        # the subject of the decision is the creature.
        #
        # Only ever ONE of these. The first pass drew a banner over every
        # offerable enemy and two of them appeared at once, which is not an
        # unmissable signal, it is two signals competing. So the banner rides
        # the target cursor and the others get the quiet marker below.
        t = "OFFER  " + name
        pw = text_w(t) + 10
        pxx = min(W - pw - 2, max(2, fx - pw // 2))
        pyy = max(20, top - 24)
        rect(px, pxx, pyy, pw, 13, OFFER)
        frame_rect(px, pxx, pyy, pw, 13, INK)
        text(px, pxx + 5, pyy + 4, t, INK)
        for k in range(pyy + 13, top - 5):       # a tick down to the creature
            put(px, fx, k, OFFER)
    elif offerable:
        # Available here too, said quietly: three rising pips, no words.
        for k in range(3):
            rect(px, fx - 3 + k * 3, top - 8 - k * 2, 2, 2, OFFER)


def draw_queue(px, s):
    """The turn order, because the queue is deterministic and a player who
    cannot read it is playing a random game with extra steps."""
    order = S.upcoming(s, 6)
    plate(px, 4, 4, 128, 13)
    text(px, 7, 7, "NEXT", DIM)
    x = 7 + text_w("NEXT") + 5
    for k, i in enumerate(order):
        nm = S.CREATURES[S.unpack(s)[0][i][0]]["display_name"][:4]
        col = PAPER if S.side_of(i) == "player" else BROKEN
        if k == 0:
            rect(px, x - 2, 6, text_w(nm) + 4, 9, mix(INK, PAPER, 0.25))
        text(px, x, 8, nm, col)
        x += text_w(nm) + 6


def draw_charges(px, s):
    _cs, pc, _ec, _qs, _seen, _taken = S.unpack(s)
    plate(px, 4, 20, 92, 16)
    text(px, 7, 24, "CHARGE", PAPER)
    pips(px, 8 + text_w("CHARGE") + 4, 24, 3, pc, CHARGE)
    if pc >= S.OFFER_COST:
        text(px, 7, 31, "ENOUGH TO OFFER", OFFER)


ACTIONS = ["ATTACK", "RANGED", "SWAP", "OFFER"]


def draw_actions(px, s, offer_live):
    """The menu, drawn only so the mockup can make the argument capture.md
    actually needs: this row is NOT the announcement. OFFER ungreying down here
    is the failure mode — a change in a corner the player is not looking at."""
    _cs, pc, _ec, _qs, _seen, _taken = S.unpack(s)
    bw, x0, y0 = 62, W - 66, H - 60
    plate(px, x0 - 4, y0 - 4, bw + 8, len(ACTIONS) * 10 + 8)
    for k, a in enumerate(ACTIONS):
        live = offer_live if a == "OFFER" else True
        if a == "SWAP" and S.slot_index("player", "back") is None:
            live = False
        y = y0 + k * 10
        if a == "OFFER" and offer_live:
            rect(px, x0 - 2, y - 2, bw + 4, 10, mix(INK, OFFER, 0.30))
        text(px, x0, y, a, PAPER if live else GUARD_GONE)
        if a == "OFFER":
            text(px, x0 + bw - text_w("%dC" % S.OFFER_COST), y,
                 "%dC" % S.OFFER_COST, CHARGE if pc >= S.OFFER_COST else GUARD_GONE)


def draw_caption(px, label):
    plate(px, W - text_w(label) - 12, H - 16, text_w(label) + 10, 12)
    text(px, W - text_w(label) - 7, H - 13, label, PAPER)


def render_frame(s, label):
    px = background()
    n = len(S.TEAM)
    offerable = {i for i in range(n) if S.side_of(i) == "enemy" and S.offer_ok(s, i)}
    # Back slots first so a Front creature overlaps the one behind it.
    order = sorted(range(n), key=lambda i: SLOT_FEET[
        ("player" if S.unpack(s)[5][i] else S.side_of(i), S.unpack(s)[0][i][1])][1])
    cursor = None
    if offerable:
        cursor = sorted(offerable, key=lambda i: S.unpack(s)[0][i][1] != "front")[0]
    else:
        fronts = [i for i in range(n) if S.side_of(i) == "enemy"
                  and S.unpack(s)[0][i][1] == "front" and not S.unpack(s)[0][i][5]]
        cursor = fronts[0] if fronts else None
    for i in order:
        draw_creature(px, i, s, i in offerable, i == cursor)
    draw_queue(px, s)
    draw_charges(px, s)
    draw_actions(px, s, bool(offerable))
    draw_caption(px, label)
    return px


def upscale(px, k):
    out = []
    for row in px:
        r = []
        for p in row:
            r.extend([p + (255,) if len(p) == 3 else p] * k)
        for _ in range(k):
            out.append(list(r))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--encounter", default=None, choices=sorted(S.ENCOUNTERS),
                    help="default: every encounter that has a capture line")
    ap.add_argument("--scale", type=int, default=SCALE)
    args = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    names = [args.encounter] if args.encounter else sorted(S.ENCOUNTERS)
    made = []
    for name in names:
        S.set_encounter(name)
        made += render_encounter(name, args.scale) or []
    return made


def render_encounter(name, scale):
    target = S.enemy_slots()[0][0]
    line, _ = S._deepen(lambda d: S.search_capture(target, True, d), 14)
    if line is None:
        print("%s: no capture line, nothing to draw" % name)
        return []

    made = []
    s = S.initial()
    for k, (_who, c) in enumerate(line):
        s, i = S.run_to_player_choice(s)
        if i is None:
            break
        open_now = any(S.offer_ok(s, ti) for ti, _t in S.enemy_slots())
        label = "DECISION %d%s" % (k + 1, "   OFFER OPEN" if open_now else "")
        px = upscale(render_frame(s, label), scale)
        p = os.path.join(OUT, "%s_d%d.png" % (name, k + 1))
        F.write_png(p, W * scale, H * scale, px)
        made.append(p)
        print(p)
        s = S.apply_choice(s, i, c)
    return made


if __name__ == "__main__":
    main()
