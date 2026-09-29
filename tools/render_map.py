"""Renders the pre-Oryx maps from legacy_maps.json, for comparing against the rebuild."""
import sys, os
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(__file__))
import tilemap_io as tio

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ATLAS = {
    0: os.path.join(ROOT, "overworld/maps/tilesets/town_tilemap.png"),
    1: os.path.join(ROOT, "overworld/maps/tilesets/dungeon_tilemap.png"),
}
TILE, SEP = 16, 1


def render(prefix, groups, scale=2, grid=True):
    import build_maps as bm
    data = bm.legacy_layers()
    atlases = {k: Image.open(v).convert("RGBA") for k, v in ATLAS.items()}
    for group, paths in groups.items():
        cells = [c for p in paths for c in data.get(p, [])]
        if not cells:
            continue
        x0 = min(c[0] for c in cells); x1 = max(c[0] for c in cells)
        y0 = min(c[1] for c in cells); y1 = max(c[1] for c in cells)
        w, h = (x1 - x0 + 1), (y1 - y0 + 1)
        img = Image.new("RGBA", (w * TILE, h * TILE), (24, 24, 32, 255))
        for p in paths:
            for x, y, src, ax, ay, _alt in data.get(p, []):
                a = atlases.get(src)
                if a is None:
                    continue
                t = a.crop((ax * (TILE + SEP), ay * (TILE + SEP),
                            ax * (TILE + SEP) + TILE, ay * (TILE + SEP) + TILE))
                img.alpha_composite(t, ((x - x0) * TILE, (y - y0) * TILE))
        img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
        if grid:
            d = ImageDraw.Draw(img)
            s = TILE * scale
            for i in range(0, w + 1, 5):
                d.line([(i * s, 0), (i * s, img.height)], fill=(255, 0, 255, 90))
                d.text((i * s + 2, 2), str(x0 + i), fill=(255, 255, 120))
            for j in range(0, h + 1, 5):
                d.line([(0, j * s), (img.width, j * s)], fill=(255, 0, 255, 90))
                d.text((2, j * s + 2), str(y0 + j), fill=(255, 255, 120))
        out = "%s_%s.png" % (prefix, group)
        img.convert("RGB").save(out)
        print(out, img.size, "origin", (x0, y0))


if __name__ == "__main__":
    render(sys.argv[1], {
        "town": ["Field/Map/Town/Ground", "Field/Map/Town/Buildings",
                 "Field/Map/Town/Trees", "Field/Map/Town/TreeTops"],
        "house": ["Field/Map/House/Ground", "Field/Map/House/Walls",
                  "Field/Map/House/Decoration"],
        "forest": ["Field/Map/Forest/Terrain", "Field/Map/Forest/Trees",
                   "Field/Map/Forest/Treetops"],
    })
