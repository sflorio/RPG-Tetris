"""Minimal reader for Godot .tres TileSet files: which tiles exist and which block movement."""
import re

SRC_RE = re.compile(r'^\[sub_resource type="TileSetAtlasSource" id="([^"]+)"\]', re.M)
TILE_RE = re.compile(r'^(\d+):(\d+)/0(?:/([\w/]+))? = (.*)$', re.M)
BIND_RE = re.compile(r'^sources/(\d+) = SubResource\("([^"]+)"\)', re.M)


def read(path):
    text = open(path, encoding="utf-8").read()
    blocks = {}
    marks = [(m.group(1), m.start()) for m in SRC_RE.finditer(text)]
    for i, (sid, start) in enumerate(marks):
        end = marks[i + 1][1] if i + 1 < len(marks) else text.find("\n[resource]")
        tiles = {}
        for t in TILE_RE.finditer(text, start, end):
            key = (int(t.group(1)), int(t.group(2)))
            tiles.setdefault(key, {})
            if t.group(3):
                tiles[key][t.group(3)] = t.group(4)
        blocks[sid] = tiles
    return {int(m.group(1)): blocks[m.group(2)] for m in BIND_RE.finditer(text)}
