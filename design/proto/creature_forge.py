#!/usr/bin/env python3
"""creature_forge — PROTOTYPE for M4's composable creature sprite system.

This is a design artifact, not shipped game code. It lives in design/ because it
is the evidence for design/creature_sprites.md: a sprite grammar is only worth
believing if the generator that implements it has been run and looked at, and
this is the generator that was run. Porting it into game/tools/ (and generating
real assets, which need `godot --headless --import` afterwards) is an engine
tick's job; the container this was written in has no Godot, so it could not be
done here.

Run it:
    python3 design/proto/creature_forge.py            # writes PNGs to /tmp
    python3 design/proto/creature_forge.py --sheet    # ...plus a scaled sheet

The claim it exists to test: a creature is (body plan, proportions, palette,
features), and that is enough to make sixty creatures read as sixty creatures.
"""
import sys, os, math, colorsys, zlib, struct

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "..", "game", "tools"))
from pixelforge import write_png  # noqa: E402  (the project's own PNG writer)

W, H = 40, 44
EMPTY, FILL, FAR = ".", "#", "="

# ---------------------------------------------------------------- canvas

def blank():
    return [[EMPTY] * W for _ in range(H)]

def put(g, x, y, ch=FILL):
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = ch

def ellipse(g, cx, cy, rx, ry, ch=FILL):
    for y in range(int(cy - ry), int(cy + ry) + 1):
        for x in range(int(cx - rx), int(cx + rx) + 1):
            if rx <= 0 or ry <= 0:
                continue
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                put(g, x, y, ch)

def taper(g, x0, y0, x1, y1, w0, w1, ch=FILL):
    """A limb: a line from (x0,y0) to (x1,y1) whose half-width lerps w0 -> w1."""
    steps = int(max(abs(x1 - x0), abs(y1 - y0), 1)) * 3
    for i in range(steps + 1):
        t = i / steps
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t
        w = w0 + (w1 - w0) * t
        ellipse(g, x, y, w, w, ch)

# ---------------------------------------------------------------- palette

def ramp(hue, sat, name=""):
    """Five roles from one hue: outline, shadow, base, light, spec.
    Hue drifts warm into the light and cool into the shadow, which is what stops
    a generated ramp from looking like a brightness slider."""
    def rgb(h, s, v):
        r, g, b = colorsys.hsv_to_rgb(h % 1.0, max(0.0, min(1.0, s)), max(0.0, min(1.0, v)))
        return (int(r * 255), int(g * 255), int(b * 255), 255)
    return {
        "K": rgb(hue - 0.04, min(1.0, sat * 0.9), 0.13),   # outline
        "d": rgb(hue - 0.03, min(1.0, sat * 1.05), 0.38),  # shadow
        "m": rgb(hue,        sat,                  0.62),  # base
        "l": rgb(hue + 0.02, sat * 0.80,           0.82),  # light
        "s": rgb(hue + 0.04, sat * 0.55,           0.97),  # spec
        ".": (0, 0, 0, 0),
    }

# ---------------------------------------------------------------- finishing

def outline(g):
    out = [row[:] for row in g]
    for y in range(H):
        for x in range(W):
            if g[y][x] != EMPTY:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < W and 0 <= ny < H and g[ny][nx] not in (EMPTY, "K"):
                    out[y][x] = "K"
                    break
    return out

def depth(g):
    """Chebyshev distance from the silhouette edge, for every filled pixel."""
    d = [[0] * W for _ in range(H)]
    filled = {(x, y) for y in range(H) for x in range(W) if g[y][x] not in (EMPTY, "K")}
    frontier = {(x, y) for (x, y) in filled
                if any((x + dx, y + dy) not in filled
                       for dx in (-1, 0, 1) for dy in (-1, 0, 1))}
    for (x, y) in frontier:
        d[y][x] = 1
    cur, n = frontier, 1
    while cur:
        n += 1
        nxt = set()
        for (x, y) in cur:
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    p = (x + dx, y + dy)
                    if p in filled and d[p[1]][p[0]] == 0:
                        d[p[1]][p[0]] = n
                        nxt.add(p)
        cur = nxt
    return d

def shade(g, light=(-0.6, -0.8)):
    """Pick a ramp role per filled pixel: rim-lit toward the light, dark away
    from it, base in the interior. One light direction for the whole roster is
    deliberate -- pillar 6 wants every frame to read as one lit diorama, and a
    creature lit from its own private angle breaks that instantly."""
    d = depth(g)
    out = [row[:] for row in g]
    cx = sum(x for y in range(H) for x in range(W) if g[y][x] == FILL) or 1
    n = sum(1 for y in range(H) for x in range(W) if g[y][x] == FILL) or 1
    cx /= n
    cy = sum(y for y in range(H) for x in range(W) if g[y][x] == FILL) / n
    lx, ly = light
    for y in range(H):
        for x in range(W):
            ch = g[y][x]
            if ch not in (FILL, FAR):
                continue
            if ch == FAR:
                # Anything on the far side of the body is flat and dark. Real
                # sprite artists do exactly this rather than shading the far
                # limb properly: the point is separation, not description.
                out[y][x] = "d"
                continue
            # dot of (pixel -> centre) against the light: >0 means facing it
            vx, vy = x - cx, y - cy
            mag = math.hypot(vx, vy) or 1.0
            face = (vx / mag) * lx + (vy / mag) * ly
            dd = d[y][x]
            if dd <= 1 and face > 0.45:
                out[y][x] = "s"
            elif dd <= 2 and face > 0.1:
                out[y][x] = "l"
            elif dd <= 1 and face < -0.30:
                out[y][x] = "d"
            else:
                # Interior stays base tone whatever direction it faces. Letting
                # "away from the light" darken the interior too is what turned
                # four legs into one black mass: the legs are all below the
                # centroid, so every interior pixel in them read as shadow.
                # Shading belongs on edges; interiors carry the colour.
                out[y][x] = "m"
    return out

def render(g, palette, path):
    rows = [[palette.get(c, palette["."]) for c in row] for row in g]
    write_png(path, W, H, rows)
    return path

def to_text(g):
    return "\n".join("".join(r) for r in g)

# ---------------------------------------------------------------- body plans
#
# A body plan is a function of proportions, not a stored map. That is the whole
# trick: "per-species proportions" cannot be a parameter of a hand-drawn
# character map, because the map has already committed to its own.

GROUND = 39

def quadruped(p):
    g = blank()
    cx = p.get("cx", 19)
    leg = p["leg"]
    brx, bry = p["body_rx"], p["body_ry"]
    by = GROUND - leg - bry
    # Far pair first, in the FAR channel and offset back and up, then the torso
    # over them, then the near pair. Drawing order *is* depth here.
    for off in (-brx * 0.58, brx * 0.42):
        taper(g, cx + off - 1.6, by + bry * 0.4, cx + off - 2.2, GROUND - 1.5,
              p["leg_w"] * 0.9, p["leg_w"] * 0.66, FAR)
    ellipse(g, cx, by, brx, bry)
    for off in (-brx * 0.5, brx * 0.5):
        splay = p.get("splay", 0.0) * (1 if off > 0 else -1)
        taper(g, cx + off, by + bry * 0.5, cx + off + splay, GROUND,
              p["leg_w"], p["leg_w"] * 0.72)
    # neck + head, forward and up
    nx = cx + brx * 0.75
    ny = by - bry * 0.4
    hx = nx + p["neck"] * 0.72
    hy = ny - p["neck"] * 0.78
    taper(g, nx, ny, hx, hy, p["neck_w"], p["neck_w"] * 0.85)
    ellipse(g, hx, hy, p["head_r"] * 1.08, p["head_r"])
    if p.get("snout"):
        ellipse(g, hx + p["head_r"] * 0.95, hy + p["head_r"] * 0.25,
                p["snout"], p["snout"] * 0.7)
    # tail
    if p.get("tail"):
        taper(g, cx - brx * 0.9, by, cx - brx * 0.9 - p["tail"],
              by - p.get("tail_lift", 3), p["tail_w"], 0.6)
    return g, (hx, hy)

def serpent(p):
    g = blank()
    cx = p.get("cx", 12)
    n = p.get("coils", 22)
    # The tail sits *on* the ground. A serpent floating clear of it reads as a
    # stray brush stroke, which is exactly what the first pass looked like.
    px, py = cx, GROUND - p["body_w"] * 0.4
    for i in range(n):
        t = i / (n - 1)
        x = cx + t * p["length"]
        y = GROUND - math.sin(t * math.pi * p.get("waves", 1.4)) * p["amp"] - t * p.get("rise", 8)
        taper(g, px, py, x, y, p["body_w"] * (1 - 0.55 * t) , p["body_w"] * (1 - 0.55 * (t + 0.05)))
        px, py = x, y
    ellipse(g, px, py, p["head_r"] * 1.1, p["head_r"])
    return g, (px, py)

def avian(p):
    g = blank()
    cx = p.get("cx", 20)
    by = GROUND - p["leg"] - p["body_ry"]
    # far leg and far wing behind the body, near ones in front
    taper(g, cx - 1.8, by + p["body_ry"] * 0.5, cx - 2.6, GROUND - 1.5,
          p["leg_w"], p["leg_w"] * 0.8, FAR)
    taper(g, cx, by - p["body_ry"] * 0.2,
          cx - p["wing"] * 0.5, by - p["wing"] * 0.30,
          p["wing_w"] * 0.8, p["wing_w"] * 0.3, FAR)
    ellipse(g, cx, by, p["body_rx"], p["body_ry"])
    taper(g, cx + 0.6, by + p["body_ry"] * 0.6, cx + 0.6, GROUND,
          p["leg_w"], p["leg_w"] * 0.8)
    taper(g, cx + 1.0, by - p["body_ry"] * 0.35,
          cx - p["wing"] * 0.68, by - p["wing"] * 0.55,
          p["wing_w"], p["wing_w"] * 0.28)
    hx = cx + p["body_rx"] * 0.6
    hy = by - p["body_ry"] - p["head_r"] * 0.6
    taper(g, cx + p["body_rx"] * 0.3, by - p["body_ry"] * 0.5, hx, hy,
          p["neck_w"], p["neck_w"])
    ellipse(g, hx, hy, p["head_r"], p["head_r"])
    ellipse(g, hx + p["head_r"] * 1.1, hy + 0.4, p["beak"], p["beak"] * 0.55)
    return g, (hx, hy)

# ---------------------------------------------------------------- features

def crest(g, anchor, n, size, spread=2.0):
    hx, hy = anchor
    for i in range(n):
        t = (i / max(1, n - 1)) - 0.5
        taper(g, hx - 1 + t * spread, hy - size * 0.2,
              hx - 2 + t * spread * 2.2, hy - size, 1.0, 0.5)

def horns(g, anchor, length, spread=2.2):
    hx, hy = anchor
    for sign in (-1, 1):
        taper(g, hx + sign * spread * 0.5, hy - 1,
              hx + sign * spread * 1.3, hy - length, 1.1, 0.5)

def shell(g, anchor_body):
    cx, cy, rx, ry = anchor_body
    ellipse(g, cx, cy - ry * 0.35, rx * 1.05, ry * 0.95)

def eye(g, anchor, dx, dy, big=False):
    """Drawn after shading, never shaded. One dark pixel on a dark flank is
    invisible; an eye needs its own light field to sit in, and at this size
    that field is two pixels."""
    hx, hy = int(anchor[0] + dx), int(anchor[1] + dy)
    for ox in range(-1, 2 if big else 1):
        for oy in range(-1, 1):
            put(g, hx + ox, hy + oy, "s")
    put(g, hx, hy, "K")

def groove(g, cx, cy, rx, ry):
    """A one-pixel dark seam along the underside of an overlay part, so a shell
    or a plate reads as sitting *on* the body instead of merging into it."""
    import math as _m
    for a in range(0, 360, 4):
        t = _m.radians(a)
        x, y = cx + _m.cos(t) * rx, cy + _m.sin(t) * ry
        if g[int(y)][int(x)] if 0 <= int(y) < H and 0 <= int(x) < W else False:
            pass
        if 0 <= int(y) < H and 0 <= int(x) < W and g[int(y)][int(x)] not in (EMPTY, "K"):
            g[int(y)][int(x)] = "K"

# ---------------------------------------------------------------- roster

# Hue per type. One number per type is the whole of "type-coded palette".
HUE = {"Ember": 0.035, "Tide": 0.545, "Gale": 0.44, "Root": 0.28}
SAT = {"Ember": 0.85, "Tide": 0.72, "Gale": 0.40, "Root": 0.62}

ROSTER = {
  "emberling": dict(plan="quadruped", type="Ember", feats=["horns"], p=dict(
      body_rx=7.0, body_ry=4.6, leg=5, leg_w=1.7, neck=5, neck_w=1.9,
      head_r=3.2, snout=1.9, tail=6, tail_w=1.6, tail_lift=4, splay=0.6)),
  "rootshell": dict(plan="quadruped", type="Root", feats=["shell"], p=dict(
      body_rx=8.6, body_ry=5.6, leg=3, leg_w=2.4, neck=3, neck_w=2.2,
      head_r=3.0, snout=1.6, tail=3, tail_w=1.4, tail_lift=0, splay=1.2)),
  "tidalpup":  dict(plan="serpent", type="Tide", feats=["crest"], p=dict(
      length=21, amp=4.0, rise=11, body_w=3.6, head_r=3.6, waves=1.2, coils=24)),
  "galewing":  dict(plan="avian", type="Gale", feats=["crest"], p=dict(
      body_rx=5.4, body_ry=4.4, leg=6, leg_w=1.2, wing=13, wing_w=2.6,
      neck_w=1.6, head_r=2.8, beak=2.0)),
}

PLANS = {"quadruped": quadruped, "serpent": serpent, "avian": avian}

SHELLS = []

def build(cid, spec, outdir):
    SHELLS.clear()
    g, anchor = PLANS[spec["plan"]](spec["p"])
    for f in spec["feats"]:
        if f == "horns": horns(g, anchor, 4.0)
        elif f == "crest": crest(g, anchor, 3, 4.0, spread=1.6)
        elif f == "shell":
            pp = spec["p"]
            by = GROUND - pp["leg"] - pp["body_ry"]
            cxx = pp.get("cx", 19)
            shell(g, (cxx, by, pp["body_rx"], pp["body_ry"]))
            SHELLS.append((cxx, by - pp["body_ry"] * 0.35, pp["body_rx"] * 1.05, pp["body_ry"] * 0.95))
    g = shade(g)
    for sh in SHELLS:
        groove(g, *sh)
    eye(g, anchor, 1, 0, big=spec["p"].get("head_r", 3) >= 3.2)
    g = outline(g)
    pal = ramp(HUE[spec["type"]], SAT[spec["type"]])
    return render(g, pal, os.path.join(outdir, cid + ".png"))

OUT = os.environ.get("FORGE_OUT", "/tmp/creature_forge")
# ------------------------------------------------- looking at the result
#
# The whole point of this prototype is that somebody opened the output. A 40x44
# sprite is unreadable at 1:1 in any viewer, so --sheet composites the roster
# nearest-neighbour-scaled onto one image. Reading PNGs back needs a decoder,
# which is thirty lines and still cheaper than a dependency.

def read_png(path):
    data = open(path, "rb").read()
    pos, idat, w, h = 8, b"", 0, 0
    while pos < len(data):
        ln = struct.unpack(">I", data[pos:pos+4])[0]
        tag = data[pos+4:pos+8]
        body = data[pos+8:pos+8+ln]
        if tag == b"IHDR":
            w, h, bd, ct = struct.unpack(">IIBB", body[:10])
            assert bd == 8 and ct == 6, (bd, ct)
        elif tag == b"IDAT":
            idat += body
        pos += 12 + ln
    raw = zlib.decompress(idat)
    rows, stride, prev = [], w * 4, bytearray(w * 4)
    i = 0
    for _y in range(h):
        f = raw[i]; i += 1
        line = bytearray(raw[i:i+stride]); i += stride
        if f == 1:
            for x in range(4, stride): line[x] = (line[x] + line[x-4]) & 255
        elif f == 2:
            for x in range(stride): line[x] = (line[x] + prev[x]) & 255
        elif f == 3:
            for x in range(stride):
                a = line[x-4] if x >= 4 else 0
                line[x] = (line[x] + ((a + prev[x]) >> 1)) & 255
        elif f == 4:
            for x in range(stride):
                a = line[x-4] if x >= 4 else 0
                b = prev[x]; c = prev[x-4] if x >= 4 else 0
                pp = a + b - c
                pa, pb, pc = abs(pp-a), abs(pp-b), abs(pp-c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[x] = (line[x] + pr) & 255
        rows.append([tuple(line[x*4:x*4+4]) for x in range(w)])
        prev = line
    return w, h, rows

def sheet(paths, scale=8, pad=6, bg=(38, 42, 50, 255)):
    imgs = [read_png(p) for p in paths]
    cw = max(i[0] for i in imgs) * scale + pad * 2
    ch = max(i[1] for i in imgs) * scale + pad * 2
    W, H = cw * len(imgs), ch
    out = [[bg] * W for _ in range(H)]
    for k, (w, h, rows) in enumerate(imgs):
        ox = k * cw + pad
        for y in range(h):
            for x in range(w):
                px = rows[y][x]
                if px[3] == 0:
                    continue
                for sy in range(scale):
                    for sx in range(scale):
                        out[pad + y*scale + sy][ox + x*scale + sx] = px
    return W, H, out


def main():
    made = []
    for cid, spec in ROSTER.items():
        made.append(build(cid, spec, OUT))
        print(made[-1])
    if "--sheet" in sys.argv:
        w, h, px = sheet(made)
        print(write_png(os.path.join(OUT, "_sheet.png"), w, h, px))


if __name__ == "__main__":
    main()
