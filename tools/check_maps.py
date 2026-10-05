"""Compares what the rebuilt maps let the player walk on against the maps they replace.

A retile is only safe if the gameboard comes out identical: the gamepieces, doors, area
transitions and cutscene triggers are all authored against cell coordinates, and a cell that
silently became blocked (or walkable) would strand one of them. The rule [Gameboard] applies is
that a cell is clear when at least one GameboardLayer has a tile there and none of them marks it
blocked, so that is what this reproduces.
"""
import os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_maps as bm
import build_tileset as bt
import oryx_atlas as oa
import tileset_io as tsi

KENNEY = os.path.join(oa.ROOT, "overworld", "maps", "tilesets", "kenney_terrain.tres")

# The layers carrying gameboard_layer.gd; the rest are decoration.
GAMEBOARD = [
    "Field/Map/Town/Ground", "Field/Map/Town/Buildings", "Field/Map/Town/Trees",
    "Field/Map/Town/Gamepieces/StrangeTreeInteraction/TileMap",
    "Field/Map/House/Ground", "Field/Map/House/Walls", "Field/Map/House/Decoration",
    "Field/Map/Forest/Terrain", "Field/Map/Forest/Trees",
]

# The Emberlight Inn has no legacy map behind it, so it is reported rather than compared.
import build_inn
import apply_inn
NEW_MAPS = build_inn.layer_paths()

NEIGHBOURS = ((0, 1), (0, -1), (1, 0), (-1, 0))


def walkable(layers, blocked_at, paths=None):
    exists, blocked = set(), set()
    for path in (paths if paths is not None else GAMEBOARD):
        for x, y, src, ax, ay, _alt in layers.get(path, []):
            exists.add((x, y))
            if blocked_at(src, ax, ay):
                blocked.add((x, y))
    return exists - blocked, exists


def check_inn(walkable_cells):
    """The inn has to be walkable end to end, which is easy to break by putting a barrel down.

    A prop on the cell in front of a doorway, or on the cell a doorway lands you in, seals a room
    off: the door is still there, you simply cannot reach it. That shipped once -- a jar in the
    kitchen cut the main hall off from the rest of the inn -- so it is asserted rather than
    eyeballed. Reachability is checked for real, by flooding from where the player wakes up.
    """
    problems = []

    for _room, name, cell, arrival in apply_inn.TRANSITIONS:
        if cell not in walkable_cells:
            problems.append("%s: the doorway at %s is blocked" % (name, cell))
        if arrival not in walkable_cells:
            problems.append("%s: it lands you on %s, which is blocked" % (name, arrival))
        approach = [n for n in _around(cell) if n in walkable_cells]
        if not approach:
            problems.append("%s: nothing walkable next to the doorway at %s" % (name, cell))

    for who, cell in build_inn.SPAWNS.items():
        if cell not in walkable_cells:
            problems.append("%s stands on %s, which is blocked" % (who, cell))

    # Doorways are one-way teleports, so flooding has to step through them.
    links = {}
    for _room, _name, cell, arrival in apply_inn.TRANSITIONS:
        links.setdefault(cell, []).append(arrival)

    start = build_inn.SPAWNS["player"]
    seen, queue = {start}, [start]
    while queue:
        cell = queue.pop()
        for nxt in list(_around(cell)) + links.get(cell, []):
            if nxt in walkable_cells and nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)

    stranded = walkable_cells - seen
    if stranded:
        problems.append("%d cells cannot be reached from where the player wakes up, e.g. %s"
                        % (len(stranded), sorted(stranded)[:8]))

    for who, cell in build_inn.SPAWNS.items():
        if cell in walkable_cells and cell not in seen:
            problems.append("%s cannot be reached" % who)

    return problems


def _around(cell):
    return [(cell[0] + dx, cell[1] + dy) for dx, dy in NEIGHBOURS]


def main():
    kenney = tsi.read(KENNEY)
    before = walkable(bm.legacy_layers(),
                      lambda src, ax, ay:
                      kenney.get(src, {}).get((ax, ay), {}).get("custom_data_0") == "true")
    after = walkable(bm.build(bm.Painter(), bm.legacy_layers()),
                     lambda src, ax, ay: bt.blocked(ax, ay))

    ok = True
    for label, i in (("walkable", 0), ("tiled", 1)):
        lost, gained = before[i] - after[i], after[i] - before[i]
        print("%-9s before=%-5d after=%-5d lost=%-4d gained=%d"
              % (label, len(before[i]), len(after[i]), len(lost), len(gained)))
        if lost or gained:
            ok = False
            print("   lost:   ", sorted(lost)[:12])
            print("   gained: ", sorted(gained)[:12])
    inn = walkable({p: c for p, c in bm.build(bm.Painter(), bm.legacy_layers()).items()
                    if p in NEW_MAPS},
                   lambda src, ax, ay: bt.blocked(ax, ay),
                   paths=NEW_MAPS)
    print("new       Inn: %d walkable of %d tiled" % (len(inn[0]), len(inn[1])))

    problems = check_inn(inn[0])
    for problem in problems:
        print("   Inn: " + problem)
    if problems:
        ok = False

    print("OK" if ok else "MISMATCH")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
