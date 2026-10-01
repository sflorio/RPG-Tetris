"""Draws a house kit into the spare corner of the Oryx atlas.

The pack has no buildings -- no roofs, no facades -- so the town's houses were composed from
dungeon wall tiles, and they read as what they are: a wall seen from above, with no ridge, no
eaves and no shadow. This generates the pieces the pack is missing, in its own palette and at its
own 24px grid: a shingled roof with a ridge and an overhanging eave, and a plastered wall with a
plinth, windows and a door.

The colours are sampled from the pack's terracotta brick and its stonework so the kit sits with
the rest of the sheet. The art itself is drawn here, which also keeps it clear of the Oryx licence.

Called by make_world_atlas.py; running this file directly repaints an existing atlas.
"""
import os, sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import oryx_atlas as oa

T = oa.TILE

# Where the kit lives in the atlas: an empty corner, well clear of the pack's own tiles.
ORIGIN_COL, ROOF_ROW, WALL_ROW, PROP_ROW = 64, 38, 39, 40

# Terracotta, read off the pack's brick wall.
R_CAP = (221, 158, 134)
R_LIGHT = (171, 103, 81)
R_BODY = (134, 80, 63)
R_LINE = (92, 53, 42)
R_FASCIA = (62, 38, 31)
R_EDGE = (36, 27, 25)

# Plaster and stone, read off the pack's grey walls.
W_LIGHT = (208, 199, 182)
W_BODY = (182, 171, 152)
W_SHADE = (141, 130, 113)
W_PLINTH = (120, 118, 116)
W_PLINTH_DARK = (86, 84, 83)
W_EDGE = (44, 39, 36)

TIMBER = (120, 78, 46)
TIMBER_DARK = (78, 48, 28)
GLASS = (64, 86, 110)
GLASS_LIT = (248, 212, 138)
HANDLE = (216, 182, 98)

COURSE = 6          # shingle course height
JOINT = 8           # shingle width


def _new():
    return Image.new("RGBA", (T, T), (0, 0, 0, 0))


def _tint(colour, factor):
    return tuple(min(255, max(0, int(c * factor))) for c in colour)


def _shingles(px, factor):
    """A field of tiles: each course lit along its top and falling into shadow where the course
    below laps under it, with staggered joints. The factor darkens a whole course band, which is
    what gives the roof its slope from ridge to eave."""
    ramp = [R_LIGHT, R_BODY, R_BODY, _tint(R_BODY, 0.90), _tint(R_BODY, 0.78), R_LINE]
    for y in range(T):
        colour = _tint(ramp[y % COURSE], factor)
        for x in range(T):
            px[x, y] = colour + (255,)
    for course in range(T // COURSE + 1):
        offset = 0 if course % 2 == 0 else JOINT // 2
        for x in range(offset, T, JOINT):
            for k in range(1, COURSE - 1):
                y = course * COURSE + k
                if 0 <= x < T and y < T:
                    px[x, y] = _tint(R_LINE, factor) + (255,)


SLOPE = {"ridge": 1.12, "slope": 1.0, "eave": 0.88}


def _roof(part, side):
    img = _new()
    px = img.load()
    _shingles(px, SLOPE[part])

    if part == "ridge":
        for x in range(T):
            px[x, 0] = R_EDGE + (255,)
            px[x, 1] = R_CAP + (255,)
            px[x, 2] = R_LIGHT + (255,)
            px[x, 3] = R_LINE + (255,)
    if part == "eave":
        for x in range(T):
            px[x, T - 5] = R_LINE + (255,)
            px[x, T - 4] = R_FASCIA + (255,)
            px[x, T - 3] = R_FASCIA + (255,)
            px[x, T - 2] = R_EDGE + (255,)
            px[x, T - 1] = R_EDGE + (255,)

    if side in ("left", "right"):
        xs = (0, 1) if side == "left" else (T - 1, T - 2)
        for y in range(T):
            px[xs[0], y] = R_EDGE + (255,)
            px[xs[1], y] = R_FASCIA + (255,)
    return img


def _wall_base(side, plinth, eave_shadow=True):
    img = _new()
    px = img.load()
    for y in range(T):
        for x in range(T):
            px[x, y] = W_BODY + (255,)
    if eave_shadow:
        # Only the course directly under the roof is in its shadow; repeating the band down a
        # two-storey wall stripes it.
        for y in range(3):
            for x in range(T):
                px[x, y] = W_SHADE + (255,)
        for x in range(T):
            px[x, 3] = W_LIGHT + (255,)
    if plinth:
        for x in range(T):
            px[x, T - 4] = W_SHADE + (255,)
            px[x, T - 3] = W_PLINTH + (255,)
            px[x, T - 2] = W_PLINTH_DARK + (255,)
            px[x, T - 1] = W_EDGE + (255,)
    if side in ("left", "right"):
        # Quoins: alternating stone blocks down the corner, so the wall has an edge rather than
        # just ending.
        x0 = 0 if side == "left" else T - 1
        inner = range(1, 5) if side == "left" else range(T - 5, T - 1)
        for y in range(T):
            px[x0, y] = W_EDGE + (255,)
            block = (y // 5) % 2 == 0
            for x in inner:
                px[x, y] = (W_LIGHT if block else W_SHADE) + (255,)
            if y % 5 == 4:
                for x in inner:
                    px[x, y] = W_SHADE + (255,)
    return img


def _window(plinth, eave_shadow=True):
    img = _wall_base("mid", plinth, eave_shadow)
    px = img.load()
    left, right, top, bottom = 6, 17, 6, 16
    for y in range(top, bottom + 1):
        for x in range(left, right + 1):
            edge = x in (left, right) or y in (top, bottom)
            px[x, y] = (TIMBER_DARK if edge else GLASS) + (255,)
    for y in range(top + 1, bottom):
        for x in range(left + 1, right):
            # Light spills from the lower half of the pane; the mullions stay dark.
            if x in (11, 12) or y == 11:
                px[x, y] = TIMBER + (255,)
            elif y > 11:
                px[x, y] = GLASS_LIT + (255,)
    for x in range(left - 1, right + 2):
        px[x, top - 1] = W_LIGHT + (255,)
    return img


def _doorway(open_):
    """A free-standing doorway for the Door gamepiece, so the door you can walk through matches
    the ones painted into the walls. Transparent around the frame, since it is drawn over whatever
    the archway behind it is."""
    img = _new()
    px = img.load()
    left, right, top = 5, 18, 3
    for y in range(top, T):
        for x in range(left, right + 1):
            frame = x in (left, right) or y == top
            px[x, y] = (W_SHADE if frame else W_EDGE) + (255,)
    if not open_:
        d_left, d_right, d_top = left + 2, right - 2, top + 2
        for y in range(d_top, T - 1):
            for x in range(d_left, d_right + 1):
                edge = x in (d_left, d_right) or y == d_top
                px[x, y] = (TIMBER_DARK if edge else TIMBER) + (255,)
        for y in range(d_top + 2, T - 2):
            px[(d_left + d_right) // 2, y] = TIMBER_DARK + (255,)
        px[d_right - 2, 15] = HANDLE + (255,)
        px[d_right - 2, 16] = HANDLE + (255,)
    return img


def _door(plinth, eave_shadow=True):
    img = _wall_base("mid", plinth, eave_shadow)
    px = img.load()
    left, right, top = 7, 16, 5
    for y in range(top, T):
        for x in range(left, right + 1):
            if x in (left, right) or y == top:
                px[x, y] = TIMBER_DARK + (255,)
            else:
                px[x, y] = TIMBER + (255,)
    for y in range(top + 2, T - 2):           # plank lines
        px[11, y] = TIMBER_DARK + (255,)
    for x in range(left - 1, right + 2):      # lintel
        px[x, top - 1] = W_LIGHT + (255,)
    px[14, 14] = HANDLE + (255,)
    px[14, 15] = HANDLE + (255,)
    return img


# Which tile sits where, as an offset from ORIGIN_COL.
ROOF_TILES = ["ridge_left", "ridge_mid", "ridge_right",
              "slope_left", "slope_mid", "slope_right",
              "eave_left", "eave_mid", "eave_right"]
# A wall course carries the eave's shadow when the roof is directly above it, and a plinth when it
# meets the ground. Most of the town's houses are one course tall and need both ("sole").
STOREYS = {"sole": (True, True), "top": (True, False), "low": (False, True)}
PARTS = ["left", "mid", "right", "window", "door"]
WALL_TILES = ["%s_%s" % (s, p) for s in ("sole", "top", "low") for p in PARTS]
PROP_TILES = ["doorway_closed", "doorway_open"]


def coords():
    """name -> (col, row) in the atlas, for oryx_atlas to expose."""
    out = {}
    for i, name in enumerate(ROOF_TILES):
        out["roof_" + name] = (ORIGIN_COL + i, ROOF_ROW)
    for i, name in enumerate(WALL_TILES):
        out["wall_" + name] = (ORIGIN_COL + i, WALL_ROW)
    for i, name in enumerate(PROP_TILES):
        out[name] = (ORIGIN_COL + i, PROP_ROW)
    return out


def tiles():
    out = {}
    for name in ROOF_TILES:
        part, side = name.rsplit("_", 1)
        out["roof_" + name] = _roof(part, side)
    for name in WALL_TILES:
        storey, part = name.split("_")
        shade, plinth = STOREYS[storey]
        if part == "window":
            out["wall_" + name] = _window(plinth, shade)
        elif part == "door":
            out["wall_" + name] = _door(plinth, shade)
        else:
            out["wall_" + name] = _wall_base(part, plinth, shade)
    out["doorway_closed"] = _doorway(False)
    out["doorway_open"] = _doorway(True)
    return out


def paint(atlas):
    """Draws the kit into an open atlas image."""
    where = coords()
    for name, tile in tiles().items():
        col, row = where[name]
        atlas.paste(tile, (col * T, row * T))
    return atlas


if __name__ == "__main__":
    img = Image.open(oa.SHEET).convert("RGBA")
    paint(img)
    img.save(oa.SHEET)
    print(oa.SHEET, "house kit at cols %d-%d, rows %d-%d"
          % (ORIGIN_COL, ORIGIN_COL + 8, ROOF_ROW, WALL_ROW))
