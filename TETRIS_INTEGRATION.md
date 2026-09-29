# Tetris combat

Fights are resolved by playing Tetris. Clearing a line makes the character that
block is assigned to attack; the fight ends when every enemy is down, or when you
top out.

Implements the Boards, Unit Stats, Status Effects and Controls notes from the
design vault: two boards, character attacks, Rounds, the Union meter, a scripted
enemy team, Xenoblocks, and ten of the fourteen status effects. See
[DESIGN_ALIGNMENT.md](DESIGN_ALIGNMENT.md) for what is still outstanding.

![Tetris battle](media/tetris_battle_screenshot.png)

## How to run

Requires **Godot 4.7** (tested on 4.7.2), standard build.

```bash
godot --path .
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

## Presentation

**Attack call-outs.** A landing attack announces itself like a fighting game: a
named call-out, a big outlined number, and a hit counter when several land at
once. The heaviest attack in the batch decides the wording and colour, so a Rally
Strike is never announced as a plain hit.

| Attack | Call-out | Colour |
|---|---|---|
| Basic | `HIT` | white |
| Special | `SPECIAL!` | cyan |
| Special +50% | `SUPER SPECIAL!!` | violet |
| Rally Strike | `RALLY STRIKE!!` | gold |
| Union Assault | `UNION ASSAULT!!!` | red |

**Status call-outs.** An effect taking hold announces itself too — `BLINDED!`,
`POISONED!`, `SHIELDED!` — in red for an affliction and green for a boon, with the
afflicted unit and the exact tier beneath. It trails the damage number by a beat
so the two read in order. Without this a third of the board simply went dark with
no stated cause.

A Perfect Strike turns the number red and adds `PERFECT STRIKE`; a fully dodged
attack reads `MISS`. Heavier attacks overshoot further on the scale punch, shake
on impact and hold longer before drifting off. All of it is in
`src/combat/ui/ui_combat_popup.gd`.

**Impact effects.** Borrowed in spirit from SNES-era JRPG combat — Chrono Trigger
in particular, whose Dual and Triple Techs are the same idea as Rally Strikes and
the Union Assault. All of it is drawn in code; no third-party art is used.

| Effect | Where |
|---|---|
| Cleared rows flash and expand, harder for a bigger clear | `Grid._spawn_line_flash` |
| Screen shake scaled to the attack's weight | `TetrisBattle._shake_screen` |
| Screen wash on Special+50%, Rally Strike and Union Assault | `TetrisBattle._flash_screen` |
| Defeated units blow out white, then dissolve and sink | `UIUnitRoster._play_downed` |

The screen flash is deliberately weak (peak alpha ~0.13). It covers the rosters
and tally as well as the boards, so a strong wash blanks the HUD instead of
punctuating the hit.

**Effect sprites.** Oryx FX sit on top of the code-drawn flashes, fired from
`src/combat/ui/combat_fx.gd`:

| Moment | Effect |
|---|---|
| A line clears | teal ring on each cleared row |
| Basic Attack | yellow starburst |
| Special | white cross slash |
| Special +50% | fire burst |
| Rally Strike | larger fire burst |
| Union Assault | blue detonation |
| A Xenoblock is queued | magenta plume |
| Rally Strike grants Shield | blue guard ring |

They are drawn *behind* the call-out (`z_index` 14 against the popup's 20) and kept
well under the board width. At full size they buried the damage number and spilled
past the playfield.

**Board style.** `BoardSkin` restyles each board instance at runtime: the red
pixel frame and the Kremlin are hidden, backgrounds go dark slate, the Hold/Next/
Score frames are dropped, and the DOS pixel font is swapped for Roboto Bold. The
blocks themselves are flat and rounded with a soft top gloss, generated by
`BlockTextures` — edit `PIECE_COLORS` there to restyle every block, preview and
ghost piece at once.

## Xenoblocks

Malformed blocks, per the design's Boards note. Shapes live in `scr/XenoBlocks.gd`.

**They need no rotation code of their own.** Under
[SRS](https://harddrop.com/wiki/SRS) a piece is a square bounding box, rotation
turns that box's contents, and the wall kicks belong to *the box and its rotation
centre* — not to which cells are filled. The offset formulation makes it explicit:
`kick(A→B) = offset[A] − offset[B]`, with the cells never entering. The board's
`getPosibleRotation` already picks its kick table by `shape.size()`, so:

| Box | Kick table | Used by |
|---|---|---|
| 3×3 | J/L/S/T/Z | every `-` form, and the `+` forms of T/J/L/S/Z |
| 4×4 | I | the `+` forms of I and O |

So a Xenoblock only has to declare which cells of its box are filled.

**The `-` forms were recoverable from the vault.** Its artwork is reused across
them — `O-`=`L-`, `T-`=`Z-`, `J-`=`S-`. Removing a cell from a tetromino leaves a
tromino and there are only two, so every `-` except `I-` is the same L-tromino at a
different spawn orientation; `I-` is the straight one.

**All 19 forms are encoded**: seven `+` pentominoes, five `#` (the design lists
none for I or O, and `XenoBlocks.has_form()` reports false for those) and the
shared `-` trominoes. Each is verified to keep its cell count and box size through
a full rotation cycle and to rotate on the live board.

Corrupted blocks use colour index **8**, painted a magenta deliberately unlike any
normal block, so one arriving in the Next queue is unmistakable.

**Infection** is what puts them there: each infected ally rolls once per Round, so
two infected allies corrupt the queue roughly twice as often. A `XENOBLOCK!` notice
fires when one is pushed, for the same reason the status call-outs exist — a
misshapen piece appearing with no explanation is exactly the confusion the Blind
fog caused. Injection goes through `Grid.force_next_shape`, the same queue
mechanism Haste uses.

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
| Infection | 30% per infected ally per Round to push a Xenoblock into the queue | yes |
| Golden / Charged | Clearing heals / restores TP | needs per-block state |
| Burning / Frozen / Thorned | Blocks decay / clear twice / hurt you | needs per-block state |

**Compound effects**: applying Renew while Poisoned or Bleeding clears both, per
the design's Compound Effects table.

### Making them legible

Each of these fails silently by nature, so each is announced where the player
notices it:

| Effect | What the player sees |
|---|---|
| Blind | The fogged third is labelled `BLIND`, not just dark |
| Confusion | The preview column is covered with `?` marks rather than vanishing |
| Shocked | Pressing rotate shows `ROTATION LOCKED — Shocked` and shakes the screen |
| Poison / Renew | The health change floats off the unit each Round |
| Infection | A `XENOBLOCK!` notice when a corrupted block is queued |

On top of that, a strip above the board lists every effect currently changing how
it plays, with rounds remaining and what it does — `BLIND+ 3 / board hidden`,
`SHOCKED 3 / cannot rotate`. The call-outs fire once when an effect lands; the
strip is what answers "why is my board like this?" at any moment afterwards.

Blind, Shocked and Confusion are carried by units but act on the board. Any
afflicted ally affects the whole team's board — the simplest reading of "some Unit
Effects will affect the Board".

Enemies have an 18% chance to inflict an effect when an attack lands, and Rally
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
| `src/combat/ui/ui_combat_popup.gd` | Hit and status call-outs |
| `src/combat/ui/board_skin.gd` | Runtime restyle of a board instance |
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

**The five per-block effects** — Golden, Charged, Burning, Frozen, Thorned. All
five need the same thing: the board storing a *state per cell* alongside its
colour. `grid[x][y]` is only a colour index today, so there is nowhere to record
"this block is frozen". One change to `Grid` unlocks all of them.

**Enemy variety.** Every enemy uses a Basic Attack on a speed-derived timer. The
design gives them attack tables, so specific enemies should inflict specific
effects rather than all of them rolling against one shared list.

**Numbers that are first-pass, not designed:** the damage formula in
`attack_resolver.gd`, enemy cast times in `tetris_battle_config.gd`, and the 18%
enemy status-infliction chance. Each is marked in the code.

**No audio at all.**

See [DESIGN_ALIGNMENT.md](DESIGN_ALIGNMENT.md) §4 for the order, and §5 for what
is still waiting on a decision rather than on code.
