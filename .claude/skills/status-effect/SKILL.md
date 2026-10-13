---
name: status-effect
description: Implement or change a combat status effect (Shield, Haste, Renew, Poison, Bleed, Blind, Shock, Confusion, Infection, Stun, Golden, Charged, Junkdrop, Burn, Freeze, Thorns). Use when wiring up an effect that is not live yet, changing what an effect does, or adding a new one from design/Status Effects.md.
---

# Status effects

Spec: `design/Status Effects.md`. Table: `src/combat/status/status_effect_defs.gd` — every effect
is listed there with tiers (-1 weak, 0 normal, +1 strong), rounds, stacks and `"implemented"`.

## Where each kind of effect lives

| Kind | Hook into |
|---|---|
| Per-Round unit effect (Poison, Renew) | `CombatUnit.tick_effects()` in `src/combat/combat_unit.gd` |
| Board effect (Blind, Shock, Confusion) | `tetris_battle.gd` — the loop over allies around `has_effect(...)` that applies board state |
| Board strip label | `src/combat/ui/ui_board_status.gd` (`TRACKED` + `EXPLANATIONS`) |
| Call-out when it lands | `StatusEffectDefs.get_callout` + `src/combat/ui/ui_combat_popup.gd` |
| Who can inflict it | `src/combat/characters.gd` |

Golden, Charged, Burn, Freeze and Thorns need **per-cell board state** (`grid[x][y]` in
`scr/Grid.gd` is only a colour index today). That is a board change; stop and propose the design
of that change to the user before starting one of these.

## Steps

1. Read the effect's row in the design note and in `DEFS`. Note any disagreement.
2. Implement it at the hook above; keep combat rules in `src/combat/`, not `scr/`.
3. Make it legible — every effect needs a visible signal (see TETRIS_INTEGRATION.md "Making them
   legible"). An effect the player can't see is a bug.
4. Set `"implemented": true` in `DEFS`.
5. Update the effect tables in `TETRIS_INTEGRATION.md` and the count in `README.md` ("Status
   effects | N of 14") and `DESIGN_ALIGNMENT.md` Phase 4.
6. Verify: `python tools/godot.py check`, then look at the battle with the effect active:
   ```bash
   python tools/godot.py shot res://tools/sandbox/combat_sandbox.tscn -f 120 -- --effect=Blind:1
   ```
   `--effect=Name[:tier]` goes on the first ally and can be repeated. Read the PNG. Per-Round
   effects need Rounds to pass, which needs input — say so instead of claiming you saw it tick.
