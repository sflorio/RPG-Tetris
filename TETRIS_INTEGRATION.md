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

## The two boards

Both are 10 wide × 40 tall, lower 20 visible, upper 20 hidden for spawning. Junk
rows are seeded on both at the start so neither begins empty.

**Left is the player's** and is the one actually played.

**Right is the enemy team's, and is scripted rather than simulated.** Nobody
places pieces on it. Its stack is a readable picture of enemy pressure: it rises
as the enemy team charges and drops back the Round they strike, so how full it
looks tells you how close the next attack is. A genuine Tetris AI is far more work
than the fight needs and the player never sees the difference. The seam is a single
method (`EnemyBoard.set_charge`), so an AI could drive the same board later.

One completed drop is a **Round** (`Grid.round_finished`). Enemies charge on Rounds
and attack when their cast completes; it is also the tick status effects will use.

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

## Enemy turns

Each enemy charges over a number of Rounds and then attacks the front ally. Cast
time is derived from the unit's speed — the design gives enemies cast bars but no
cast-time stat, so that derivation is a placeholder in `tetris_battle_config.gd`.

Allies take damage, can be downed, and the battle is **lost** when the whole active
team is down or the player tops out.

## Status effects

Effects come in three tiers, written as a suffix: `Poison-` < `Poison` < `Poison+`.
They tick once per Round. The full table lives in
`src/combat/status/status_effect_defs.gd`, including the effects not wired up yet,
so it is the single record of what the game is meant to have.

| Effect | What it does | Live |
|---|---|---|
| Shield | Halves incoming damage, consumes a stack | yes |
| Haste | That unit's block comes next (spent per block generation) | yes |
| Renew | Heals 2% max HP per Round | yes |
| Poison | 1/2/3% max HP per Round by tier | yes |
| Bleed | 1/3/5% current HP **on every rotation** | yes |
| Blind | Fogs a third of the playfield | yes |
| Shocked | The team cannot rotate | yes |
| Confusion | Hides the block preview | yes |
| Infection | Generates Xenoblocks | needs Xenoblocks |
| Golden / Charged | Clearing heals / restores TP | needs per-block state |
| Burning / Frozen / Thorned | Blocks decay / clear twice / hurt you | needs per-block state |

**Compound effects**: applying Renew while Poisoned or Bleeding clears both, per
the design's Compound Effects table.

Blind, Shocked and Confusion are carried by units but act on the board. Any
afflicted ally affects the whole team's board — the simplest reading of "some Unit
Effects will affect the Board".

Enemies have a 35% chance to inflict an effect when an attack lands, and Rally
Strikes grant the team Shield. Both are placeholders: the design gives enemies
attack tables and characters their own equipped Rally Strikes, neither modelled yet.

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
| `src/combat/enemy_board.gd` | The scripted enemy board |
| `src/combat/status/status_effect.gd` | One active effect: tier, duration, stacks |
| `src/combat/status/status_effect_defs.gd` | **The effect table.** Add effects here |
| `src/combat/ui/ui_unit_roster.gd` | Roster for either team; health + cast bars |
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

The five per-block effects (Golden, Charged, Burning, Frozen, Thorned) need the
board to track a state per cell rather than just a colour. Xenoblocks — and so
Infection — need their shapes written down as coordinates first; the vault only
has them as images. Enemies still use a Basic Attack on a timer. See
[DESIGN_ALIGNMENT.md](DESIGN_ALIGNMENT.md) §4.
