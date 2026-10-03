## The stats shared by every unit, ally or enemy, as defined in the design's Unit Stats note.
##
## A unit has one Type, which the attacker's Type is weighed against on the design's chart (see
## [TypeChart]). Offence and defence come in two halves: an ability's Class decides whether it uses
## Offense against Defense, or Tech Offense against Tech Defense.
class_name UnitStats extends Resource

## The five damage types from the design's type chart.
enum Type {
	NONE,
	ARCANE,   ## Anything magical.
	BEAST,    ## Anything with monster origins.
	MARTIAL,  ## Anything standard warfare.
	SPIRIT,   ## Anything otherworldly: ghosts, hexes.
	XENO,     ## Anything with alien origins.
}

## Whether an ability measures itself against Defense or against Tech Defense.
enum DamageClass { PHYSICAL, TECHNICAL }

const TYPE_NAMES: = {
	Type.NONE: "None", Type.ARCANE: "Arcane", Type.BEAST: "Beast",
	Type.MARTIAL: "Martial", Type.SPIRIT: "Spirit", Type.XENO: "Xeno",
}

@export var display_name: = "Unit"

## For allies this mirrors the Party Level.
@export var level: = 1

@export var type: Type = Type.NONE

@export var max_hp: = 100

## Physical strength and resistance.
@export var offense: = 10
@export var defense: = 5

## Non-physical strength and resistance.
@export var tech_offense: = 10
@export var tech_defense: = 5

## Chance for damage or healing to be a Perfect Strike, as a percentage. 1% by default.
@export var perfect_strike_chance: = 1.0

## Efficiency gained when a Perfect Strike happens, as a percentage. 50% by default.
@export var perfect_strike_power: = 50.0

## Chance to avoid a source of damage, as a percentage. 1% by default.
@export var dodge: = 1.0

## Chance to hit, as a percentage. 100% by default.
@export var accuracy: = 100.0

## How likely this unit's Block Type is to come up next. 1 by default; the design makes Speed a
## weighting on block generation rather than a turn order.
@export var speed: = 1


static func get_type_name(unit_type: Type) -> String:
	return TYPE_NAMES.get(unit_type, "None")


## The offence this unit brings to an ability of `damage_class`.
func get_offense(damage_class: DamageClass) -> int:
	return offense if damage_class == DamageClass.PHYSICAL else tech_offense


## The resistance this unit applies against an ability of `damage_class`.
func get_defense(damage_class: DamageClass) -> int:
	return defense if damage_class == DamageClass.PHYSICAL else tech_defense
