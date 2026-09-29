"""Read and write the TileMapLayer data embedded in a Godot .tscn file.

Godot stores a layer as base64 of: a 2-byte format header, then 12 bytes per cell,
`<hhhhhh` = x, y, source_id, atlas_x, atlas_y, alternative_tile. Coordinates are cell
based, so swapping tilesets preserves a layout.
"""
import base64, re, struct

NODE_RE = re.compile(r'^\[node name="([^"]+)" type="TileMapLayer" parent="([^"]+)"', re.M)
DATA_RE = re.compile(r'^tile_map_data = PackedByteArray\("([^"]*)"\)', re.M)


def decode(b64: str):
    raw = base64.b64decode(b64)
    header = raw[:2]
    cells = []
    for i in range(2, len(raw), 12):
        x, y, src, ax, ay, alt = struct.unpack_from("<hhhhhh", raw, i)
        cells.append((x, y, src, ax, ay, alt))
    return header, cells


def encode(header: bytes, cells) -> str:
    out = bytearray(header)
    for c in cells:
        out += struct.pack("<hhhhhh", *c)
    return base64.b64encode(bytes(out)).decode("ascii")


def layers(text: str):
    """Yields (path, name, parent, b64, span) for every TileMapLayer that carries data."""
    found = []
    for m in NODE_RE.finditer(text):
        name, parent = m.group(1), m.group(2)
        block_end = text.find("\n[node ", m.end())
        if block_end == -1:
            block_end = len(text)
        d = DATA_RE.search(text, m.end(), block_end)
        if d is None:
            continue
        found.append(("%s/%s" % (parent, name), name, parent, d.group(1), d.span(1)))
    return found


if __name__ == "__main__":
    import sys, collections
    text = open(sys.argv[1], encoding="utf-8").read()
    for path, name, parent, b64, _ in layers(text):
        _, cells = decode(b64)
        by_src = collections.Counter((c[2], c[3], c[4]) for c in cells)
        xs = [c[0] for c in cells] or [0]
        ys = [c[1] for c in cells] or [0]
        print("%-46s cells=%-6d distinct=%-4d x=[%d..%d] y=[%d..%d]"
              % (path, len(cells), len(by_src), min(xs), max(xs), min(ys), max(ys)))
