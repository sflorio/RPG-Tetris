# RPG-Tetris

Godot **4.7.2** (standard build, GDScript only, GL Compatibility). An RPG on GDQuest's OpenRPG
where every fight is two Tetris boards. Read `README.md` for the game, `TETRIS_INTEGRATION.md` for
combat, `DESIGN_ALIGNMENT.md` for what is built against the design and what is still open.

## Checking a change — do this, don't guess

Godot is at `C:\Godot_v4.7.2-stable_win64_console.exe` (also `$GODOT`). Use the wrapper:

```bash
python tools/godot.py check                    # scripts + headless boot + content check (~20s)
python tools/godot.py map MainHall             # an area as a text grid: walls, NPCs, doorways
python tools/godot.py walk l,l,d,x -- --spawn=Kitchen   # walk headless, report each step's cell
python tools/godot.py shot res://tools/sandbox/field_sandbox.tscn -f 120 -- --spawn=Quinn --walk=x
python tools/godot.py shot res://tools/sandbox/combat_sandbox.tscn -f 120   # straight into a battle
python tools/godot.py run [scene]              # windowed, for the user to play
python tools/check_content.py [-v]             # dialogue/content only (part of `check`)
```

- A PostToolUse hook parse-checks the whole project after every `.gd` edit and reports errors
  back. A clean check is silent.
- After any visual change, take a `shot` and **look at the PNG** before saying it works.
- **Reach for `map` before a screenshot** when the question is about layout, reachability or
  where something is: it is text, exact, and far cheaper than an image.
- **Field sandbox** (`tools/sandbox/field_sandbox.tscn`) is the real overworld minus the Opening.
  After `--`: `--spawn=` an area (Town StorageAttic Kitchen MainHall House Forest), a gamepiece
  name (lands beside it, facing it) or `x,y`; `--walk=` steps `u d l r` / `x` interact / `w` wait;
  `--set=Var=Value` sets a Dialogic variable first (story state, e.g. `Chapter1Stage=2`).
  Doorways are taken like in play, so `walk` is how to prove a route works.
- A `shot` must cover the walk: roughly 12 frames per step, 45 per doorway, 15 after an `x`.
- **Combat sandbox** takes `--arena=res://...tscn` for another encounter and
  `--effect=Blind[:tier]` (repeatable) to start with a status effect on the first ally.
- `check_content.py` reads timelines, characters, Dialogic variables, signals and every `res://`
  path. A speaker that resolves to a same-named character in another folder is an error.
- `scn/Main.tscn` on its own floods "InputMap action tetris_* doesn't exist": its actions are only
  registered by `TetrisControls` when a real battle starts. Use the combat sandbox instead.
- Never run Godot with `-e` or `--import`: editor mode reopens scenes and re-saves files.
- `python -m gdtoolkit.linter <path>` lints style (config in `gdlintrc`; `scr/` and `addons/`
  excluded). It cannot parse every 4.7 construct — Godot's parser is the authority.

## Layout

| Path | What |
|---|---|
| `src/combat/` | Tetris battle: units, attacks, damage (`attack_resolver.gd`), status effects (`status/status_effect_defs.gd` is the effect table), UI |
| `src/field/` | Overworld from OpenRPG: gameboard, gamepieces, cutscenes, UI |
| `src/common/` | Party, player, music, screen transitions |
| `scr/`, `scn/` | The Tetris board from PokeTetris (`Grid.gd`). camelCase legacy code — keep its style when editing it |
| `overworld/` | Maps, dialogue (Dialogic `.dtl`), characters, encounter arenas |
| `combat/` | Battler stats and art |
| `design/` | Snapshot of the design vault (source of truth: publish.obsidian.md/projectfour). Read-only |
| `tools/` | Python map pipeline + dev tools. See `tools/README.md` |
| `addons/dialogic/` | Third-party. Carries 3 local patches for 4.7 (README "Local patch to Dialogic") — don't update it blindly |

Autoloads (in `project.godot`): `Camera`, `Party`, `CombatEvents`, `FieldEvents`, `Gameboard`,
`GamepieceRegistry`, `Music`, `Player`, `Transition`, `Dialogic`, plus the board's `Utilities`,
`Constants`, `MatrixOperations`, `BlockTextures`. Systems talk through the `*Events` signal buses.

## Rules that are easy to break

- **`src/main.tscn` map layers and the inn are generated.** Don't hand-edit tile data or the inn's
  nodes; change `tools/build_maps.py` / `tools/build_inn.py` and run the pipeline (`/rebuild-maps`).
  Then `python tools/check_maps.py` must pass — it also proves the inn is walkable end to end.
- The board reports *what happened* (`lines_cleared`, `round_finished`); it never decides damage or
  victory. Combat rules belong in `src/combat/`, not in `scr/`.
- Placeholder numbers (stat scaling, enemy cast times, 18% status chance) are flagged in code as
  placeholders. Keep them flagged; don't present them as design values.
- `design/` is fetched, not written. When code and design disagree, record it in
  `DESIGN_ALIGNMENT.md`.
- Oryx art in `resoursces/` (sic) is licensed and gitignored — never commit from it.

## Style

- GDScript: static typing everywhere, `: =` inference, `##` doc comments on classes and public
  functions explaining *why*. Tabs. Match the surrounding file.
- Commits: imperative subject describing the player-visible effect ("Fix the player walking into
  an invisible room"); body explains cause and fix in prose, ending with how it was verified.
