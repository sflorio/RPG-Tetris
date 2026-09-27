# RPG-Tetris

An RPG where every fight is resolved by playing Tetris.

Explore a Pokémon-style overworld; when you run into an enemy, a Tetris board
opens instead of a turn-based battle screen. Clearing lines damages the enemies,
combos multiply that damage, and the fight ends when every enemy is defeated —
or when you top out.

![Tetris battle](media/tetris_battle_screenshot.png)

## Running it

**Requires Godot 4.7** (tested on 4.7.2). Get it from
[godotengine.org/download](https://godotengine.org/download) — the standard build,
not .NET/Mono; there is no C# in this project.

Import `project.godot` from the Godot project manager and press **F5**. The first
import takes a minute while assets are converted.

From a terminal, with `godot` being wherever you unpacked it:

```bash
godot --path .
```

Walk around town with the arrow keys or WASD, press Space to talk. Two
encounters start a fight: the ghost blocking the south exit, and the NPC you can
talk to.

## Combat in one line

One cleared line = one damage. Multi-line clears, combos, repeated-piece streaks
(three clears with the square doubles the damage), back-to-back Tetrises and
perfect clears all multiply it.

**See [TETRIS_INTEGRATION.md](TETRIS_INTEGRATION.md)** for the full damage model,
how enemies get their health, and how to add new combo rules.

## Local patch to Dialogic

Godot 4.7 made "not all code paths return a value" a parser error, and the
bundled Dialogic has three functions that fall off the end. They now return
explicitly:

| File | Function |
|---|---|
| `addons/dialogic/Modules/Variable/subsystem_variables.gd:179` | `_get` -> `return null` |
| `addons/dialogic/Modules/Variable/subsystem_variables.gd:~242` | `VariableFolder._get` -> `return null` |
| `addons/dialogic/Modules/Text/node_name_label.gd:18` | `_set` -> `return false` |

**Updating Dialogic will overwrite these.** Re-apply them, or move to a Dialogic
release that supports Godot 4.7.

## Built on

- [godot-open-rpg](https://github.com/gdquest-demos/godot-open-rpg) by GDQuest —
  the overworld, grid movement, dialogue and encounter system (MIT).
  Still available as the `upstream` remote.
- [PokeTetris](https://github.com/jpcerrone/PokeTetris) by jpcerrone — the Tetris
  board, SRS rotation and wall kicks (MIT).
- [Dialogic](https://github.com/dialogic-godot/dialogic) for dialogue.

Original licenses are kept in `LICENSE` and `CREDITS.md`.
