# RPG-Tetris

An RPG where every fight is played out on a Tetris board.

You are a natural-born psion working at a small-town inn, in a kingdom where the
School of Psionics is forbidden. An alien force invades to siphon the mana the
planet gives off, and your ability — the thing you were meant to hide — turns out
to be the only effective weapon against it.

Explore the world on foot; when a fight starts, two boards open. Your active team
holds the left one, the enemy team the right. Clearing a line makes one of your
characters attack, and the fight ends when every enemy is down — or when you top
out.

![Tetris battle](media/tetris_battle_screenshot.png)

## Running it

**Requires Godot 4.7** (tested on 4.7.2). Get it from
[godotengine.org/download](https://godotengine.org/download) — the **standard**
build, not .NET/Mono; there is no C# in this project.

Import `project.godot` from the Godot project manager and press **F5**. The first
import takes a minute while assets are converted.

```bash
godot --path .
```

## Controls

Two keyboard schemes, because the design maps the same keys to different jobs.
Keyboard A is the default; switch with
`TetrisControls.apply(TetrisControls.Scheme.KEYBOARD_B)`.

| | Keyboard A | Keyboard B | Controller |
|---|---|---|---|
| **Field** — move | WASD / arrows | WASD / arrows | D-Pad |
| **Field** — talk, confirm | Space | Space | B |
| **Combat** — move piece | `A` `D` | `←` `→` | D-Pad |
| **Combat** — soft / hard drop | `S` / `W` | `↓` / `↑` | D-Pad |
| **Combat** — rotate | `←` `→` | `A` `D` | A (right only) |
| **Combat** — hold | Space | Space | X |
| **Combat** — forfeit | Esc | Esc | B |

Rotate-left has no controller binding: the design assigns `A` to both rotate
directions, which cannot work. Needs a decision.

## How combat works

The **block** you clear with decides *who* attacks; the **number of lines**
decides *how*:

| Lines | Result |
|---|---|
| 1 | That character's Basic Attack |
| 2 | Special Attack |
| 3 | Special Attack, +50% |
| 4 | Every active ally's Rally Strike |

Four-line clears are only reachable with the Line block, which is why it belongs
to no character — it is the Rally Strike trigger. Every cleared line also fills
the **Union meter**; at ten it fires a Union Assault automatically.

Enemies charge over Rounds (one completed drop = one Round) and strike when their
cast completes. They can inflict status effects that change how your board plays —
fogging a third of it, locking rotation, hiding the preview, or corrupting your
block queue with Xenoblocks.

**See [TETRIS_INTEGRATION.md](TETRIS_INTEGRATION.md)** for the full model: damage,
status effects, Xenoblocks, and the files to edit for each.

## What is built

| Area | State |
|---|---|
| Overworld, maps, dialogue, encounters, saving | from OpenRPG, working |
| Two boards, 10×40, Rounds | done |
| Character attacks, Rally Strikes, Union meter | done |
| Unit and party stats, Psionic Power gating | done |
| Scripted enemy team with cast timers | done |
| Status effects | 10 of 14 |
| Xenoblocks and Infection | done |
| Golden / Charged / Burning / Frozen / Thorned | **not started** — need per-cell board state |
| Techniques, Soul Gems, Trinkets, Constellations, Field Actions | **not started** |
| Audio | **none** |

Characters and enemies use Oryx sprites mapped onto the design's names — Soldier
and Archer against Xeno Drone and Xeno Stalker — but they are still GDQuest's
placeholder battlers underneath, with the stats and arenas to match.
`src/combat/unit_appearance.gd` does that mapping and goes away once real units
exist. The damage formula and enemy cast times
are first-pass numbers, not designed ones — both are flagged in the code.

## Design source

The game is specified in an Obsidian vault at
[publish.obsidian.md/projectfour](https://publish.obsidian.md/projectfour).
[DESIGN_ALIGNMENT.md](DESIGN_ALIGNMENT.md) tracks the implementation against it,
including what is still outstanding and the inconsistencies found in the vault
itself.

## Repository map

```
scr/          the Tetris board (from PokeTetris), block and Xenoblock shapes
scn/          the board scene
src/field/    overworld: grid, movement, triggers, cutscenes   (OpenRPG)
src/combat/   the battle: units, attacks, status effects, UI
overworld/    maps, dialogue, characters, encounter arenas
combat/       battler stats and art
addons/       Dialogic
```

## Local patch to Dialogic

Godot 4.7 made "not all code paths return a value" a parser error, and the
bundled Dialogic has three functions that fall off the end. They now return
explicitly:

| File | Function |
|---|---|
| `addons/dialogic/Modules/Variable/subsystem_variables.gd:179` | `_get` → `return null` |
| `addons/dialogic/Modules/Variable/subsystem_variables.gd:~242` | `VariableFolder._get` → `return null` |
| `addons/dialogic/Modules/Text/node_name_label.gd:18` | `_set` → `return false` |

**Updating Dialogic will overwrite these.** Re-apply them, or move to a Dialogic
release that supports Godot 4.7.

## Built on

- [godot-open-rpg](https://github.com/gdquest-demos/godot-open-rpg) by GDQuest —
  the overworld, grid movement, dialogue and encounter system (MIT). Kept as the
  `upstream` remote.
- [PokeTetris](https://github.com/jpcerrone/PokeTetris) by jpcerrone — the board,
  [SRS](https://harddrop.com/wiki/SRS) rotation and wall kicks (MIT).
- [Dialogic](https://github.com/dialogic-godot/dialogic) for dialogue.

Unit sprites are 16-bit Fantasy by **Oryx Design Lab**
([oryxdesignlab.com](https://www.oryxdesignlab.com)), used under their licence,
which permits commercial use and requires that credit. The block art itself is
generated in code (`scr/BlockTextures.gd`) rather than drawn. Asset credits are in `CREDITS.md`, licences
in `LICENSE`. `CHANGELOG.md` is OpenRPG's, kept from upstream.
