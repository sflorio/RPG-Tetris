# RPG-Tetris

An RPG where every fight is resolved by playing Tetris.

Explore a Pokémon-style overworld; when you run into an enemy, a Tetris board
opens instead of a turn-based battle screen. Clearing lines damages the enemies,
combos multiply that damage, and the fight ends when every enemy is defeated —
or when you top out.

![Tetris battle](media/tetris_battle_screenshot.png)

## Running it

Open the project in Godot and press F5, or:

```bash
"C:\Godot_v4.5-stable_mono_win64\Godot_v4.5-stable_mono_win64.exe" --path .
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

## Built on

- [godot-open-rpg](https://github.com/gdquest-demos/godot-open-rpg) by GDQuest —
  the overworld, grid movement, dialogue and encounter system (MIT).
  Still available as the `upstream` remote.
- [PokeTetris](https://github.com/jpcerrone/PokeTetris) by jpcerrone — the Tetris
  board, SRS rotation and wall kicks (MIT).
- [Dialogic](https://github.com/dialogic-godot/dialogic) for dialogue.

Original licenses are kept in `LICENSE` and `CREDITS.md`.
