"""Generates overworld/maps/tilesets/oryx_world.tres from the Oryx atlas.

Every non-empty tile in the sheet is declared, so the sheet can be painted freely in the editor.
On top of that the generator sets the two things the game relies on: the IsCellBlocked custom data
layer that [GameboardLayer] reads for pathfinding, and one "match sides" terrain per Oryx terrain
set, with the peering bits read off the artwork rather than typed in by hand.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import oryx_atlas as oa

OUT = os.path.join(oa.ROOT, "overworld", "maps", "tilesets", "oryx_world.tres")
SIDES = ["top_side", "right_side", "bottom_side", "left_side"]  # bit 8, 4, 2, 1


def is_blocked(col, row):
    """Whether a tile stops movement. Read off how the sheet is laid out."""
    if row <= 12:                       # the dungeon block
        if col <= 6:
            return False                # floors and fills
        if col <= 24:
            return True                 # wall runs
        return True                     # props, doors, furniture
    if row in (13, 14, 15):             # lava, hedges, flowering hedges
        return 7 <= col <= 24
    if row == 16:                       # fences and railings
        return True
    if row == 17:
        return col <= 24                # cliff faces; 28+ is ground fill
    if 18 <= row <= 35:
        if col <= 27:
            return True                 # cliffs and rock faces
        if col <= 47:
            return False                # the nine terrain sets
        return True
    if row >= 36:
        return True                     # pipework and cliff walls
    return False


def tree_or_scatter_blocked(col, row):
    if 42 <= col <= 64 and 10 <= row <= 15:
        return True
    if 42 <= col <= 51 and 7 <= row <= 9:
        return (col, row) not in oa.FLOWERS
    return None


def blocked(col, row):
    override = tree_or_scatter_blocked(col, row)
    return is_blocked(col, row) if override is None else override


def main():
    img = oa.sheet()
    lines = [
        '[gd_resource type="TileSet" format=3]',
        "",
        '[ext_resource type="Texture2D" path="res://assets/tiles/oryx_world.png" id="1_oryx"]',
        "",
        '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_oryx"]',
        'resource_name = "Oryx World"',
        'texture = ExtResource("1_oryx")',
        "texture_region_size = Vector2i(24, 24)",
    ]

    # Terrain peering bits, keyed by atlas coordinate so they can be merged with the tile list.
    peering = {}
    for index, (_name, row, _colour) in enumerate(oa.TERRAINS):
        autotile_row = row + 1
        for mask, coords in oa.terrain_tiles(img, autotile_row).items():
            for coord in coords:
                peering[coord] = (index, mask)
        for col in range(28, 38):       # the interior variants are fully surrounded
            if not oa.tile_is_empty(img, col, row):
                peering[(col, row)] = (index, 0b1111)

    count = 0
    for row in range(oa.ROWS):
        for col in range(oa.COLS):
            if oa.tile_is_empty(img, col, row):
                continue
            count += 1
            lines.append("%d:%d/0 = 0" % (col, row))
            if blocked(col, row):
                lines.append("%d:%d/0/custom_data_0 = true" % (col, row))
            if (col, row) in peering:
                index, mask = peering[(col, row)]
                lines.append("%d:%d/0/terrain_set = 0" % (col, row))
                lines.append("%d:%d/0/terrain = %d" % (col, row, index))
                for bit, side in enumerate(SIDES):
                    if mask & (0b1000 >> bit):
                        lines.append("%d:%d/0/terrains_peering_bit/%s = %d"
                                     % (col, row, side, index))

    lines += ["", "[resource]", "tile_size = Vector2i(24, 24)", "terrain_set_0/mode = 2"]
    for index, (name, _row, colour) in enumerate(oa.TERRAINS):
        lines.append('terrain_set_0/terrain_%d/name = "%s"' % (index, name.replace("_", " ").title()))
        lines.append("terrain_set_0/terrain_%d/color = Color(%s, 1)"
                     % (index, ", ".join("%g" % c for c in colour)))
    lines += [
        'custom_data_layer_0/name = "IsCellBlocked"',
        "custom_data_layer_0/type = 1",
        'sources/0 = SubResource("TileSetAtlasSource_oryx")',
        "",
    ]

    open(OUT, "w", encoding="utf-8", newline="\n").write("\n".join(lines))
    print(OUT, "%d tiles" % count, os.path.getsize(OUT), "bytes")


if __name__ == "__main__":
    main()
