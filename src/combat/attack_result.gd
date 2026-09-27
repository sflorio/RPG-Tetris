## The outcome of one resolved attack, ready to be shown to the player.
class_name AttackResult extends RefCounted

## The unit that attacked.
var attacker_name: = ""

## Which kind of attack this was (see [enum AttackResolver.Kind]).
var kind: = 0

## Damage actually dealt. Zero when the attack was dodged.
var damage: = 0

## True when the target avoided the attack entirely.
var was_dodged: = false

## True when the attack rolled a Perfect Strike.
var was_perfect_strike: = false


## A short line describing the attack, e.g. "Soldier - Special Attack".
func get_label() -> String:
	if was_dodged:
		return "%s - MISS" % attacker_name
	var label: = "%s - %s" % [attacker_name, AttackResolver.get_kind_name(kind)]
	if was_perfect_strike:
		label += "  PERFECT STRIKE"
	return label


func _to_string() -> String:
	return "%s for %d" % [get_label(), damage]
