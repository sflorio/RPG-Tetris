## The stats shared by every unit, ally or enemy, as defined in the design's Unit Stats note.
class_name UnitStats extends Resource

## Damage types. The first three are physical and mitigated by Defense; the rest are non-physical
## and mitigated by Barrier.
enum Type {
	NONE,
	SLASH, PIERCE, CRUSH,
	ELEMENTAL, NATURE, XENO, VOID, DIVINE,
}

## Types mitigated by Defense rather than Barrier.
const PHYSICAL_TYPES: Array[Type] = [Type.SLASH, Type.PIERCE, Type.CRUSH]

@export var display_name: = "Unit"

## For allies this mirrors the Party Level.
@export var level: = 1

## Every unit must have at least one Type. Type 2 is optional and weighed equally.
@export var type: Type = Type.NONE
@export var type_2: Type = Type.NONE

@export var max_hp: = 100
@export var power: = 10
@export var defense: = 5
@export var barrier: = 5

## Chance for damage or healing to be a Perfect Strike, as a percentage. 1% by default.
@export var perfect_strike_chance: = 1.0

## Efficiency gained when a Perfect Strike happens, as a percentage. 50% by default.
@export var perfect_strike_power: = 50.0

## Chance to avoid a source of damage, as a percentage. 1% by default.
@export var dodge: = 1.0


## True when this unit's primary type is mitigated by Defense rather than Barrier.
func is_physical() -> bool:
	return type in PHYSICAL_TYPES


## The mitigation this unit applies against an incoming attack of `attack_type`.
func get_mitigation(attack_type: Type) -> int:
	return defense if attack_type in PHYSICAL_TYPES else barrier
