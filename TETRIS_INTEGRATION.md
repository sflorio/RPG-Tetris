# Tetris-combat proof of concept

Replaces OpenRPG's turn-based JRPG battles with a game of Tetris
([PokeTetris](https://github.com/jpcerrone/PokeTetris), MIT). Walk into an enemy
on the field and a Tetris board pops up instead of the battle screen.

## How to run

Open `C:\Godot\godot-open-rpg` in Godot and press F5, or from a terminal:

```bash
"C:\Godot_v4.5-stable_mono_win64\Godot_v4.5-stable_mono_win64.exe" --path "C:\Godot\godot-open-rpg"
```

## Controls during a battle

| Key | Action |
|---|---|
| ← → / A D | Move piece |
| ↓ / S | Soft drop |
| ↑ / W | Hard drop |
| X | Rotate clockwise |
| Z | Rotate anticlockwise |
| Shift | Hold / swap piece |
| Esc | Forfeit the battle (counts as a loss) |

**Win:** clear the number of lines shown in the banner. **Lose:** top out, or forfeit.

![Tetris battle](media/tetris_battle_screenshot.png)

## Enemies set the difficulty

Each encounter's board is built from the enemies placed in its `CombatArena`
(`src/combat/tetris_battle_config.gd`):

| Enemy stat | Board effect | Rate |
|---|---|---|
| Total health | Lines to clear | 1 line per 25 HP |
| Total attack | Garbage rows already on the board (one gap each) | 1 row per 5 attack |
| Fastest speed | Starting level (fall speed) | +1 level per 20 speed |

With the stock arenas:

| Arena | Enemies | Lines | Garbage | Start level |
|---|---|---|---|---|
| `test_combat_arena.tscn` | Bugcat ×3 | 6 | 6 | 3 |
| `test_combat_arena2.tscn` | Bugcat, Wolf | 6 | 4 | 3 |

The two come out similar because OpenRPG's sample enemies have near-identical
stats (Bugcat 50 HP, Wolf 100 HP, both 10 attack). Different stats or the
overrides below make encounters diverge.

### Per-arena overrides

Open an arena scene, select its root, and use the **Tetris Battle** group in the
inspector:

| Property | Default | Meaning |
|---|---|---|
| `tetris_target_lines` | `0` | Lines to win. `0` = derive from health |
| `tetris_garbage_rows` | `-1` | Starting garbage. `-1` = derive from attack |
| `tetris_start_level` | `0` | Starting level. `0` = derive from speed |

To retune every encounter at once, change the three constants at the top of
`tetris_battle_config.gd`.

## Why this was easy: OpenRPG already had the right seam

Combat in OpenRPG is bounded by two signals, so the battle implementation is
swappable without touching the overworld at all:

```
FieldEvents.combat_triggered(arena)  →  [ battle ]  →  CombatEvents.combat_finished(won)
```

`field.gd` hides the map on `combat_initiated` and shows it again on
`combat_finished`; `combat_trigger.gd` awaits `combat_finished` to run its
victory/loss cutscene. Emitting those two signals is the entire contract, so the
Tetris battle drops straight in.

## What changed

| File | Change |
|---|---|
| `src/combat/tetris_battle_config.gd` | **New.** `TetrisBattleConfig.from_arena()` turns an arena's enemy stats into lines / garbage / level, applies per-arena overrides, and names the enemies for the banner. |
| `src/combat/tetris_battle.gd` | **New.** Hosts the PokeTetris `Main` scene under a "VS …" banner, scales/centres the board into the viewport, gives it its own 16px font theme, and re-emits its outcome as `finished(won, score, lines)`. |
| `src/combat/combat.gd` | `setup()` now branches on `use_tetris_combat` and passes the triggering arena to `_setup_tetris_combat()`. Added `_on_tetris_combat_finished()` and `_display_tetris_results_dialog()`. The original JRPG flow is untouched, just renamed to `_setup_jrpg_combat()`. |
| `src/combat/combat_arena.gd` | Added the three `tetris_*` override exports. |
| `scr/Grid.gd` | Added `battle_finished` signal, `target_lines`, `start_level`, `garbage_rows`, `_apply_battle_setup()` and `_finish_battle()`. **Replaced two `get_tree().quit()` calls** — on top-out and on Escape — which would otherwise have closed the whole RPG. |
| `project.godot` | Merged PokeTetris's 4 autoloads and 4 input actions (`rotate_clockwise`, `rotate_anticlockwise`, `swap_piece`, `ui_exit`). |
| `.gitignore` | `/audio` → `/audio/*` plus an exception, so the Tetris music isn't silently dropped on a fresh clone. |
| `scr/ scn/ spr/ fonts/ extras/ audio/` | PokeTetris files, copied at their **original `res://` paths** so none of its internal `preload()` strings needed rewriting. |

## Switching back to JRPG combat

Select the `Combat` node in `src/main.tscn` and untick **Use Tetris Combat** in
the inspector, or change the default in `src/combat/combat.gd`:

```gdscript
@export var use_tetris_combat: = true      # false restores turn-based battles
```

## Godot version note

OpenRPG was authored against Godot **4.6.2**. It was imported and run here with
the installed Godot **4.5**, which rewrote `config/features` to `"4.5"` and
opened it without errors. Two side effects of that re-save were repaired:
Dialogic's `dch_directory` / `dtl_directory` maps were blanked and have been
restored from git. If you later move to 4.6+, expect `config/features` to flip
back.

## Verified

- Derived configs for both stock arenas and the no-arena fallback (4 lines, no garbage, level 1).
- Garbage rows: correct count, exactly one gap per row, level label and fall speed applied.
- End-to-end win path (arena 1) and loss path (arena 2, forced top-out): `combat_triggered` →
  field hides → board live → results dialog → `combat_finished(won)`.
- Windowed 1920×1080 screenshot of the live battle (above). Boots with zero script errors.

## What this PoC deliberately does NOT do

Difficulty is fixed when the battle starts. Enemies don't act during the fight —
no garbage pushed on a timer, no status effects — and your party and creature
modifiers have no effect on the board yet. Those are the parts that would make
it an RPG rather than Tetris with walking in between.
