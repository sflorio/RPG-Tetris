## The outcome of one resolved attack, ready to be shown to the player.
class_name AttackResult extends RefCounted

## The unit that attacked.
var attacker_name: = ""

## The ability used, e.g. "Shield Bash".
var ability_name: = ""

## Which kind of attack this was (see [enum AttackResolver.Kind]).
var kind: = 0

## Damage actually dealt. Zero when the attack was dodged.
var damage: = 0

## True when the target avoided the attack entirely.
var was_dodged: = false

## True when the attack rolled a Perfect Strike.
var was_perfect_strike: = false

## The type chart's multiplier for this matchup. 1.0 is neutral.
var type_multiplier: = 1.0


## A short line describing the attack, e.g. "Wilhelm - Shield Bash".
func get_label() -> String:
	if was_dodged:
		return "%s - MISS" % attacker_name
	var label: = "%s - %s" % [attacker_name, get_action_name()]
	if was_perfect_strike:
		label += "  PERFECT STRIKE"
	var matchup: = TypeChart.get_callout(type_multiplier)
	if not matchup.is_empty():
		label += "  " + matchup
	return label


## The ability's own name where it has one, otherwise what kind of attack it was.
func get_action_name() -> String:
	return ability_name if not ability_name.is_empty() \
		else AttackResolver.get_kind_name(kind)


func _to_string() -> String:
	return "%s for %d" % [get_label(), damage]
