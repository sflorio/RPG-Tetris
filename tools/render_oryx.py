"""Composites the rebuilt maps into PNGs, so the look can be judged without opening Godot."""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import oryx_atlas as oa
import build_maps as bm

T = oa.TILE

GROUPS = {
    "town": ["Field/Map/Town/Ground", "Field/Map/Town/GroundCover",
             "Field/Map/Town/Buildings", "Field/Map/Town/Trees", "Field/Map/Town/TreeTops"],
    "house": ["Field/Map/House/Ground", "Field/Map/House/Walls", "Field/Map/House/Decoration"],
    "forest": ["Field/Map/Forest/Terrain", "Field/Map/Forest/Undergrowth",
               "Field/Map/Forest/Trees", "Field/Map/Forest/Treetops"],
}


def render(layers, prefix, groups=GROUPS, scale=1, grid=True, crop=None):
    sheet = oa.sheet()
    for group, paths in groups.items():
        cells = [c for p in paths for c in layers.get(p, [])]
        if not cells:
            continue
        x0 = min(c[0] for c in cells); x1 = max(c[0] for c in cells)
        y0 = min(c[1] for c in cells); y1 = max(c[1] for c in cells)
        if crop:
            x0, y0, x1, y1 = crop
        w, h = x1 - x0 + 1, y1 - y0 + 1
        img = Image.new("RGBA", (w * T, h * T), (24, 24, 32, 255))
        for p in paths:
            for x, y, _s, ax, ay, _alt in layers.get(p, []):
                if not (x0 <= x <= x1 and y0 <= y <= y1):
                    continue
                img.alpha_composite(
                    sheet.crop((ax * T, ay * T, (ax + 1) * T, (ay + 1) * T)),
                    ((x - x0) * T, (y - y0) * T))
        if scale != 1:
            img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
        if grid:
            d = ImageDraw.Draw(img)
            s = T * scale
            for i in range(0, w + 1, 5):
                d.line([(i * s, 0), (i * s, img.height)], fill=(255, 0, 255, 70))
                d.text((i * s + 2, 2), str(x0 + i), fill=(255, 255, 120))
            for j in range(0, h + 1, 5):
                d.line([(0, j * s), (img.width, j * s)], fill=(255, 0, 255, 70))
                d.text((2, j * s + 2), str(y0 + j), fill=(255, 255, 120))
        out = "%s_%s.png" % (prefix, group)
        img.convert("RGB").save(out)
        print(out, img.size)


if __name__ == "__main__":
    prefix = sys.argv[1]
    scale = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    render(bm.build(bm.Painter(), bm.legacy_layers()), prefix, scale=scale)
