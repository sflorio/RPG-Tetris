"""Draws the 24px field cursor: corner brackets for the hovered cell, hatching for a selection."""
import os, sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import oryx_atlas as oa

T = oa.TILE
OUT = os.path.join(oa.ROOT, "assets", "tiles", "cursor.png")

img = Image.new("RGBA", (T * 2, T), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
WHITE = (255, 255, 255, 230)

# Cell 0: corner brackets.
arm = 6
for cx, cy in ((0, 0), (T - 1, 0), (0, T - 1), (T - 1, T - 1)):
    sx = 1 if cx == 0 else -1
    sy = 1 if cy == 0 else -1
    d.line([(cx, cy), (cx + sx * arm, cy)], fill=WHITE)
    d.line([(cx, cy), (cx, cy + sy * arm)], fill=WHITE)

# Cell 1: the same brackets over a light diagonal hatch.
img.paste(img.crop((0, 0, T, T)), (T, 0))
for i in range(-T, T * 2, 6):
    d.line([(T + i, 0), (T + i + T, T)], fill=(255, 255, 255, 70))
img.paste(img.crop((0, 0, T, T)), (T, 0), img.crop((0, 0, T, T)))

img.save(OUT)
print(OUT, img.size)
