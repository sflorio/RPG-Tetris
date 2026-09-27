## A unit taking part in a battle: an ally on the active team, or an enemy.
##
## Wraps a [UnitStats] resource with the state that only exists during combat — current health, and
## for allies, which block types trigger their attacks.
class_name CombatUnit extends RefCounted

## The unit's stats. Never modified in place; combat state lives on this object.
var stats: UnitStats = null

## Current health. Reaching 0 downs the unit.
var hp: = 1

## Portrait shown beside this unit's health bar. May be null.
var icon: Texture2D = null

## Block types that trigger this unit's attacks. Allies only, and never includes the Line block.
var block_types: Array[int] = []

## True for units on the player's active team.
var is_ally: = false

## Rounds this unit needs to charge before it acts. Enemies only.
##
## The design gives enemies cast bars (see the Future Sight psionic power) but no cast-time stat,
## so this is derived from the unit's speed in [TetrisBattleConfig] and is a placeholder.
var cast_rounds: = 3

## Rounds charged so far toward the next action.
var cast_progress: = 0


func _init(unit_stats: UnitStats = null, ally: bool = false) -> void:
	stats = unit_stats if unit_stats != null else UnitStats.new()
	hp = stats.max_hp
	is_ally = ally


var display_name: String:
	get: return stats.display_name


func is_downed() -> bool:
	return hp <= 0


## Applies damage and returns how much was actually dealt, capped by remaining health so overkill
## doesn't leak onto the next unit.
func take_damage(amount: int) -> int:
	var dealt: = clampi(amount, 0, hp)
	hp -= dealt
	return dealt


func heal(amount: int) -> int:
	var healed: = clampi(amount, 0, stats.max_hp - hp)
	hp += healed
	return healed


func get_health_ratio() -> float:
	return float(hp) / float(maxi(stats.max_hp, 1))


## True when this unit attacks on clears made with `block_type`.
func handles_block(block_type: int) -> bool:
	return block_type in block_types


## Advances this unit's cast by one Round. Returns true when the cast completes, which also resets
## it ready for the next one. Downed units never charge.
func advance_cast() -> bool:
	if is_downed():
		return false

	cast_progress += 1
	if cast_progress < cast_rounds:
		return false

	cast_progress = 0
	return true


## Progress toward this unit's next action, 0..1.
func get_cast_ratio() -> float:
	return clampf(float(cast_progress) / float(maxi(cast_rounds, 1)), 0.0, 1.0)


func _to_string() -> String:
	return "%s (%d/%d)" % [display_name, maxi(hp, 0), stats.max_hp]
