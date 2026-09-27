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


func _to_string() -> String:
	return "%s (%d/%d)" % [display_name, maxi(hp, 0), stats.max_hp]
