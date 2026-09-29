# Map tools

The overworld maps are generated, not hand-painted. These scripts build the Oryx
tileset and rebuild Town, House and Forest from it. They are development tools —
nothing here runs at game time.

They need Python 3 and Pillow (`python -m pip install Pillow`), and the purchased
Oryx pack unzipped into `resoursces/` (gitignored). Only the first script needs
the pack; everything after it works from `assets/tiles/oryx_world.png`.

## Pipeline

Run in this order. Each step is idempotent.

```bash
python tools/make_world_atlas.py   # Oryx sheet -> assets/tiles/oryx_world.png
python tools/build_tileset.py      # -> overworld/maps/tilesets/oryx_world.tres
python tools/apply_maps.py         # rebuild the maps and write src/main.tscn
python tools/check_maps.py         # assert the gameboard did not change
```

To see the result without opening Godot:

```bash
python tools/render_oryx.py out    # writes out_town.png, out_house.png, out_forest.png
python tools/render_map.py old     # the same maps before the retile, for comparison
```

## What each file is

| File | Job |
|---|---|
| `make_world_atlas.py` | keys pure black out of the Oryx world sheet and bakes in the one terrain piece the pack omits |
| `oryx_atlas.py` | the catalogue: which coordinates are terrain, trees, walls, floors, doors, props |
| `build_tileset.py` | writes the TileSet, deriving terrain peering bits from the artwork and setting `IsCellBlocked` |
| `build_maps.py` | decides what every cell becomes; this is the file to edit to change how a map looks |
| `apply_maps.py` | writes the layers into `src/main.tscn` and holds the 16px -> 24px migration |
| `check_maps.py` | compares walkable cells before and after |
| `render_oryx.py`, `render_map.py` | offline previews |
| `tilemap_io.py`, `tileset_io.py` | read and write Godot's `tile_map_data` and `.tres` tile entries |
| `make_cursor.py` | draws the 24px field cursor |

## legacy_maps.json

The maps exactly as GDQuest authored them, on the Kenney tiles. `build_maps.py`
reads its *shape* from here — which cells exist, which block movement, what each
one was — rather than from whatever is currently in the scene. That is what makes
`apply_maps.py` safe to re-run after changing the painting rules, and it is why
`overworld/maps/tilesets/kenney_terrain.tres` is still in the repository:
`check_maps.py` reads the old blocking flags out of it.
