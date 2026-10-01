"""Builds assets/tiles/oryx_world.png, the atlas every map is drawn from.

Three steps:

1. The pack ships the world tiles as a 24px grid with pure black standing in for transparency
   (that is what the bundled Tiled map declares with trans="000000"). No artwork uses pure black --
   the darkest colour in the sheet is (38,38,38) -- so keying it out is lossless.
2. Each terrain ships 15 of the 16 side-combinations; the piece that connects downwards only is
   absent, and is baked in as a mirror of the upwards-only piece.
3. The pack has no buildings at all, so the house kit is drawn into a spare corner of the sheet.
"""
import os, sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "resoursces", "TMX Source", "oryx_world2.png")
DST = os.path.join(ROOT, "assets", "tiles", "oryx_world.png")


def key_out_black():
    img = Image.open(SRC).convert("RGBA")
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, _ = px[x, y]
            if r == 0 and g == 0 and b == 0:
                px[x, y] = (0, 0, 0, 0)
    return img


def patch_missing_terrain_tiles(img):
    import oryx_atlas as oa

    for name, row, _ in oa.TERRAINS:
        autotile_row = row + 1
        by_mask = oa.terrain_tiles(img, autotile_row)
        src_col, src_row = by_mask[0b1000][0]           # connects upwards only
        box = (src_col * oa.TILE, src_row * oa.TILE,
               (src_col + 1) * oa.TILE, (src_row + 1) * oa.TILE)
        flipped = img.crop(box).transpose(Image.FLIP_TOP_BOTTOM)
        img.paste(flipped, (oa.PATCH_COL * oa.TILE, autotile_row * oa.TILE))
    print("  patched the down-only terrain piece for %d terrain sets" % len(oa.TERRAINS))


def main():
    img = key_out_black()
    img.save(DST)                                      # oryx_atlas reads the file back
    img = Image.open(DST).convert("RGBA")
    patch_missing_terrain_tiles(img)

    import make_buildings
    make_buildings.paint(img)
    print("  house kit at cols %d-%d, rows %d-%d"
          % (make_buildings.ORIGIN_COL,
             make_buildings.ORIGIN_COL + len(make_buildings.WALL_TILES) - 1,
             make_buildings.ROOF_ROW, make_buildings.WALL_ROW))

    img.save(DST)
    print(DST, img.size, os.path.getsize(DST), "bytes")


if __name__ == "__main__":
    main()
