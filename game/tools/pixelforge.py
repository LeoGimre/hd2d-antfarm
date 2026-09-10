#!/usr/bin/env python3
"""pixelforge — tiny dependency-free pixel-art generator.

Writes PNGs with nothing but the standard library, because this machine has no PIL and a
game that generates its own creature sprites shouldn't depend on one anyway.

This is the seed of the composable creature system (M4): sprites are authored as character
maps over a named palette, so a new creature is a data edit, not a drawing.
"""
import zlib, struct, hashlib, os, sys

# ---------------------------------------------------------------- png writer

def write_png(path, width, height, rgba_rows):
    """rgba_rows: list of height lists of (r,g,b,a) tuples."""
    raw = b"".join(
        b"\x00" + b"".join(struct.pack("BBBB", *px) for px in row) for row in rgba_rows
    )

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(png)
    return path

# ---------------------------------------------------------------- palettes

T = (0, 0, 0, 0)

TRAVELER = {
    ".": T,
    "K": (26, 20, 32, 255),      # outline, warm near-black
    "S": (232, 186, 148, 255),   # skin
    "s": (186, 138, 108, 255),   # skin shadow
    "H": (58, 92, 78, 255),      # cloak
    "h": (38, 62, 54, 255),      # cloak shadow
    "L": (86, 128, 104, 255),    # cloak highlight
    "A": (168, 74, 62, 255),     # scarf accent
    "B": (96, 64, 48, 255),      # boots
    "b": (64, 42, 34, 255),      # boot shadow
}

def render_map(rows, palette, name="sprite"):
    w = max(len(r) for r in rows)
    for i, r in enumerate(rows):
        if len(r) != w:
            raise SystemExit(f"{name}: row {i} is {len(r)} chars, expected {w}\n  {r!r}")
    out = []
    for r in rows:
        out.append([palette[c] for c in r])
    return w, len(rows), out

# ---------------------------------------------------------------- the traveler

HERO = [
    "........................",
    "........KKKKKKKK........",
    ".......KHHHHHHHHK.......",
    ".......KHLLLLLLHK.......",
    "......KHHHHHHHHHHK......",
    "...KKKKHHHHHHHHHHKKKK...",
    "..KHHHHHHHHHHHHHHHHHHK..",
    "..KhhhhhhhhhhhhhhhhhhK..",
    "...KKKKKKKKKKKKKKKKKK...",
    "........KKSSSSKK........",
    "........KSSSSSSK........",
    "........KSKSSKSK........",
    "........KSSSSSSK........",
    "........KSsssssK........",
    ".........KKSSKK.........",
    ".......KAAAAAAAAK.......",
    "......KAAAAAAAAAAK......",
    ".....KHHHHHHHHHHHHK.....",
    "....KHHHHHHHHHHHHHHK....",
    "....KHHLHHHHHHHHhhHK....",
    "....KHLLHHHHHHHHhhHK....",
    "....KHLLHHHHHHHHhhHK....",
    "....KHHHHHHHHHHHhhHK....",
    "....KHHHHHHHHHHHhhHK....",
    "....KHHHHHHHHHHHhhHK....",
    ".....KHHHHHHHHHhhHK.....",
    ".....KHHHHHHHHHhhHK.....",
    ".....KKHHHHHHHHhhKK.....",
    "......KBBBKKKBBBBK......",
    "......KBBBK.KBBBBK......",
    "......KbbbK.KbbbbK......",
    "......KKKKK.KKKKKK......",
]

# ---------------------------------------------------------------- walk cycle
#
# The cloak covers most of the legs, so a convincing stride doesn't need new
# poses — shifting the boot row block sideways under the hem reads as a foot
# stepping without redrawing anything above it.

BOOT_ROW_START = 28
BOOT_ROW_END = 31


def _shift_row(row, delta):
    if delta > 0:
        return ("." * delta) + row[:-delta]
    if delta < 0:
        d = -delta
        return row[d:] + ("." * d)
    return row


def walk_frame(base_rows, delta):
    rows = list(base_rows)
    for i in range(BOOT_ROW_START, BOOT_ROW_END + 1):
        rows[i] = _shift_row(rows[i], delta)
    return rows


# ---------------------------------------------------------------- tiles
#
# Per-pixel random noise looks like television static, not ground, and its high
# frequency also wrecks video bitrate. Real pixel-art ground is *coherent*:
# low-frequency patches with sparse detail on top. So: value noise for the
# patches, explicit masonry for stone.

def _rand(x, y, seed, salt=b""):
    h = hashlib.md5(salt + struct.pack(">iii", int(x), int(y), seed)).digest()
    return h[0] / 255.0


def value_noise(size, cells, seed, salt=b""):
    """Tileable smoothed value noise. `cells` must divide `size`."""
    step = size / float(cells)
    out = [[0.0] * size for _ in range(size)]
    for y in range(size):
        for x in range(size):
            fx, fy = x / step, y / step
            x0, y0 = int(fx), int(fy)
            tx, ty = fx - x0, fy - y0
            sx = tx * tx * (3 - 2 * tx)      # smoothstep, so patches blend
            sy = ty * ty * (3 - 2 * ty)
            v00 = _rand(x0 % cells, y0 % cells, seed, salt)
            v10 = _rand((x0 + 1) % cells, y0 % cells, seed, salt)
            v01 = _rand(x0 % cells, (y0 + 1) % cells, seed, salt)
            v11 = _rand((x0 + 1) % cells, (y0 + 1) % cells, seed, salt)
            a = v00 + (v10 - v00) * sx
            b = v01 + (v11 - v01) * sx
            out[y][x] = a + (b - a) * sy
    return out


def grass_tile(size=32, seed=7):
    """Clustered greens with sparse blade marks."""
    shades = [
        (62, 94, 56, 255),
        (72, 106, 62, 255),
        (82, 118, 68, 255),
        (94, 130, 76, 255),
    ]
    blade = (54, 84, 50, 255)
    tip = (112, 148, 88, 255)
    n = value_noise(size, 4, seed, b"grass")
    rows = []
    for y in range(size):
        row = []
        for x in range(size):
            idx = min(int(n[y][x] * len(shades)), len(shades) - 1)
            c = shades[idx]
            d = _rand(x, y, seed + 991, b"gdetail")
            if d > 0.976:
                c = tip
            elif d < 0.034:
                c = blade
            row.append(c)
        rows.append(row)
    return rows


def stone_tile(size=32, seed=13, brick_w=16, brick_h=8):
    """Offset masonry. Reads as cobble at distance; UV stretch can't turn it
    into planks the way flat noise did."""
    mortar = (72, 68, 64, 255)
    shades = [
        (104, 99, 92, 255),
        (116, 110, 103, 255),
        (128, 122, 114, 255),
        (139, 133, 124, 255),
    ]
    hilite = (154, 148, 139, 255)
    rows = []
    for y in range(size):
        row = []
        band = y // brick_h
        offset = (brick_w // 2) * (band % 2)
        for x in range(size):
            bx = (x + offset) % size
            in_mortar = (y % brick_h == brick_h - 1) or (bx % brick_w == brick_w - 1)
            if in_mortar:
                row.append(mortar)
                continue
            bid_x = bx // brick_w
            r = _rand(bid_x, band, seed, b"brick")
            idx = min(int(r * len(shades)), len(shades) - 1)
            c = shades[idx]
            # top edge of each brick catches a little light
            if y % brick_h == 0:
                c = hilite
            elif _rand(x, y, seed + 17, b"grain") > 0.93:
                c = shades[min(idx + 1, len(shades) - 1)]
            row.append(c)
        rows.append(row)
    return rows


# ---------------------------------------------------------------- main

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    made = []

    w, h, px = render_map(HERO, TRAVELER, "hero-idle")
    made.append(write_png(os.path.join(root, "assets/sprites/traveler_idle.png"), w, h, px))

    w, h, px = render_map(walk_frame(HERO, -1), TRAVELER, "hero-walk-a")
    made.append(write_png(os.path.join(root, "assets/sprites/traveler_walk_a.png"), w, h, px))

    w, h, px = render_map(walk_frame(HERO, 1), TRAVELER, "hero-walk-b")
    made.append(write_png(os.path.join(root, "assets/sprites/traveler_walk_b.png"), w, h, px))

    g = grass_tile(32, 7)
    made.append(write_png(os.path.join(root, "assets/textures/grass.png"), 32, 32, g))

    s = stone_tile(32, 13)
    made.append(write_png(os.path.join(root, "assets/textures/stone.png"), 32, 32, s))

    for m in made:
        print(f"  {os.path.relpath(m, root)}  ({os.path.getsize(m)} bytes)")

if __name__ == "__main__":
    main()
