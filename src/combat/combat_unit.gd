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

## Active status effects, keyed by effect id.
var effects: Dictionary = {}


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
##
## Shield halves the damage and is consumed a stack at a time, per the design.
func take_damage(amount: int) -> int:
	var incoming: = amount
	var shield: StatusEffect = effects.get(StatusEffectDefs.SHIELD)
	if shield != null:
		incoming = maxi(1, incoming / 2)
		shield.stacks -= 1
		if shield.is_expired():
			effects.erase(StatusEffectDefs.SHIELD)

	var dealt: = clampi(incoming, 0, hp)
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


# --- Status effects ----------------------------------------------------------------------------

## Applies a status effect at `tier`. Re-applying refreshes it rather than stacking a second copy,
## except for stack-based effects like Shield which accumulate.
##
## Honours the design's Compound Effects: Renew cancels with Bleed and with Poison, clearing both
## rather than either taking hold. Returns the applied effect, or null when it cancelled instead.
func apply_effect(id: String, tier: int = StatusEffect.TIER_NORMAL) -> StatusEffect:
	if not StatusEffectDefs.exists(id):
		return null

	# Compound effects: applying one half of a cancelling pair removes the other and itself.
	for other_id in StatusEffectDefs.CANCELS.get(id, []):
		if effects.has(other_id):
			effects.erase(other_id)
			effects.erase(id)
			return null

	var effect: = StatusEffectDefs.build(id, tier)
	if StatusEffectDefs.uses_stacks(id) and effects.has(id):
		effect.stacks += effects[id].stacks

	effects[id] = effect
	return effect


func has_effect(id: String) -> bool:
	return effects.has(id)


func get_effect(id: String) -> StatusEffect:
	return effects.get(id)


func remove_effect(id: String) -> void:
	effects.erase(id)


## Ticks every effect by one Round: applies per-Round damage and healing, counts durations down and
## drops anything that has expired. Returns lines describing what happened, for the combat log.
func tick_effects() -> PackedStringArray:
	var log: = PackedStringArray()
	if is_downed():
		effects.clear()
		return log

	var poison: StatusEffect = effects.get(StatusEffectDefs.POISON)
	if poison != null:
		var percent: = StatusEffectDefs.get_percent(StatusEffectDefs.POISON, poison.tier)
		var damage: = maxi(1, roundi(stats.max_hp * percent/100.0))
		take_damage(damage)
		log.append("%s takes %d from %s" % [display_name, damage, poison.get_display_name()])

	var renew: StatusEffect = effects.get(StatusEffectDefs.RENEW)
	if renew != null and not is_downed():
		var percent: = StatusEffectDefs.get_percent(StatusEffectDefs.RENEW, renew.tier)
		var healed: = heal(maxi(1, roundi(stats.max_hp * percent/100.0)))
		if healed > 0:
			log.append("%s heals %d from %s" % [display_name, healed, renew.get_display_name()])

	for effect: StatusEffect in effects.values().duplicate():
		effect.advance_round()
		if effect.is_expired():
			effects.erase(effect.id)
			log.append("%s: %s wore off" % [display_name, effect.get_display_name()])

	return log


## Spends one use of a generation-based effect such as Haste, removing it when exhausted.
func consume_generation(id: String) -> void:
	var effect: StatusEffect = effects.get(id)
	if effect == null:
		return
	effect.rounds_remaining -= 1
	if effect.rounds_remaining <= 0:
		effects.erase(id)


## Applies Bleed's damage, which triggers on block rotation rather than per Round. Returns the
## damage dealt, or 0 when the unit isn't bleeding.
func apply_bleed_on_rotate() -> int:
	var bleed: StatusEffect = effects.get(StatusEffectDefs.BLEED)
	if bleed == null or is_downed():
		return 0

	var percent: = StatusEffectDefs.get_percent(StatusEffectDefs.BLEED, bleed.tier)
	return take_damage(maxi(1, roundi(hp * percent/100.0)))


## Short summary of active effects for the roster, e.g. "Poison+, Shield x2".
func get_effect_summary() -> String:
	if effects.is_empty():
		return ""
	var parts: Array[String] = []
	for effect: StatusEffect in effects.values():
		parts.append(str(effect))
	return ", ".join(parts)


func _to_string() -> String:
	return "%s (%d/%d)" % [display_name, maxi(hp, 0), stats.max_hp]
