## One active status effect on a unit or a board.
##
## Effects come in three tiers, written in the design as a suffix: `Poison-` is weaker than
## `Poison`, which is weaker than `Poison+`. The tier changes duration, magnitude or stack count
## depending on the effect — see [StatusEffectDefs].
class_name StatusEffect extends RefCounted

const TIER_WEAK: = -1
const TIER_NORMAL: = 0
const TIER_STRONG: = 1

## Which effect this is, e.g. [constant StatusEffectDefs.POISON].
var id: = ""

## One of the TIER_* constants.
var tier: = TIER_NORMAL

## Rounds left before the effect falls off. Unused by effects that count stacks instead.
var rounds_remaining: = 0

## Stacks left, for effects like Shield that are consumed rather than timed.
var stacks: = 0


func _init(effect_id: String, effect_tier: int, rounds: int = 0, stack_count: int = 0) -> void:
	id = effect_id
	tier = effect_tier
	rounds_remaining = rounds
	stacks = stack_count


## The effect's name with its tier suffix, e.g. "Poison+".
func get_display_name() -> String:
	match tier:
		TIER_WEAK: return "%s-" % id
		TIER_STRONG: return "%s+" % id
		_: return id


## True once the effect has run out and should be removed.
func is_expired() -> bool:
	if StatusEffectDefs.uses_stacks(id):
		return stacks <= 0
	return rounds_remaining <= 0


## Counts down one Round. Effects measured in stacks or in block generations are untouched — those
## are spent when they are used, not by the passage of Rounds.
func advance_round() -> void:
	if StatusEffectDefs.uses_stacks(id) or StatusEffectDefs.uses_generations(id):
		return
	rounds_remaining -= 1


func _to_string() -> String:
	if StatusEffectDefs.uses_stacks(id):
		return "%s x%d" % [get_display_name(), stacks]
	return "%s (%d)" % [get_display_name(), rounds_remaining]
