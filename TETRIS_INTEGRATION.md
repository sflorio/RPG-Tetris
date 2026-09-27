# Tetris combat

Fights are resolved by playing Tetris. Clearing a line makes the character that
block is assigned to attack; the fight ends when every enemy is down, or when you
top out.

Implements the Boards, Unit Stats and Controls notes from the design vault. See
[DESIGN_ALIGNMENT.md](DESIGN_ALIGNMENT.md) for what is still outstanding.

![Tetris battle](media/tetris_battle_screenshot.png)

## How to run

```bash
"C:\Godot_v4.5-stable_mono_win64\Godot_v4.5-stable_mono_win64.exe" --path .
```

## Controls

Two schemes, because the design maps the same keys to different jobs. Keyboard A
is the default; switch with `TetrisControls.apply(TetrisControls.Scheme.KEYBOARD_B)`.

| Function | Keyboard A | Keyboard B | Controller |
|---|---|---|---|
| Move | `A` / `D` | `←` / `→` | D-Pad |
| Soft drop | `S` | `↓` | D-Pad Down |
| Hard drop | `W` | `↑` | D-Pad Up |
| Rotate | `←` / `→` | `A` / `D` | `A` (right only) |
| Hold / swap | `Space` | `Space` | `X` |
| Forfeit | `Esc` | `Esc` | `B` |

Rotate-left has no controller binding: the design assigns `A` to both rotate
directions, which cannot work. Needs a decision.

## The board

10 wide × 40 tall, lower 20 visible, upper 20 hidden and used to spawn blocks and
junk. Junk rows are seeded at the start so combat never begins on an empty board.

One completed drop is a **Round** (`Grid.round_finished`). That is the tick status
effects and board timers will hang off.

Fall speed comes from the party's **Gravity** stat, not from the enemies present.

## How damage works

The block used decides **who** attacks; the number of lines decides **how**:

| Lines | Result |
|---|---|
| 1 | That character's Basic Attack |
| 2 | That character's Special Attack |
| 3 | Special Attack, +50% damage |
| 4 | **Every** active ally performs their Rally Strike |

Four-line clears are only reachable with the Line block, which is why the Line
block is never assigned to anyone — it is the Rally Strike trigger.

Clearing with a block assigned to nobody still clears the line and fills the
Union meter; it just deals no damage.

**Union meter**: every cleared line fills it. At 10 lines the Union Assault fires
automatically and the meter resets. A clear can carry the total past ten (nine
plus a four-line clear reaches thirteen); each line over ten adds +10% damage.

> The design specifies which attack happens, not the damage formula. The current
> maths — Power × an attack multiplier, minus Defense or Barrier by attack Type,
> with Perfect Strike and Dodge rolled from `PSC`/`PSP`/`DOD` — is a first pass in
> `attack_resolver.gd` and is meant to be tuned.

## Block assignment

Assignable blocks (`O T J L S Z`) are dealt out across the active team, so with
two allies one holds three each. The legend under the board shows the mapping and
counts clears per block.

## Enemy health is hidden by default

Enemy bars read `???` and stay full until the **HP Sight** Psionic Power is
unlocked, per the design. To reveal them:

```gdscript
config.party.unlock_power(PartyStats.HP_SIGHT)
```

## Structure

```
CombatArena (which Battlers)
   └─> TetrisBattleConfig    allies + enemies as CombatUnits, block assignments, junk
         └─> TetrisBattle    owns the board, routes clears to characters, decides the winner
               ├─ AttackResolver   one attack -> damage (Perfect Strike, Dodge)
               ├─ UnionMeter       lines -> Union Assault
               ├─ CombatUnit       a unit's health, stats and blocks
               ├─ UITetrisEnemyList  portraits + health bars (HP Sight gated)
               ├─ UIUnionMeter       Union progress
               └─ UIClearTally       block -> character legend
```

| File | Role |
|---|---|
| `src/combat/block_types.gd` | The seven blocks; which are assignable |
| `src/combat/unit_stats.gd` | `HP/POW/DEF/BAR/PSC/PSP/DOD/TYPE/TYPE2/LVL` |
| `src/combat/party_stats.gd` | Party stats incl. Gravity, and unlocked Psionic Powers |
| `src/combat/combat_unit.gd` | A unit in battle: health + assigned blocks |
| `src/combat/attack_resolver.gd` | **Damage maths lives here.** Tune it here |
| `src/combat/attack_result.gd` | One attack's outcome |
| `src/combat/union_meter.gd` | Union threshold and overflow bonus |
| `src/combat/tetris_controls.gd` | Runtime input bindings for both schemes |
| `src/combat/tetris_battle_config.gd` | Arena Battlers -> battle setup |
| `src/combat/tetris_battle.gd` | Wires it together |
| `scr/Grid.gd` | The board. Emits `lines_cleared(count, block_type)` and `round_finished(n)` |
| `scr/BlockTextures.gd` | Block sprites, generated in code |

The board reports *what happened*; it decides neither damage nor victory (only
topping out). That keeps combat rules in one place.

## Changes made to the original PokeTetris board

- Board grown from 10×23 to 10×40; blocks spawn just above the visible area.
- Added `lines_cleared`, `round_finished` and `battle_finished` signals.
- `afterDrop()` captures which block locked **before** `currentPiece` is reset.
- Added `start_level`, `junk_rows`, `isBoardEmpty()` and `end_battle()`.
- **Replaced two `get_tree().quit()` calls** (top-out and Escape) that would
  otherwise have closed the whole game.
- Pokeball sprites replaced with generated Tetris blocks; the `poke*.png` files
  and the `PokeballTextures` autoload are gone.

## Switching back to JRPG combat

Select the `Combat` node in `src/main.tscn` and untick **Use Tetris Combat**.

## Verified

- Block assignment across the active team, with the Line block left unassigned.
- Line count → attack kind, including Rally Strike for all allies on four lines.
- Union meter filling, firing at ten and resetting.
- Damage spilling across enemies; every enemy reached updates and animates.
- HP Sight gating (hidden by default, revealed when unlocked).
- Both control schemes registering, with the board still playable after a swap.
- End to end in the real game: encounter → board → attacks → results dialog →
  `combat_finished(won)`.

## Not done yet

Single board only — the design calls for two, with the enemy team on its own
board. Enemies never act. No status effects and no Xenoblocks. See
[DESIGN_ALIGNMENT.md](DESIGN_ALIGNMENT.md) §4 for the order.
