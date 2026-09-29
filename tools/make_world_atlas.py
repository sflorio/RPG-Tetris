"""Turns the Oryx world sheet into a Godot-ready atlas.

The pack ships the world tiles as a 24px grid with pure black standing in for transparency
(that is what the bundled Tiled map declares with trans="000000"). No artwork uses pure black --
the darkest colour in the sheet is (38,38,38) -- so keying it out is lossless.
"""
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "resoursces", "TMX Source", "oryx_world2.png")
DST = os.path.join(ROOT, "assets", "tiles", "oryx_world.png")

img = Image.open(SRC).convert("RGBA")
px = img.load()
for y in range(img.height):
    for x in range(img.width):
        r, g, b, _ = px[x, y]
        if r == 0 and g == 0 and b == 0:
            px[x, y] = (0, 0, 0, 0)
img.save(DST)
print(DST, img.size, os.path.getsize(DST))


def patch_missing_terrain_tiles():
    """The pack ships 15 of the 16 side-combinations for each terrain: the piece that connects
    downwards only is absent. It is the upwards-only piece mirrored, so bake that into the spare
    column next to each autotile row rather than leaning on runtime tile transforms."""
    import sys
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import oryx_atlas as oa

    img = Image.open(DST).convert("RGBA")
    for name, row, _ in oa.TERRAINS:
        autotile_row = row + 1
        by_mask = oa.terrain_tiles(img, autotile_row)
        src_col, src_row = by_mask[0b1000][0]           # connects upwards only
        box = (src_col * oa.TILE, src_row * oa.TILE,
               (src_col + 1) * oa.TILE, (src_row + 1) * oa.TILE)
        flipped = img.crop(box).transpose(Image.FLIP_TOP_BOTTOM)
        img.paste(flipped, (oa.PATCH_COL * oa.TILE, autotile_row * oa.TILE))
        print("  %-13s down-only <- flip of (%d,%d)" % (name, src_col, src_row))
    img.save(DST)


patch_missing_terrain_tiles()
