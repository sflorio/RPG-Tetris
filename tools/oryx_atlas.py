"""The Oryx 16-bit Fantasy world sheet, described in the terms this game needs.

Coordinates are (column, row) into assets/tiles/oryx_world.png, which is a plain 24px grid with
no margin or separation. Everything here was read off the sheet rather than guessed: the terrain
sets are 2 rows each (a row of interior variants and a row of 16 "sides" autotile pieces), and the
tree sets are a seamless 3x3 canopy block plus a pair of single trees.
"""
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEET = os.path.join(ROOT, "assets", "tiles", "oryx_world.png")
TILE = 24
COLS, ROWS = 85, 42

# --- Terrain --------------------------------------------------------------------------------
# Each entry is the row holding the interior variants; the autotile row is the one below it.
# The 16 side-combinations live in columns 28..45 of the autotile row.
TERRAIN_ROW0 = 18
TERRAIN_COLS = range(28, 47)
# Spare column that make_world_atlas.py fills with the one piece the pack does not ship.
PATCH_COL = 46
TERRAINS = [
    ("grass",        18, (0.30, 0.60, 0.28)),
    ("dry_grass",    20, (0.60, 0.57, 0.31)),
    ("dirt",         22, (0.72, 0.44, 0.14)),
    ("dark_moss",    24, (0.24, 0.26, 0.20)),
    ("swamp",        26, (0.33, 0.31, 0.10)),
    ("snow",         28, (0.90, 0.91, 0.93)),
    ("pale_sand",    30, (0.93, 0.82, 0.66)),
    ("sand",         32, (0.92, 0.79, 0.61)),
    ("forest_floor", 34, (0.18, 0.42, 0.22)),
]
TERRAIN_INDEX = {name: i for i, (name, _, _) in enumerate(TERRAINS)}

# Trees. `canopy` is the top-left of a seamless 3x3 block and `singles` are stand-alone trees.
# `trunks_at_bottom` says which way up the block is drawn: the broadleaf blocks put the trunks and
# roots on their last row, so that row belongs on the south edge of a wood, while the conifer
# blocks put the clear tree tops on their first row, which belongs on the north edge.
TREES = {
    "green":  {"canopy": (43, 11), "singles": [(44, 15), (45, 15)], "trunks_at_bottom": True},
    "autumn": {"canopy": (46, 11), "singles": [(47, 15), (48, 15)], "trunks_at_bottom": True},
    "dead":   {"canopy": (49, 11), "singles": [(50, 15), (51, 15)], "trunks_at_bottom": True},
    "pine":   {"canopy": (52, 11), "singles": [(52, 15), (53, 15)], "trunks_at_bottom": False},
    "snow":   {"canopy": (55, 11), "singles": [(55, 15), (56, 15)], "trunks_at_bottom": False},
    "stone":  {"canopy": (58, 11), "singles": [(58, 15), (59, 15)], "trunks_at_bottom": False},
    "brown":  {"canopy": (61, 11), "singles": [(61, 15), (62, 15)], "trunks_at_bottom": False},
}

# --- Scatter --------------------------------------------------------------------------------
FLOWERS = [(43, 7), (44, 7), (45, 7)]
BUSHES = [(47, 7), (48, 7), (49, 7)]
SHRUBS = [(43, 9), (44, 9), (45, 9)]
# Grey only: the brown one reads as a traffic cone once it is sitting on grass.
ROCKS = [(45, 8), (46, 8), (47, 8)]
STUMP = (47, 9)
CAVE = (43, 8)

# --- Structures -----------------------------------------------------------------------------
FENCE = {"run": [(7, 16), (8, 16), (9, 16), (10, 16)], "post": (11, 16), "vertical": (13, 16)}

# Wall sets. Each is one row of the sheet: `run` lists the plain lengths (the rest of the row is
# corner and junction pieces, which leave dark notches when used as a straight wall), and `window`
# the barred opening that matches.
WALLS = {
    "stone":  {"row": 9, "run": [9, 17], "window": (8, 9)},
    "brick":  {"row": 3, "run": [13, 14, 15, 16, 17, 18, 19, 20, 21, 22], "window": None},
    "wood":   {"row": 4, "run": [8, 9, 17], "window": None},
    "olive":  {"row": 2, "run": [8, 9, 17], "window": None},
    "sand":   {"row": 11, "run": [8, 9, 17], "window": None},
    "teal":   {"row": 6, "run": [8, 9, 17], "window": None},
    "blue":   {"row": 7, "run": [8, 9, 17], "window": None},
    "sea":    {"row": 10, "run": [8, 9, 17], "window": None},
}

FLOOR = {
    "plank": (33, 17), "flagstone": (0, 0), "dark": (3, 0), "wood": (0, 4),
    "sand": (35, 17), "dirt": (36, 17),
}

# The house kit drawn by make_buildings.py. The pack has no buildings of its own, so these are
# generated into the spare corner of the atlas; see that file for why and for the layout.
def house_kit():
    import make_buildings
    return make_buildings.coords()


DOORS = {
    "wood_closed": (28, 8), "wood_open": (29, 8), "wood_barred": (30, 8),
    "wood_closed2": (31, 8), "stone_closed": (35, 8), "stone_open": (36, 8),
}

# Things that belong in somebody's home, as opposed to a crypt.
FURNISHINGS = [
    "bookshelf", "table", "barrel", "crate", "shelf", "chest", "bench", "cauldron",
    "brazier_lit", "workbench", "pot", "locker", "tub", "anvil", "crate_grey", "barrel_open",
]

PROPS = {
    "crate": (28, 4), "crate_grey": (30, 4), "locker": (28, 10), "bookshelf": (30, 10),
    "shelf": (30, 3), "table": (33, 10), "bench": (34, 10), "throne": (35, 10),
    "workbench": (36, 10), "anvil": (37, 10), "chest": (31, 9), "chest_open": (32, 9),
    "barrel": (38, 9), "barrel_open": (39, 9), "tub": (40, 9), "brazier_lit": (28, 11),
    "cauldron": (30, 11), "armour_stand": (32, 11), "pot": (36, 11), "fountain": (28, 13),
    "grave": (28, 6), "boulder": (29, 6), "rubble": (30, 6),
}


def sheet():
    return Image.open(SHEET).convert("RGBA")


def tile_is_empty(img, col, row):
    px = img.load()
    for y in range(0, TILE, 2):
        for x in range(0, TILE, 2):
            if px[col * TILE + x, row * TILE + y][3] != 0:
                return False
    return True


def edges(img, col, row):
    """(top, right, bottom, left): does the artwork run off that edge of the tile?"""
    px = img.load()
    ox, oy = col * TILE, row * TILE
    return (
        any(px[ox + x, oy][3] for x in range(TILE)),
        any(px[ox + TILE - 1, oy + y][3] for y in range(TILE)),
        any(px[ox + x, oy + TILE - 1][3] for x in range(TILE)),
        any(px[ox, oy + y][3] for y in range(TILE)),
    )


def terrain_tiles(img, autotile_row):
    """side-mask (T,R,B,L as bits 8,4,2,1) -> the atlas coords that paint it."""
    out = {}
    for col in TERRAIN_COLS:
        if tile_is_empty(img, col, autotile_row):
            continue
        t, r, b, l = edges(img, col, autotile_row)
        mask = (t << 3) | (r << 2) | (b << 1) | l
        out.setdefault(mask, []).append((col, autotile_row))
    return out


def corners_whole(img, col, row):
    """True when the tile's four corner pixels are opaque, i.e. it reads as a flat field."""
    px = img.load()
    ox, oy = col * TILE, row * TILE
    return all(px[ox + dx, oy + dy][3]
               for dx in (0, TILE - 1) for dy in (0, TILE - 1))
