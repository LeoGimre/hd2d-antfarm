#!/usr/bin/env python3
"""limit.py — classify a finished tick.

    python3 farm/limit.py farm/logs/tick-0003.json

Prints one machine-readable line for run.sh to act on:

    OK|<cost>|<turns>|<summary>
    LIMIT|<resume-epoch>|<human>|<raw message>
    FAIL|<reason>

A usage limit is not a failed tick — it is a tick that never got to run. Treating
the two the same is what made the first run burn its remaining attempts on 300s
backoffs against a limit that still had hours left on it.
"""
import json
import os
import re
import sys
from datetime import datetime, timedelta

try:
    from zoneinfo import ZoneInfo
except ImportError:  # pragma: no cover - stdlib since 3.9
    ZoneInfo = None

# Buffer past the stated reset, because the server's clock is the one that counts.
GRACE_SECONDS = 150
# Never sleep longer than this off a single parse, however the message reads.
MAX_WAIT_SECONDS = 12 * 3600
# If the reset time cannot be read at all, wait this long and try again.
FALLBACK_WAIT_SECONDS = 1800
# A reset time this recently past is read as "already rolled over", not "tomorrow".
JUST_ELAPSED_HOURS = 6
# How soon to retry in that case. run.sh escalates if the limit is in fact still on.
RESUME_SOON_SECONDS = 120

LIMIT_PATTERNS = (
    r"session limit",
    r"usage limit",
    r"rate limit",
    r"limit reached",
    r"quota (?:exceeded|reached)",
    r"too many requests",
    r"overloaded",
)


def parse_reset_epoch(text, now=None):
    """Pull a reset time out of e.g. "resets 10:50pm (Europe/Oslo)".

    Returns (epoch, human) or (None, "") when the message has no time in it.
    """
    tz = None
    mtz = re.search(r"\(([A-Za-z]+/[A-Za-z_+\-]+)\)", text)
    if mtz and ZoneInfo is not None:
        try:
            tz = ZoneInfo(mtz.group(1))
        except Exception:
            tz = None

    now = now or datetime.now(tz)
    if now.tzinfo is None and tz is not None:
        now = now.replace(tzinfo=tz)

    m = re.search(
        r"reset(?:s|ting)?(?:\s+at)?\s+(\d{1,2})(?::(\d{2}))?\s*([ap]\.?m\.?)?",
        text,
        re.I,
    )
    if not m:
        return None, ""

    hour = int(m.group(1))
    minute = int(m.group(2) or 0)
    meridiem = (m.group(3) or "").replace(".", "").lower()
    if meridiem == "pm" and hour != 12:
        hour += 12
    elif meridiem == "am" and hour == 12:
        hour = 0
    if not (0 <= hour <= 23 and 0 <= minute <= 59):
        return None, ""

    target = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
    if target <= now:
        # The stated time has already passed. Two very different cases:
        #
        # It passed *just now* — the message was written minutes ago and the
        # window has since rolled over. The limit is already lifted, so rolling
        # forward a day would park the farm for 24 hours over nothing. This is
        # the common case, because we parse the message seconds after it is
        # written and reset times cluster near the current hour.
        #
        # It passed *long* ago — the clock or timezone is not what we assumed.
        # Then tomorrow's occurrence is the honest reading.
        if (now - target) <= timedelta(hours=JUST_ELAPSED_HOURS):
            return (now + timedelta(seconds=RESUME_SOON_SECONDS)).timestamp(), "just elapsed"
        target += timedelta(days=1)

    return target.timestamp(), target.strftime("%H:%M %Z").strip()


def classify(path):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        # The watchdog kills a hung tick before it writes anything at all.
        return "FAIL|tick produced no output (killed by the watchdog, or crashed)"

    try:
        with open(path) as f:
            d = json.load(f)
    except Exception as e:
        return f"FAIL|unparseable tick log: {e}"

    result = (d.get("result") or "").strip()
    cost = d.get("total_cost_usd", 0) or 0
    turns = d.get("num_turns", 0) or 0

    if d.get("is_error"):
        low = result.lower()
        if any(re.search(p, low) for p in LIMIT_PATTERNS):
            epoch, human = parse_reset_epoch(result)
            if epoch is None:
                epoch = datetime.now().timestamp() + FALLBACK_WAIT_SECONDS
                human = "unknown (fallback wait)"
            # Clamp, so a misparse can never park the farm for a day.
            epoch = min(epoch + GRACE_SECONDS,
                        datetime.now().timestamp() + MAX_WAIT_SECONDS)
            return f"LIMIT|{epoch:.0f}|{human}|{result}"
        return f"FAIL|{result[:200] or 'tick reported an error with no message'}"

    return f"OK|{cost:.4f}|{turns}|{result.replace(chr(10), ' ')[:160]}"


def main():
    if len(sys.argv) < 2:
        print("FAIL|no tick log given")
        return 0
    print(classify(sys.argv[1]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
