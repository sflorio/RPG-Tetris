---
name: rebuild-maps
description: Rebuild the overworld maps (Town, House, Forest, Emberlight Inn) from the Python pipeline in tools/ and verify them. Use when changing how a map looks, moving props or doorways in the inn, editing tools/build_maps.py, build_inn.py, oryx_atlas.py or make_buildings.py, or when src/main.tscn tile layers need regenerating.
---

# Rebuild the maps

The map layers and the inn in `src/main.tscn` are generated. Never hand-edit tile data there.

## 1. Decide which steps are needed

| You changed | Run from |
|---|---|
| `make_buildings.py`, `make_world_atlas.py`, the house kit | step A (needs the Oryx pack in `resoursces/`; stop and tell the user if it is missing) |
| `oryx_atlas.py`, tile catalogue, blocking flags | step B |
| `build_inn.py` (inn rooms, props, cast, doorways) | step C |
| `build_maps.py` (how Town/House/Forest are painted) | step D |

Each step is idempotent; running from an earlier one is always safe.

```bash
python tools/make_world_atlas.py   # A
python tools/build_tileset.py      # B
python tools/apply_inn.py          # C
python tools/apply_maps.py         # D - also rewrites src/main.tscn
```

## 2. Verify — all three, in order

```bash
python tools/check_maps.py         # walkable cells unchanged + inn walkable end to end
python tools/godot.py check        # scene still loads, no script errors
python tools/render_oryx.py .godot/preview   # .godot/preview_town.png, _house.png, _forest.png
```

- `check_maps.py` failing means a cell became blocked or a doorway/NPC is unreachable. Fix the
  painting rules; don't loosen the check.
- **Look at the rendered PNGs** (Read them) before saying the map is right.
- The game opens on a name prompt, so a `shot` of the main scene cannot reach the maps. Say
  what you could not verify in-game rather than claiming it.

## 3. Report

`git diff --stat src/main.tscn` will be large; that is expected. Summarise what changed visibly
and which checks passed.
