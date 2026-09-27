## Turns a line clear into character attacks, following the design's Boards note.
##
## Clearing a line with a block assigned to an active character makes [b]that character[/b] attack:
## [br]- 1 line  -> Basic Attack
## [br]- 2 lines -> Special Attack
## [br]- 3 lines -> Special Attack with +50% damage
## [br]- 4 lines -> every active, non-downed ally performs their Rally Strike
## [br][br]Four-line clears are only reachable with the Line block, which is why the Line block is
## never assigned to a character.
##
## [b]Note:[/b] the design specifies which attack happens but not the damage formula, so the
## numbers below are a first pass. Tune [constant POWER_MULTIPLIERS] and [method _compute_damage]
## once the real combat maths is settled.
class_name AttackResolver extends RefCounted

enum Kind {
	BASIC,
	SPECIAL,
	## Special Attack with the +50% bonus from a three-line clear.
	SPECIAL_BOOSTED,
	RALLY_STRIKE,
	UNION_ASSAULT,
}

const KIND_NAMES: = {
	Kind.BASIC: "Basic Attack",
	Kind.SPECIAL: "Special Attack",
	Kind.SPECIAL_BOOSTED: "Special Attack +50%",
	Kind.RALLY_STRIKE: "Rally Strike",
	Kind.UNION_ASSAULT: "Union Assault",
}

## How hard each attack hits, as a multiple of the attacker's Power.
const POWER_MULTIPLIERS: = {
	Kind.BASIC: 1.0,
	Kind.SPECIAL: 1.8,
	Kind.SPECIAL_BOOSTED: 2.7,
	Kind.RALLY_STRIKE: 2.5,
	Kind.UNION_ASSAULT: 4.0,
}


static func get_kind_name(kind: int) -> String:
	return KIND_NAMES.get(kind, "Attack")


## The attack a clear of `lines` produces. Four or more lines is a Rally Strike.
static func kind_for_lines(lines: int) -> Kind:
	if lines >= 4:
		return Kind.RALLY_STRIKE
	elif lines == 3:
		return Kind.SPECIAL_BOOSTED
	elif lines == 2:
		return Kind.SPECIAL
	return Kind.BASIC


## Resolves one attack. `bonus_multiplier` carries extra damage from outside the attack itself,
## such as the Union Assault's +10% per line cleared over the ten-line threshold.
static func resolve(
	attacker: CombatUnit,
	target: CombatUnit,
	kind: Kind,
	bonus_multiplier: float = 1.0
) -> AttackResult:
	var result: = AttackResult.new()
	result.attacker_name = attacker.display_name
	result.kind = kind

	# Dodge is rolled first: a dodged attack deals nothing at all.
	if randf() * 100.0 < target.stats.dodge:
		result.was_dodged = true
		return result

	var damage: = _compute_damage(attacker, target, kind, bonus_multiplier)

	if randf() * 100.0 < attacker.stats.perfect_strike_chance:
		result.was_perfect_strike = true
		damage = roundi(damage * (1.0 + attacker.stats.perfect_strike_power/100.0))

	result.damage = maxi(1, damage)
	return result


# Power scaled by the attack, reduced by the target's Defense or Barrier depending on the
# attacker's Type. Placeholder maths - see the class docs.
static func _compute_damage(
	attacker: CombatUnit,
	target: CombatUnit,
	kind: Kind,
	bonus_multiplier: float
) -> int:
	var multiplier: float = POWER_MULTIPLIERS.get(kind, 1.0)
	var raw: = float(attacker.stats.power) * multiplier * bonus_multiplier
	var mitigation: = target.stats.get_mitigation(attacker.stats.type)
	return maxi(1, roundi(raw) - mitigation)
