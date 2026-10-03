## The design's type chart: how much damage one Type does to another.
##
## Rows are the attacking Type, columns the defending Type, exactly as the Damage Calculation note
## tabulates them. A Type of NONE on either side is neutral, which is what unmapped placeholder
## units get.
class_name TypeChart extends RefCounted

const STRONG: = 2.0
const EFFECTIVE: = 1.5
const NEUTRAL: = 1.0
const WEAK: = 0.5
const ZERO: = 0.0

const CHART: = {
	UnitStats.Type.ARCANE: {
		UnitStats.Type.ARCANE: NEUTRAL, UnitStats.Type.BEAST: NEUTRAL,
		UnitStats.Type.MARTIAL: EFFECTIVE, UnitStats.Type.SPIRIT: STRONG,
		UnitStats.Type.XENO: WEAK,
	},
	UnitStats.Type.BEAST: {
		UnitStats.Type.ARCANE: EFFECTIVE, UnitStats.Type.BEAST: NEUTRAL,
		UnitStats.Type.MARTIAL: NEUTRAL, UnitStats.Type.SPIRIT: WEAK,
		UnitStats.Type.XENO: STRONG,
	},
	UnitStats.Type.MARTIAL: {
		UnitStats.Type.ARCANE: NEUTRAL, UnitStats.Type.BEAST: EFFECTIVE,
		UnitStats.Type.MARTIAL: NEUTRAL, UnitStats.Type.SPIRIT: ZERO,
		UnitStats.Type.XENO: WEAK,
	},
	UnitStats.Type.SPIRIT: {
		UnitStats.Type.ARCANE: NEUTRAL, UnitStats.Type.BEAST: NEUTRAL,
		UnitStats.Type.MARTIAL: WEAK, UnitStats.Type.SPIRIT: EFFECTIVE,
		UnitStats.Type.XENO: STRONG,
	},
	UnitStats.Type.XENO: {
		UnitStats.Type.ARCANE: STRONG, UnitStats.Type.BEAST: NEUTRAL,
		UnitStats.Type.MARTIAL: STRONG, UnitStats.Type.SPIRIT: WEAK,
		UnitStats.Type.XENO: NEUTRAL,
	},
}

## What the player is told about a matchup, for the combat popups.
const CALLOUTS: = {
	STRONG: "DEVASTATING!",
	EFFECTIVE: "EFFECTIVE!",
	WEAK: "RESISTED",
	ZERO: "IMMUNE",
}


## The multiplier for `attack_type` striking `defend_type`.
static func multiplier(attack_type: UnitStats.Type, defend_type: UnitStats.Type) -> float:
	return CHART.get(attack_type, {}).get(defend_type, NEUTRAL)


## The word for a multiplier, or "" when the matchup is neutral and not worth saying.
static func get_callout(value: float) -> String:
	return CALLOUTS.get(value, "")
