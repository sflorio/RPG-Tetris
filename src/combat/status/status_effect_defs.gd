## The status effect table from the design's Status Effects note.
##
## Every effect in the design is listed here, including the ones not wired up yet, so the table is
## the single record of what the game is supposed to have. [method is_implemented] says which ones
## currently do anything.
##
## The five per-block effects (Golden, Charged, Burning, Frozen, Thorned) all need the board to
## track a state per cell rather than just a colour, which is a change to the board itself — see
## DESIGN_ALIGNMENT.md.
class_name StatusEffectDefs extends RefCounted

# --- Unit effects ---
const SHIELD: = "Shield"
const HASTE: = "Haste"
const RENEW: = "Renew"
const BLIND: = "Blind"
const POISON: = "Poison"
const BLEED: = "Bleed"
const INFECTION: = "Infection"

# --- Board effects ---
const SHOCKED: = "Shocked"
const CONFUSION: = "Confusion"
const GOLDEN: = "Golden"
const CHARGED: = "Charged"
const BURNING: = "Burning"
const FROZEN: = "Frozen"
const THORNED: = "Thorned"

## Keyed by tier: -1 weak, 0 normal, +1 strong.
const DEFS: = {
	SHIELD: {
		"positive": true, "implemented": true, "stacks": {-1: 1, 0: 1, 1: 2},
		"note": "Halves incoming damage and consumes a stack.",
	},
	HASTE: {
		"positive": true, "implemented": true, "rounds": {-1: 1, 0: 1, 1: 3},
		"note": "This unit's block is guaranteed to come next. Counted in block generations.",
	},
	RENEW: {
		"positive": true, "implemented": true, "rounds": {-1: 3, 0: 5, 1: 10},
		"percent": {-1: 2.0, 0: 2.0, 1: 2.0},
		"note": "Heals 2% of max HP per Round.",
	},
	BLIND: {
		"positive": false, "implemented": true, "rounds": {-1: 1, 0: 2, 1: 3},
		"note": "Hides a third of the board behind fog.",
	},
	POISON: {
		"positive": false, "implemented": true, "rounds": {-1: 5, 0: 5, 1: 5},
		"percent": {-1: 1.0, 0: 2.0, 1: 3.0},
		"note": "Loses a percentage of max HP per Round.",
	},
	BLEED: {
		"positive": false, "implemented": true, "rounds": {-1: 5, 0: 5, 1: 5},
		"percent": {-1: 1.0, 0: 3.0, 1: 5.0},
		"note": "Loses a percentage of current HP each time a block is rotated.",
	},
	INFECTION: {
		"positive": false, "implemented": true, "rounds": {-1: 3, 0: 5, 1: 7},
		"note": "30% chance per infected unit to generate a Xenoblock on that team's board.",
	},
	SHOCKED: {
		"positive": false, "implemented": true, "rounds": {-1: 1, 0: 3, 1: 5},
		"note": "The team cannot rotate their active block.",
	},
	CONFUSION: {
		"positive": false, "implemented": true, "rounds": {-1: 1, 0: 3, 1: 5},
		"note": "Obscures the block preview.",
	},
	GOLDEN: {
		"positive": true, "implemented": false, "rounds": {-1: 5, 0: 5, 1: 5},
		"percent": {-1: 10.0, 0: 15.0, 1: 20.0},
		"note": "Clearing gold blocks heals. Needs per-block state.",
	},
	CHARGED: {
		"positive": true, "implemented": false, "rounds": {-1: 5, 0: 5, 1: 5},
		"note": "Clearing charged blocks restores TP. Needs per-block state.",
	},
	BURNING: {
		"positive": false, "implemented": false, "rounds": {-1: 7, 0: 5, 1: 3},
		"note": "Blocks burn away, leaving holes. Needs per-block state.",
	},
	FROZEN: {
		"positive": false, "implemented": false, "rounds": {-1: 5, 0: 5, 1: 5},
		"note": "Blocks must be cleared twice. Needs per-block state.",
	},
	THORNED: {
		"positive": false, "implemented": false, "rounds": {-1: 5, 0: 5, 1: 5},
		"note": "Clearing thorned blocks damages the clearing character. Needs per-block state.",
	},
}

## Pairs that cancel each other out, from the design's Compound Effects table. Applying either one
## while the other is active clears both.
const CANCELS: = {
	RENEW: [BLEED, POISON],
	BLEED: [RENEW],
	POISON: [RENEW],
}

## What the player is told when an effect lands, e.g. "BLINDED!".
const CALLOUTS: = {
	SHIELD: "SHIELDED!", HASTE: "HASTED!", RENEW: "RENEWED!",
	BLIND: "BLINDED!", POISON: "POISONED!", BLEED: "BLEEDING!", INFECTION: "INFECTED!",
	SHOCKED: "SHOCKED!", CONFUSION: "CONFUSED!",
	GOLDEN: "GOLDEN!", CHARGED: "CHARGED!",
	BURNING: "BURNING!", FROZEN: "FROZEN!", THORNED: "THORNED!",
}


static func get_callout(id: String) -> String:
	return CALLOUTS.get(id, id.to_upper() + "!")


## Effects that are consumed rather than timed.
const STACK_BASED: Array[String] = [SHIELD]

## Effects measured in block generations rather than Rounds. The design gives Haste a duration in
## "Block generations", so it is spent when it forces a block, not by the Round tick.
const GENERATION_BASED: Array[String] = [HASTE]

## Chance, per infected unit per Round, that Infection pushes a Xenoblock onto that team's board.
const XENOBLOCK_CHANCE: = 0.30

## Negative effects an enemy can inflict today. Used to pick one at random when an attack lands.
const ENEMY_INFLICTABLE: Array[String] = [POISON, BLEED, BLIND, SHOCKED, CONFUSION, INFECTION]

## Effects that act on the whole board rather than on one unit's body.
const BOARD_SCOPED: Array[String] = [BLIND, SHOCKED, CONFUSION]


static func exists(id: String) -> bool:
	return DEFS.has(id)


static func is_implemented(id: String) -> bool:
	return DEFS.get(id, {}).get("implemented", false)


static func is_positive(id: String) -> bool:
	return DEFS.get(id, {}).get("positive", false)


static func uses_stacks(id: String) -> bool:
	return id in STACK_BASED


static func uses_generations(id: String) -> bool:
	return id in GENERATION_BASED


static func affects_board(id: String) -> bool:
	return id in BOARD_SCOPED


## Rounds this effect lasts at `tier`.
static func get_rounds(id: String, tier: int) -> int:
	var table: Dictionary = DEFS.get(id, {}).get("rounds", {})
	return table.get(tier, 0)


## Stacks this effect applies at `tier`.
static func get_stacks(id: String, tier: int) -> int:
	var table: Dictionary = DEFS.get(id, {}).get("stacks", {})
	return table.get(tier, 0)


## The magnitude of this effect at `tier`, as a percentage.
static func get_percent(id: String, tier: int) -> float:
	var table: Dictionary = DEFS.get(id, {}).get("percent", {})
	return table.get(tier, 0.0)


## Builds a ready-to-apply effect at the given tier.
static func build(id: String, tier: int = StatusEffect.TIER_NORMAL) -> StatusEffect:
	return StatusEffect.new(id, tier, get_rounds(id, tier), get_stacks(id, tier))
