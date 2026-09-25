## The result of turning one line clear into damage.
##
## Produced by [method TetrisDamageRules.resolve_clear] and consumed by [TetrisBattle], which shows
## the numbers on screen and applies them to the current enemy.
class_name TetrisDamageBreakdown extends RefCounted

## Damage before bonuses: one point per line cleared.
var base_damage: int = 0

## Damage actually dealt to the enemy, after every bonus.
var total_damage: int = 0

## Names of the bonuses that fired, e.g. ["TETRIS x3", "SQUARE STREAK x2"]. Shown to the player.
var bonus_labels: PackedStringArray = PackedStringArray()


## True when at least one bonus rule fired.
func has_bonus() -> bool:
	return not bonus_labels.is_empty()


func _to_string() -> String:
	return "%d damage (base %d)%s" % [
		total_damage,
		base_damage,
		"" if bonus_labels.is_empty() else " [%s]" % ", ".join(bonus_labels)
	]
