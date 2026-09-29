"""Writes the rebuilt maps into src/main.tscn and moves the gameboard from 16px to 24px cells.

Rebuilding the tiles is only half the job: the Oryx world tiles are 24px, so the gameboard's cell
size, every authored pixel position and the field's on-screen scale have to move with them. Cell
coordinates are untouched, which is why the gamepieces, doors and triggers still land where they
did.

Run it again after changing tools/build_maps.py. Rebuilding tiles repeats safely; the 16px-to-24px
migration runs only once, guarded by the cell size already recorded in gbprops.tres.

The migration also scaled the collision shapes in the shared cutscene scenes -- Interaction.tscn,
Trigger.tscn, interaction_popup.tscn and door.tscn. Those were a one-off edit, not something this
script owns; DESIGN_ALIGNMENT.md section 7 lists them.
"""
import os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_maps as bm
import oryx_atlas as oa
import tilemap_io as tio

SCENE = bm.SCENE
GBPROPS = os.path.join(oa.ROOT, "overworld", "maps", "gbprops.tres")

OLD_CELL, NEW_CELL = 16, 24
SCALE = NEW_CELL / float(OLD_CELL)          # 1.5: pixel positions, speeds and radii
FIELD_SCALE_BEFORE, FIELD_SCALE_AFTER = 5, 3  # keeps roughly the same number of cells on screen

TILESET_LINE = ('[ext_resource type="TileSet" path="res://overworld/maps/tilesets/'
                'oryx_world.tres" id="7_po5fq"]')

# The decorative layers the Oryx autotiles need: a base fill underneath, transitions on top.
# They deliberately do not carry gameboard_layer.gd, so they cannot change what is walkable.
NEW_LAYERS = [
    ("Field/Map/Town/Ground", "GroundCover", "Field/Map/Town", 3100100),
    ("Field/Map/Forest/Terrain", "Undergrowth", "Field/Map/Forest", 3100101),
]

POSITIONAL = re.compile(
    r"^(position|arrival_coordinates) = Vector2\(([-\d.e+]+), ([-\d.e+]+)\)$")
SCALAR = re.compile(r"^(move_speed|radius) = ([-\d.e+]+)$")
NODE = re.compile(r'^\[node name="([^"]+)"(?: type="([^"]+)")?(?: parent="([^"]+)")?', re.M)


def fmt(value):
    return ("%g" % value) if value != int(value) else str(int(value))


def scale_positions(text):
    """Scales the authored pixel positions under Field/Map, leaving the UI alone."""
    out, node_parent, changed = [], None, 0
    for line in text.splitlines():
        m = NODE.match(line)
        if m:
            node_parent = m.group(3)
        elif node_parent and node_parent.startswith("Field/Map"):
            p = POSITIONAL.match(line)
            s = SCALAR.match(line)
            if p:
                line = "%s = Vector2(%s, %s)" % (
                    p.group(1), fmt(float(p.group(2)) * SCALE), fmt(float(p.group(3)) * SCALE))
                changed += 1
            elif s:
                line = "%s = %s" % (s.group(1), fmt(float(s.group(2)) * SCALE))
                changed += 1
        out.append(line)
    print("  scaled %d authored positions" % changed)
    return "\n".join(out) + ("\n" if text.endswith("\n") else "")


def node_block(name, parent, uid):
    return (
        '\n[node name="%s" type="TileMapLayer" parent="%s" unique_id=%d]\n'
        'tile_map_data = PackedByteArray("")\n'
        'tile_set = ExtResource("7_po5fq")\n'
        'metadata/_edit_lock_ = true\n' % (name, parent, uid))


def insert_layers(text):
    for after_path, name, parent, uid in NEW_LAYERS:
        if '[node name="%s" type="TileMapLayer" parent="%s"' % (name, parent) in text:
            continue
        anchor = '[node name="%s" type="TileMapLayer" parent="%s"' % (
            after_path.rsplit("/", 1)[1], after_path.rsplit("/", 1)[0])
        start = text.index(anchor)
        end = text.index("\n[node ", start)
        text = text[:end] + "\n" + node_block(name, parent, uid).lstrip("\n") + text[end:]
        print("  added %s/%s" % (parent, name))
    return text


def write_layers(text, layers):
    """Swaps each layer's cell data for the rebuilt version, in place."""
    replacements = []
    for path, _name, _parent, b64, span in tio.layers(text):
        if path not in layers:
            continue
        header = tio.decode(b64)[0] if b64 else b"\x00\x00"
        cells = sorted(layers[path], key=lambda c: (c[1], c[0]))
        replacements.append((span, tio.encode(header, cells)))
    for (start, end), data in sorted(replacements, reverse=True):
        text = text[:start] + data + text[end:]
    print("  rewrote %d layers" % len(replacements))
    return text


def main():
    text = open(SCENE, encoding="utf-8").read()
    props = open(GBPROPS, encoding="utf-8").read()

    # Rebuilding tiles is safe to repeat; rescaling pixel positions is not. The gameboard's cell
    # size is the record of whether the migration has already run.
    migrate = "cell_size = Vector2i(%d, %d)" % (OLD_CELL, OLD_CELL) in props

    layers = bm.build(bm.Painter(), bm.legacy_layers())
    text = insert_layers(text)
    text = write_layers(text, layers)

    text = re.sub(r'^\[ext_resource type="TileSet"[^\n]*kenney_terrain\.tres" id="7_po5fq"\]$',
                  TILESET_LINE, text, flags=re.M)

    # The one map sprite still cut from the retired dungeon sheet.
    text = text.replace(
        'texture = ExtResource("9_woa3f")\nregion_enabled = true\nregion_rect = Rect2(85, 51, 16, 16)',
        'texture = ExtResource("1_oryxw")\nregion_enabled = true\n'
        'region_rect = Rect2(792, 312, 24, 24)')
    if 'id="1_oryxw"' not in text:
        text = text.replace(
            '[ext_resource type="Texture2D" uid="uid://dm4h0uo6gjp22" '
            'path="res://overworld/maps/tilesets/dungeon_tilemap.png" id="9_woa3f"]',
            '[ext_resource type="Texture2D" path="res://assets/tiles/oryx_world.png" '
            'id="1_oryxw"]')

    if migrate:
        text = text.replace(
            '[node name="Main" type="Node2D" unique_id=24929608]\nscale = Vector2(%d, %d)'
            % (FIELD_SCALE_BEFORE, FIELD_SCALE_BEFORE),
            '[node name="Main" type="Node2D" unique_id=24929608]\nscale = Vector2(%d, %d)'
            % (FIELD_SCALE_AFTER, FIELD_SCALE_AFTER))
        # The trigger volume that ends the game, authored in pixels outside any node block.
        text = text.replace("size = Vector2(14, 23)", "size = Vector2(21, 34.5)")
        text = scale_positions(text)
        props = props.replace("cell_size = Vector2i(%d, %d)" % (OLD_CELL, OLD_CELL),
                              "cell_size = Vector2i(%d, %d)" % (NEW_CELL, NEW_CELL))
        open(GBPROPS, "w", encoding="utf-8", newline="\n").write(props)
        print("  wrote", GBPROPS)
    else:
        print("  already on %dpx cells, leaving positions alone" % NEW_CELL)

    open(SCENE, "w", encoding="utf-8", newline="\n").write(text)
    print("  wrote", SCENE)


if __name__ == "__main__":
    main()
