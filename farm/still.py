#!/usr/bin/env python3
"""still.py — keep one frame from a capture, so a devlog entry can show it.

    python3 farm/still.py battle_demo qc-02 sprites-on-the-board

Why this exists: farm/capture.sh produces a clip and farm/publish.py uploads it,
but publish.py wants AWS_ENDPOINT_URL_S3 and keys out of a gitignored farm/.env
that does not exist in a cloud container. Three visual ticks in a row produced
good captures nobody could see, and their entries went out text-only.

A still is not a clip and does not pretend to be one. It is one frame, chosen
deliberately, small enough to commit, published by the site at /stills/<name>.jpg
the same way the HUD mockups are. The site is deployed by Vercel straight out of
this repository (vercel.json), so a committed still is a live one.

JPEG at q:v 3 rather than the source PNG: 100KB against 380KB, and at 1280x720
the two are indistinguishable — checked by looking, which is the only way that
claim is worth anything. Do not lower the quality further; the creature sprites
are the first thing that starts ringing.

One or two per tick. farm/agreements.py fails on a still no devlog entry
references, so this stays a record rather than a dumping ground.
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STILLS = os.path.join(ROOT, "farm", "stills")
QUALITY = "3"


def main():
    if len(sys.argv) != 4:
        print(__doc__.strip().splitlines()[2].strip())
        return 2
    demo, frame, name = sys.argv[1:]
    src = os.path.join(ROOT, "farm", "out", demo, frame + ".png")
    if not os.path.exists(src):
        print("still: no such frame: %s" % src)
        print("       capture first: ./farm/capture.sh %s" % demo)
        return 2
    ffmpeg = os.environ.get("FFMPEG_BIN") or "ffmpeg"
    os.makedirs(STILLS, exist_ok=True)
    dest = os.path.join(STILLS, name + ".jpg")
    r = subprocess.run([ffmpeg, "-y", "-loglevel", "error", "-i", src,
                        "-q:v", QUALITY, dest], capture_output=True, text=True)
    if r.returncode != 0:
        print("still: ffmpeg failed: %s" % r.stderr.strip().splitlines()[-1:])
        return 1
    print("%s  (%d KB)" % (dest, os.path.getsize(dest) // 1024))
    print("")
    print("paste into the devlog entry, and set `still: true` in its frontmatter:")
    print("")
    print("![describe what the frame shows](/stills/%s.jpg)" % name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
