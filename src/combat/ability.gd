## One attack, Technique or Rally Strike, with the columns the design's Ability Properties note
## gives every ability.
##
## Power is the ability's own number rather than a multiple of the attacker's stats: the damage
## formula in [AttackResolver] takes Power and Offense as separate terms, so a Basic Attack of
## Power 10 means the same thing on every character.
class_name Ability extends Resource

## Who an ability hits. The design writes these as 1E, AllE, Ran1E and so on.
enum Targets {
	NONE,
	ONE_ENEMY,
	RANDOM_ENEMY,
	ALL_ENEMIES,
	ONE_ALLY,
	ALL_ALLIES,
	ALL_UNITS,
}

@export var display_name: = "Attack"

## The Type weighed on the [TypeChart] against the target's Type.
@export var type: UnitStats.Type = UnitStats.Type.MARTIAL

## Whether this measures Offense against Defense, or Tech Offense against Tech Defense.
@export var damage_class: UnitStats.DamageClass = UnitStats.DamageClass.PHYSICAL

## Levelled with Mastery Points. Not yet used by the damage formula.
@export var level: = 1

## Raw damage of the ability, before stats, Perfect Strike, variance and type.
@export var power: = 10

@export var targets: Targets = Targets.RANDOM_ENEMY

## Tech Points to use it. Only Techniques cost anything.
@export var cost: = 0

## Status effects the ability applies, as ids from [StatusEffectDefs].
@export var effects: Array[String] = []

## Tier the effects land at, from [StatusEffect]. Shield Bash applies Stun- rather than Stun.
@export var effect_tier: = 0

@export_multiline var description: = ""


static func make(
	name: String,
	power: int,
	targets: Targets = Targets.RANDOM_ENEMY,
	type: UnitStats.Type = UnitStats.Type.MARTIAL,
	damage_class: UnitStats.DamageClass = UnitStats.DamageClass.PHYSICAL
) -> Ability:
	var ability: = Ability.new()
	ability.display_name = name
	ability.power = power
	ability.targets = targets
	ability.type = type
	ability.damage_class = damage_class
	return ability


## True when the ability hits every enemy rather than one of them.
func hits_all_enemies() -> bool:
	return targets == Targets.ALL_ENEMIES
