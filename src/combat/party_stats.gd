## Party-wide stats, as defined in the design's Unit Stats note.
##
## Also holds the unlocked Psionic Powers, because several of them change what combat is allowed to
## show the player (enemy health bars, enemy next blocks, and so on).
class_name PartyStats extends Resource

## Psionic Power identifiers. Each one is an unlock, not a default.
const HP_SIGHT: = "HP Sight"
const TP_SIGHT: = "TP Sight"
const FUTURE_SIGHT: = "Future Sight"
const PEEK: = "Peek"
const PSYCHOMETRY: = "Psychometry"
const MINDREAD: = "Mindread"
const TRUE_SIGHT: = "True Sight"
const THIRD_EYE: = "Third Eye"

@export var level: = 1
@export var experience: = 0

## Contributed by the allies in the active team.
@export var tech_points: = 0
@export var luck: = 0

## Currency.
@export var crowns: = 0

@export var battle_count: = 0

## How quickly blocks fall. Raised by Stars and by enemy attacks; this is the party's stat, not
## something derived from the enemies present.
@export var gravity: = 1

## How quickly the player moves around the Field Map.
@export var move_speed: = 96.0

## How often a random encounter spawns on the Field Map.
@export var encounter_rate: = 1.0

## Psionic Powers the player has unlocked so far. Empty at the start of the game, which is why
## enemy health bars are hidden until HP Sight is found.
@export var psionic_powers: Array[String] = []


func has_power(power_name: String) -> bool:
	return power_name in psionic_powers


func unlock_power(power_name: String) -> void:
	if not has_power(power_name):
		psionic_powers.append(power_name)
