"""Rebuilds the overworld maps on the Oryx 16-bit Fantasy world tiles.

The old maps are the source of truth for *shape*: every cell that carried a tile still carries one,
and every cell that blocked movement still blocks it. Only the artwork changes, plus two new
purely decorative layers that let a terrain blend into its neighbour the way the Oryx autotiles
expect (a base fill underneath, the transitions on top).
"""
import json, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import oryx_atlas as oa
import tilemap_io as tio

ROOT = oa.ROOT
SCENE = os.path.join(ROOT, "src", "main.tscn")
SRC = 0  # the single Oryx atlas source

T_GRASS, T_DIRT, T_PATH, T_FOREST = "grass", "dirt", "pale_sand", "forest_floor"


# The maps as GDQuest authored them, on the Kenney tiles. The rebuild reads its shape -- which
# cells exist, which block movement, what each one was -- from this snapshot rather than from
# whatever is currently in the scene, so it can be re-run any number of times.
LEGACY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "legacy_maps.json")


def scene_layers(path=SCENE):
    text = open(path, encoding="utf-8").read()
    return {p: tio.decode(b64)[1] for p, _, _, b64, _ in tio.layers(text)}


def legacy_layers():
    if not os.path.exists(LEGACY):
        json.dump(scene_layers(), open(LEGACY, "w", encoding="utf-8"), separators=(",", ":"))
        print("snapshotted the Kenney maps to", os.path.basename(LEGACY))
    raw = json.load(open(LEGACY, encoding="utf-8"))
    return {path: [tuple(c) for c in cells] for path, cells in raw.items()}


# Old atlas coordinates, grouped by what they are. Source 0 is town_tilemap.png, source 1 is
# dungeon_tilemap.png.
GROUND_CLASS = {}
for _c in [(0, 0), (1, 0), (2, 0)]:
    GROUND_CLASS[_c] = T_GRASS
for _c in [(0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2), (0, 3), (1, 3), (2, 3),
           (3, 3), (4, 3), (5, 3), (6, 3)]:
    GROUND_CLASS[_c] = T_DIRT
GROUND_CLASS[(7, 3)] = T_PATH

TREE_BLOB = {(x, y) for x in range(6, 12) for y in range(3)}
TREE_SINGLE = {(3, 0), (3, 1), (3, 2), (4, 0), (4, 1), (4, 2)}
BUSH = {(5, 0), (5, 1)}
SCATTER = {(5, 2)}
FENCE = {(x, y) for x in range(8, 12) for y in range(3, 7)}


def classify_scenery_cell(src, ax, ay):
    if src != 0:
        return "prop"
    c = (ax, ay)
    if c in TREE_BLOB:
        return "tree"
    if c in TREE_SINGLE:
        return "tree_single"
    if c in BUSH:
        return "bush"
    if c in SCATTER:
        return "scatter"
    if c in FENCE:
        return "fence"
    return "prop"


# Buildings: the old art puts roofs on atlas rows 4-5 and walls on rows 6-7.
BUILDING_DOORS = {(1, 7), (2, 7), (3, 7), (5, 7), (6, 7), (7, 7)}
BUILDING_WINDOWS = {(0, 7), (4, 7)}


def classify_building_cell(ax, ay):
    if ay in (4, 5):
        return "roof"
    if (ax, ay) in BUILDING_DOORS:
        return "door"
    if (ax, ay) in BUILDING_WINDOWS:
        return "window"
    return "wall"


class Painter:
    """Chooses Oryx tiles. Every choice is a pure function of the cell, so a rebuild is stable."""

    def __init__(self):
        self.img = oa.sheet()
        self._terrain = {name: oa.terrain_tiles(self.img, row + 1)
                         for name, row, _ in oa.TERRAINS}
        # The autotile row's "connects on all four sides" piece still has its corners rounded off,
        # because a sides-only set carries no corner information. A field of them is speckled with
        # holes, so interiors come from the row above, where the tiles are whole.
        self._fills = {}
        for name, row, _ in oa.TERRAINS:
            whole = [(col, row) for col in range(28, 38)
                     if not oa.tile_is_empty(self.img, col, row)
                     and oa.corners_whole(self.img, col, row)]
            self._fills[name] = whole or self._terrain[name][0b1111]

    @staticmethod
    def _pick(options, cell):
        return options[(cell[0] * 7 + cell[1] * 13) % len(options)]

    def fill(self, name, cell):
        return self._pick(self._fills[name], cell)

    def autotile(self, name, cell, members):
        x, y = cell
        mask = 0
        for bit, (dx, dy) in zip((0b1000, 0b0100, 0b0010, 0b0001),
                                 ((0, -1), (1, 0), (0, 1), (-1, 0))):
            if (x + dx, y + dy) in members:
                mask |= bit
        if mask == 0b1111:
            return self.fill(name, cell)
        return self._pick(self._terrain[name][mask], cell)

    # Woods are laid out in stands rather than one species everywhere: a single 3x3 canopy block
    # repeated over a whole map reads as wallpaper, with the trunk row banding every third row.
    STANDS = ["green", "green", "green", "pine", "green", "autumn", "pine", "green"]
    STAND_SIZE = 7

    def _stand(self, cell):
        # Jitter the stand boundaries so they do not show up as a grid of rectangles.
        x = cell[0] + ((cell[1] * 2654435761) >> 7) % 4
        y = cell[1] + ((cell[0] * 2246822519) >> 7) % 4
        sx, sy = x // self.STAND_SIZE, y // self.STAND_SIZE
        h = (sx * 73856093) ^ (sy * 19349663)
        return self.STANDS[(h >> 3) % len(self.STANDS)], (h >> 11) % 3, (h >> 17) % 3

    def canopy(self, cell):
        kind, px, py = self._stand(cell)
        cx, cy = oa.TREES[kind]["canopy"]
        return (cx + (cell[0] + px) % 3, cy + (cell[1] + py) % 3)

    def single_tree(self, cell):
        kind, _, _ = self._stand(cell)
        return self._pick(oa.TREES[kind]["singles"], cell)

    def scatter(self, cell):
        return self._pick(oa.FLOWERS, cell)

    def bush(self, cell):
        return self._pick(oa.BUSHES + oa.SHRUBS, cell)

    def prop(self, cell):
        return self._pick(oa.ROCKS + [oa.STUMP], cell)

    def fence(self, cell):
        return self._pick(oa.FENCE["run"], cell)

    def wall(self, style, cell):
        spec = oa.WALLS[style]
        return (self._pick(spec["run"], cell), spec["row"])


def neighbours(cell, members):
    x, y = cell
    return sum(((x + dx, y + dy) in members)
               for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0)))


def build(painter, old):
    out = {}

    # --- Town ---------------------------------------------------------------------------------
    classes = {(x, y): GROUND_CLASS.get((ax, ay), T_GRASS)
               for x, y, s, ax, ay, _ in old["Field/Map/Town/Ground"]}
    out["Field/Map/Town/Ground"] = [cell + (SRC,) + painter.fill(T_GRASS, cell) + (0,)
                                    for cell in classes]

    cover = []
    for name in (T_DIRT, T_PATH):
        members = {c for c, k in classes.items() if k == name}
        for cell in members:
            cover.append(cell + (SRC,) + painter.autotile(name, cell, members) + (0,))
    out["Field/Map/Town/GroundCover"] = cover

    out["Field/Map/Town/Buildings"] = buildings(painter, old["Field/Map/Town/Buildings"])
    out["Field/Map/Town/Trees"] = scenery(painter, old["Field/Map/Town/Trees"])
    out["Field/Map/Town/TreeTops"] = []
    out["Field/Map/Town/Gamepieces/StrangeTreeInteraction/TileMap"] = scenery(
        painter, old["Field/Map/Town/Gamepieces/StrangeTreeInteraction/TileMap"])

    # --- Forest -------------------------------------------------------------------------------
    out["Field/Map/Forest/Terrain"] = [(x, y, SRC) + painter.fill(T_GRASS, (x, y)) + (0,)
                                       for x, y, s, ax, ay, _ in old["Field/Map/Forest/Terrain"]]

    # Dark undergrowth wherever the wood is thick, so the clearings read as clearings.
    wooded = {(x, y) for x, y, s, ax, ay, _ in old["Field/Map/Forest/Trees"]}
    floor_cells = {c for c in wooded if neighbours(c, wooded) >= 3}
    out["Field/Map/Forest/Undergrowth"] = [
        c + (SRC,) + painter.autotile(T_FOREST, c, floor_cells) + (0,) for c in floor_cells]

    out["Field/Map/Forest/Trees"] = scenery(painter, old["Field/Map/Forest/Trees"])
    out["Field/Map/Forest/Treetops"] = []

    out.update(house(painter, old))
    return out


def scenery(painter, cells):
    out = []
    for x, y, s, ax, ay, _ in cells:
        kind = classify_scenery_cell(s, ax, ay)
        cell = (x, y)
        if kind == "tree":
            coord = painter.canopy(cell)
        elif kind == "tree_single":
            coord = painter.single_tree(cell)
        elif kind == "bush":
            coord = painter.bush(cell)
        elif kind == "scatter":
            coord = painter.scatter(cell)
        elif kind == "fence":
            coord = painter.fence(cell)
        else:
            coord = painter.prop(cell)
        out.append((x, y, SRC) + coord + (0,))
    return out


def buildings(painter, cells):
    roofs = {(x, y) for x, y, s, ax, ay, _ in cells if classify_building_cell(ax, ay) == "roof"}
    out = []
    for x, y, s, ax, ay, _ in cells:
        cell = (x, y)
        kind = classify_building_cell(ax, ay)
        if kind == "roof":
            # The Oryx wall run carries a shadowed front face. Use it only along the eave, and
            # plain brick above it, so a roof does not read as a row of separate blocks.
            coord = (painter.wall("brick", cell) if (x, y + 1) not in roofs
                     else painter._pick(oa.ROOF_FILL, cell))
        elif kind == "door":
            coord = oa.DOORS["wood_closed"]
        elif kind == "window":
            coord = oa.WALLS["stone"]["window"]
        else:
            coord = painter.wall("stone", cell)
        out.append((x, y, SRC) + coord + (0,))
    return out


def house(painter, old):
    out = {"Field/Map/House/Ground": [(x, y, SRC) + oa.FLOOR["plank"] + (0,)
                                      for x, y, s, ax, ay, _ in old["Field/Map/House/Ground"]]}
    walls = []
    for x, y, s, ax, ay, _ in old["Field/Map/House/Walls"]:
        # One wall tile throughout: a room is small enough that variants read as noise.
        coord = oa.FLOOR["flagstone"] if (ax, ay) == (9, 0) else (9, oa.WALLS["stone"]["row"])
        walls.append((x, y, SRC) + coord + (0,))
    out["Field/Map/House/Walls"] = walls

    props = [oa.PROPS[k] for k in oa.FURNISHINGS]
    out["Field/Map/House/Decoration"] = [
        (x, y, SRC) + props[i % len(props)] + (0,)
        for i, (x, y, s, ax, ay, _) in enumerate(old["Field/Map/House/Decoration"])]
    return out


if __name__ == "__main__":
    p = Painter()
    for path, cells in build(p, legacy_layers()).items():
        print("%-58s %d" % (path, len(cells)))
