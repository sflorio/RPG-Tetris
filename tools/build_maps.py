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

# How the old map's ground reads in Oryx terms. The paths are brown earth rather than the pale
# sand they first got: Oryx's own mockups run dirt tracks through grass, and pale sand at this
# width read as a beach rather than a village lane.
T_GRASS, T_PATCH, T_PATH, T_FOREST = "grass", "dry_grass", "dirt", "forest_floor"


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
    GROUND_CLASS[_c] = T_PATCH
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
    # Only the two greens, though -- the autumn set is bright orange, and a stand of it next to
    # the village read as a stain rather than as trees.
    STANDS = ["green", "green", "pine", "green", "green", "pine", "green", "pine"]
    STAND_SIZE = 7

    def _stand(self, cell):
        # Jitter the stand boundaries so they do not show up as a grid of rectangles.
        x = cell[0] + ((cell[1] * 2654435761) >> 7) % 4
        y = cell[1] + ((cell[0] * 2246822519) >> 7) % 4
        sx, sy = x // self.STAND_SIZE, y // self.STAND_SIZE
        h = (sx * 73856093) ^ (sy * 19349663)
        return self.STANDS[(h >> 3) % len(self.STANDS)], (h >> 11) % 3, (h >> 17) % 3

    def canopy(self, cell, members):
        """One tile of a 3x3 canopy block, chosen so the block's edge row lands on the edge of
        the wood.

        Tiling the block as-is is what makes a big wood read as wallpaper: the broadleaf block's
        bottom row is drawn with trunks and roots, so repeating it stripes the forest every third
        row. That row belongs on the south edge of the mass and nowhere else. The conifer block is
        built the other way up -- its first row is the one where the tops are clear -- so that row
        belongs on the north edge."""
        kind, px, py = self._stand(cell)
        cx, cy = oa.TREES[kind]["canopy"]
        x, y = cell
        if oa.TREES[kind]["trunks_at_bottom"]:
            # Broadleaf: the block is one 3x3 grove. Its outer columns carry a trunk at the side
            # and its bottom row carries trunks and roots, so all of that belongs on the edge of
            # the mass; the clean middle tile fills the interior as unbroken canopy.
            col = (0 if (x - 1, y) not in members
                   else 2 if (x + 1, y) not in members else 1)
            row = 2 if (x, y + 1) not in members else (y + py) % 2
        else:
            # Conifers are drawn as whole trees however they are tiled, so keep the artist's
            # 3-wide rhythm and only move the clear-tops row to the north edge.
            col = (x + px) % 3
            row = 0 if (x, y - 1) not in members else 1 + (y + py) % 2
        return (cx + col, cy + row)

    def single_tree(self, cell):
        kind, _, _ = self._stand(cell)
        return self._pick(oa.TREES[kind]["singles"], cell)

    def scatter(self, cell):
        return self._pick(oa.FLOWERS, cell)

    def bush(self, cell):
        return self._pick(oa.BUSHES, cell)

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

    town_trees = {(x, y) for x, y, s, ax, ay, _ in old["Field/Map/Town/Trees"]
                  if classify_scenery_cell(s, ax, ay) == "tree"}
    cover = undergrowth(painter, town_trees)
    for name in (T_PATCH, T_PATH):
        members = {c for c, k in classes.items() if k == name}
        for cell in members:
            cover.append(cell + (SRC,) + painter.autotile(name, cell, members) + (0,))
    plain = set(classes) - {(c[0], c[1]) for c in cover} - town_trees
    cover += meadow(painter, plain)
    cover += passages(old["Field/Map/Town/Buildings"])
    out["Field/Map/Town/GroundCover"] = cover

    out["Field/Map/Town/Buildings"] = buildings(painter, old["Field/Map/Town/Buildings"])
    out["Field/Map/Town/Trees"] = scenery(painter, old["Field/Map/Town/Trees"])
    out["Field/Map/Town/TreeTops"] = []
    out["Field/Map/Town/Gamepieces/StrangeTreeInteraction/TileMap"] = scenery(
        painter, old["Field/Map/Town/Gamepieces/StrangeTreeInteraction/TileMap"])

    # --- Forest -------------------------------------------------------------------------------
    out["Field/Map/Forest/Terrain"] = [(x, y, SRC) + painter.fill(T_GRASS, (x, y)) + (0,)
                                       for x, y, s, ax, ay, _ in old["Field/Map/Forest/Terrain"]]

    wooded = {(x, y) for x, y, s, ax, ay, _ in old["Field/Map/Forest/Trees"]
              if classify_scenery_cell(s, ax, ay) == "tree"}
    clearing = {(x, y) for x, y, s, ax, ay, _ in old["Field/Map/Forest/Terrain"]} - wooded
    out["Field/Map/Forest/Undergrowth"] = undergrowth(painter, wooded) + meadow(painter, clearing)

    out["Field/Map/Forest/Trees"] = scenery(painter, old["Field/Map/Forest/Trees"])
    out["Field/Map/Forest/Treetops"] = []

    out.update(house(painter, old))

    # The Emberlight Inn, where the design's Opening starts. It has no legacy map behind it, so it
    # is authored rather than translated; see tools/build_inn.py.
    import build_inn
    out.update(build_inn.build(painter))
    return out


def undergrowth(painter, wooded):
    """Dark forest floor under and just outside the thick of the wood.

    Taking the wood's own cells alone would be invisible -- the canopy covers them. What makes the
    wood read as having depth is the ring that falls one cell beyond it, so the trees stand in
    their own shade rather than on bright lawn. Isolated trees are left out, or every one of them
    would sit in a dark blotch."""
    inner = {c for c in wooded if neighbours(c, wooded) >= 3}
    shade = set(inner)
    for x, y in inner:
        shade.update(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return [c + (SRC,) + painter.autotile(T_FOREST, c, shade) + (0,) for c in sorted(shade)]


def meadow(painter, cells):
    """Sparse flowers over open grass. A field of one tile is flat however good the tile is, and
    Oryx's own overworld mockups break theirs up exactly this way."""
    out = []
    for cell in sorted(cells):
        h = ((cell[0] * 73856093) ^ (cell[1] * 19349663)) & 0xFFFF
        if h % 13 == 0:
            out.append(cell + (SRC,) + painter.scatter(cell) + (0,))
    return out


def scenery(painter, cells):
    canopies = {(x, y) for x, y, s, ax, ay, _ in cells
                if classify_scenery_cell(s, ax, ay) == "tree"}
    out = []
    for x, y, s, ax, ay, _ in cells:
        kind = classify_scenery_cell(s, ax, ay)
        cell = (x, y)
        if kind == "tree":
            coord = painter.canopy(cell, canopies)
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


def passages(building_cells):
    """Shaded floor where a walkable cell is enclosed by a building.

    The old town has one: a gap in a wall with roof above it and wall either side. Left as grass
    it reads as a hole knocked in the house; as dark floor it reads as the archway it is."""
    cells = {(x, y) for x, y, s, ax, ay, _ in building_cells}
    out = []
    for x, y in sorted({(x, y + 1) for x, y in cells}):
        if (x, y) not in cells and (x - 1, y) in cells and (x + 1, y) in cells:
            out.append((x, y, SRC) + oa.FLOOR["dark"] + (0,))
    return out


def components(cells):
    """Splits a set of cells into 4-connected groups -- one per building."""
    remaining, groups = set(cells), []
    while remaining:
        seed = remaining.pop()
        group, queue = {seed}, [seed]
        while queue:
            x, y = queue.pop()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n in remaining:
                    remaining.discard(n)
                    group.add(n)
                    queue.append(n)
        groups.append(group)
    return groups


def buildings(painter, cells):
    """Composes each house from the generated kit: a ridge, an eave, and a wall under it.

    The old art says which cells are roof and which are wall, and which of the wall cells are the
    door and the windows. What it cannot say is where each cell sits in its own building, which is
    what a roof needs to read as a roof -- so the buildings are separated out and each one is
    walked by row and column.
    """
    kit = oa.house_kit()
    kinds = {(x, y): classify_building_cell(ax, ay) for x, y, s, ax, ay, _ in cells}
    out = []

    for group in components(kinds):
        roof = sorted(c for c in group if kinds[c] == "roof")
        wall = sorted(c for c in group if kinds[c] != "roof")
        roof_rows = sorted({c[1] for c in roof})
        wall_rows = sorted({c[1] for c in wall})

        for cell in group:
            x, y = cell
            row = [c for c in group if c[1] == y]
            side = ("left" if x == min(c[0] for c in row)
                    else "right" if x == max(c[0] for c in row) else "mid")
            if kinds[cell] == "roof":
                part = ("ridge" if y == roof_rows[0]
                        else "eave" if y == roof_rows[-1] else "slope")
                name = "roof_%s_%s" % (part, side)
            else:
                # One course of wall is both the top of the wall and its base.
                storey = ("sole" if len(wall_rows) == 1
                          else "top" if y == wall_rows[0] else "low")
                part = kinds[cell] if kinds[cell] in ("door", "window") else side
                name = "wall_%s_%s" % (storey, part)
            out.append((x, y, SRC) + kit[name] + (0,))
    return out


def house(painter, old):
    out = {"Field/Map/House/Ground": [(x, y, SRC) + oa.FLOOR["plank"] + (0,)
                                      for x, y, s, ax, ay, _ in old["Field/Map/House/Ground"]]}
    walls = []
    for x, y, s, ax, ay, _ in old["Field/Map/House/Walls"]:
        # One wall tile throughout: a room is small enough that variants read as noise. The two
        # gaps in the wall are the doorways out, so they get the dark floor rather than a lit one.
        coord = oa.FLOOR["dark"] if (ax, ay) == (9, 0) else (9, oa.WALLS["stone"]["row"])
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
