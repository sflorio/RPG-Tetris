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


def walkable(layers, blocked_at):
    exists, blocked = set(), set()
    for path in GAMEBOARD:
        for x, y, src, ax, ay, _alt in layers.get(path, []):
            exists.add((x, y))
            if blocked_at(src, ax, ay):
                blocked.add((x, y))
    return exists - blocked, exists


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
    print("OK" if ok else "MISMATCH")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
