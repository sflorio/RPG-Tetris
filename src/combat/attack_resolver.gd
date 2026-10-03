## Turns a line clear into character attacks, following the design's Boards and Party notes.
##
## Clearing a line with a block assigned to an active character makes [b]that character[/b] attack:
## [br]- 1 line  -> Basic Attack
## [br]- 2 lines -> Advanced Attack
## [br]- 3 lines -> Advanced Attack with +50% damage
## [br]- 4 lines -> every active, non-downed ally performs their Rally Strike
## [br]- 10 lines -> the Party's Union Assault
## [br][br]Four-line clears are only reachable with the Tower block, which is why Tower is never
## assigned to a character.
##
## The damage itself follows the Damage Calculation note exactly:
## [br][code]Base x PerfectStrike x Randomizer x Type x Other[/code], flooring after every step.
class_name AttackResolver extends RefCounted

enum Kind {
	BASIC,
	ADVANCED,
	## Advanced Attack with the +50% bonus from a three-line clear.
	ADVANCED_BOOSTED,
	RALLY_STRIKE,
	UNION_ASSAULT,
}

const KIND_NAMES: = {
	Kind.BASIC: "Basic Attack",
	Kind.ADVANCED: "Advanced Attack",
	Kind.ADVANCED_BOOSTED: "Advanced Attack +50%",
	Kind.RALLY_STRIKE: "Rally Strike",
	Kind.UNION_ASSAULT: "Union Assault",
}

## Which of a character's abilities each attack uses.
const KIND_SLOTS: = {
	Kind.BASIC: Characters.BASIC,
	Kind.ADVANCED: Characters.ADVANCED,
	Kind.ADVANCED_BOOSTED: Characters.ADVANCED,
	Kind.RALLY_STRIKE: Characters.RALLY,
	Kind.UNION_ASSAULT: Characters.RALLY,
}

## The three-line clear's bonus to the Advanced Attack.
const THREE_LINE_BONUS: = 1.5

## The Union Assault has no ability of its own in the vault yet, so it fires the Rally Strike at
## this multiple. Flagged rather than silently folded into the numbers.
const UNION_ASSAULT_BONUS: = 2.0

## The damage variance the design applies, as percentages of the rolled value.
const RANDOMIZER_MIN: = 85
const RANDOMIZER_MAX: = 100


static func get_kind_name(kind: int) -> String:
	return KIND_NAMES.get(kind, "Attack")


## The attack a clear of `lines` produces. Four or more lines is a Rally Strike.
static func kind_for_lines(lines: int) -> Kind:
	if lines >= 4:
		return Kind.RALLY_STRIKE
	elif lines == 3:
		return Kind.ADVANCED_BOOSTED
	elif lines == 2:
		return Kind.ADVANCED
	return Kind.BASIC


## The ability `attacker` uses for this kind of attack.
static func ability_for(attacker: CombatUnit, kind: Kind) -> Ability:
	return Characters.get_ability(attacker.display_name, KIND_SLOTS.get(kind, Characters.BASIC))


## Resolves one attack. `bonus_multiplier` carries extra damage from outside the attack itself,
## such as the Union Assault's +10% per line cleared over the ten-line threshold.
static func resolve(
	attacker: CombatUnit,
	target: CombatUnit,
	kind: Kind,
	party_level: int = 1,
	bonus_multiplier: float = 1.0
) -> AttackResult:
	var ability: = ability_for(attacker, kind)

	var result: = AttackResult.new()
	result.attacker_name = attacker.display_name
	result.ability_name = ability.display_name
	result.kind = kind

	# Accuracy, then Dodge: a miss and a dodge both deal nothing at all.
	if randf() * 100.0 >= attacker.stats.accuracy:
		result.was_dodged = true
		return result
	if randf() * 100.0 < target.stats.dodge:
		result.was_dodged = true
		return result

	match kind:
		Kind.ADVANCED_BOOSTED:
			bonus_multiplier *= THREE_LINE_BONUS
		Kind.UNION_ASSAULT:
			bonus_multiplier *= UNION_ASSAULT_BONUS

	result.was_perfect_strike = randf() * 100.0 < attacker.get_perfect_strike_chance()
	result.type_multiplier = TypeChart.multiplier(ability.type, target.stats.type)
	result.damage = compute_damage(
		attacker, target, ability, party_level,
		result.was_perfect_strike, result.type_multiplier, bonus_multiplier)
	return result


## The design's damage equation. Every step floors, and Base has a floor of 1 built into it, so a
## neutral hit always lands for at least 1 -- but a type multiplier of 0 still deals nothing.
static func compute_damage(
	attacker: CombatUnit,
	target: CombatUnit,
	ability: Ability,
	party_level: int,
	perfect_strike: bool,
	type_multiplier: float,
	other_multiplier: float = 1.0
) -> int:
	var offense: = float(attacker.stats.get_offense(ability.damage_class))
	var defense: = float(maxi(target.stats.get_defense(ability.damage_class), 1))

	# Base = (((2 x Level / 5) + 2) x Power x (Offense / Defense)) / 50 + 1
	var base: = (2.0*party_level/5.0 + 2.0) * float(ability.power) * (offense/defense)
	var damage: = floori(base/50.0 + 1.0)

	if perfect_strike:
		damage = floori(damage * (1.0 + attacker.stats.perfect_strike_power/100.0))

	damage = floori(damage * randi_range(RANDOMIZER_MIN, RANDOMIZER_MAX) / 100.0)
	damage = floori(damage * type_multiplier)
	damage = floori(damage * other_multiplier)

	# A hit that connects deals something, unless the target is outright immune to the type.
	if is_zero_approx(type_multiplier):
		return 0
	return maxi(damage, 1)
