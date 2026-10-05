"""Builds the Emberlight Inn, where the design's Opening starts.

Chapter 1 runs through three rooms -- the Storage Attic the player wakes in, the Kitchen below it
and the Main Hall with Quinn and the mercenaries -- none of which exist in the GDQuest demo maps.
They are authored here rather than by hand because the tile data lives base64-encoded inside
src/main.tscn, and because keeping them in the same pipeline as the retile means the Oryx catalogue
and the walkability check cover them too.

Rooms are placed in the gaps between the existing maps and inside the gameboard's extents
(70x35) -- outside those, Gameboard never adds the cell to the pathfinder and the room would be
unwalkable.
"""
import os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_maps as bm
import oryx_atlas as oa

SRC = bm.SRC

# Room footprints: the walkable floor. A wall ring is added around each.
# Town occupies x -12..36, House x 49..60 y -1..8, Forest x 23..71 y 17..42, so these sit in what
# is left inside the extents.
ROOMS = {
    "StorageAttic": {"x": 62, "y": 2, "w": 6, "h": 4, "floor": "plank"},
    "Kitchen": {"x": 38, "y": 2, "w": 7, "h": 4, "floor": "sand"},
    "MainHall": {"x": 38, "y": 10, "w": 13, "h": 6, "floor": "plank"},
}

# Where the player and the cast stand, in cells.
SPAWNS = {
    "player": (64, 4),
    "quinn": (44, 12),
    "captain": (40, 11),
    "warrior": (42, 14),
    "medic": (48, 12),
}

# Doorways cut through a room's wall, as (room, cell). The cell is a wall cell that becomes floor.
DOORWAYS = [
    ("StorageAttic", (62, 6)),
    ("Kitchen", (38, 6)),
    ("Kitchen", (45, 4)),
    ("MainHall", (38, 9)),
]

# Props, placed on the Decoration layer. Everything here blocks movement.
PROPS = {
    "StorageAttic": [
        ((62, 2), "crate"), ((63, 2), "crate_grey"), ((67, 2), "barrel"),
        ((67, 5), "crate"), ((66, 2), "barrel_open"),
    ],
    "Kitchen": [
        ((38, 2), "cauldron"), ((39, 2), "table"), ((40, 2), "workbench"),
        ((44, 2), "barrel"), ((44, 5), "crate"), ((38, 5), "pot"),
    ],
    "MainHall": [
        ((38, 10), "barrel"), ((39, 10), "barrel_open"), ((40, 10), "tub"),
        ((45, 10), "bookshelf"), ((46, 10), "locker"),
        ((39, 12), "table"), ((41, 12), "table"), ((43, 15), "table"), ((46, 15), "table"),
        ((50, 10), "brazier_lit"), ((50, 15), "brazier_lit"),
        ((48, 15), "chest"),
    ],
}


def _ring(room):
    """The wall cells around a room: one cell out on every side, corners included."""
    x0, y0 = room["x"], room["y"]
    x1, y1 = x0 + room["w"] - 1, y0 + room["h"] - 1
    cells = set()
    for x in range(x0 - 1, x1 + 2):
        cells.add((x, y0 - 1))
        cells.add((x, y1 + 1))
    for y in range(y0 - 1, y1 + 2):
        cells.add((x0 - 1, y))
        cells.add((x1 + 1, y))
    return cells


def _floor(room):
    return {(x, y)
            for x in range(room["x"], room["x"] + room["w"])
            for y in range(room["y"], room["y"] + room["h"])}


def layer_paths():
    """Every TileMapLayer the inn owns, in scene order. One set per room: each room is its own
    exclusive area, so walking into the kitchen hides the hall rather than showing both at once."""
    return ["Field/Map/Inn/%s/%s" % (room, layer)
            for room in ROOMS for layer in ("Ground", "Walls", "Decoration")]


def build(painter):
    """Returns {layer path: cells} for the inn, one set of layers per room."""
    out = {}
    doorways = {cell for _room, cell in DOORWAYS}

    for name, room in ROOMS.items():
        ground, walls, deco = [], [], []
        floor_tile = oa.FLOOR[room["floor"]]
        for cell in sorted(_floor(room)):
            ground.append(cell + (SRC,) + floor_tile + (0,))
        for cell in sorted(_ring(room)):
            if cell in doorways:
                # A doorway is floor the player walks through, not wall.
                ground.append(cell + (SRC,) + oa.FLOOR["dark"] + (0,))
            else:
                walls.append(cell + (SRC,) + (9, oa.WALLS["stone"]["row"]) + (0,))
        for cell, prop in PROPS.get(name, []):
            deco.append(cell + (SRC,) + oa.PROPS[prop] + (0,))
        out["Field/Map/Inn/%s/Ground" % name] = ground
        out["Field/Map/Inn/%s/Walls" % name] = walls
        out["Field/Map/Inn/%s/Decoration" % name] = deco
    return out


def cell_to_pixel(cell):
    """Centre of a cell in gameboard pixels, which is where a Gamepiece is authored."""
    return (cell[0]*oa.TILE + oa.TILE//2, cell[1]*oa.TILE + oa.TILE//2)


if __name__ == "__main__":
    layers = build(bm.Painter())
    for path, cells in layers.items():
        print("%-34s %d" % (path, len(cells)))
    for who, cell in SPAWNS.items():
        print("  %-8s cell %s -> position %s" % (who, cell, cell_to_pixel(cell)))
