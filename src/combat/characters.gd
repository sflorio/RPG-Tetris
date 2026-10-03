## The design's Combat Characters, with the abilities their notes give them.
##
## This is the table from Wilhelm (Soldier), Olister (Archer) and Rena (Cleric). Where the vault
## leaves a row blank it is left blank here too rather than invented — [method get_ability] falls
## back to a generic attack so a half-written character still fights.
##
## Enemies are not in this table. They are generated, and the design's Block Types note says
## non-boss enemies take a random Block Type, so they are built in [TetrisBattleConfig].
class_name Characters extends RefCounted

const SPRITE_DIR: = "res://assets/units/"

## Which ability a clear produces, matching [enum AttackResolver.Kind].
const BASIC: = "basic"
const ADVANCED: = "advanced"
const RALLY: = "rally"

## Traits are the characters' passives. Only the hooks the battle actually calls are listed.
const TRAIT_SHIELDBEARER: = "Shieldbearer"
const TRAIT_VICIOUS_AIM: = "Vicious Aim"

## Wilhelm's Shieldbearer: chance to ignore direct damage and any effects with it.
const SHIELDBEARER_CHANCE: = 0.05

## Olister's Vicious Aim: Perfect Strike Chance gained per line he clears, for the rest of combat.
const VICIOUS_AIM_PER_STACK: = 1.0

const ROSTER: = {
	"Wilhelm": {
		"class_name": "Soldier",
		"sprite": "soldier",
		"type": UnitStats.Type.MARTIAL,
		"trait": TRAIT_SHIELDBEARER,
	},
	"Olister": {
		"class_name": "Archer",
		"sprite": "archer",
		"type": UnitStats.Type.MARTIAL,
		"trait": TRAIT_VICIOUS_AIM,
	},
	"Rena": {
		# The vault has Rena's description and prestige paths but none of her abilities or Trait
		# yet, so she fights on the fallbacks until it does.
		"class_name": "Cleric",
		"sprite": "cleric",
		"type": UnitStats.Type.NONE,
		"trait": "",
	},
}


## The abilities each character performs, by slot. Powers and effects are the vault's.
static func _abilities() -> Dictionary:
	var martial: = UnitStats.Type.MARTIAL
	var physical: = UnitStats.DamageClass.PHYSICAL

	var slice: = Ability.make("Slice", 10, Ability.Targets.RANDOM_ENEMY, martial, physical)
	slice.description = "A basic sword swing, dealing low Martial damage to a single enemy."

	var shield_bash: = Ability.make(
		"Shield Bash", 20, Ability.Targets.RANDOM_ENEMY, martial, physical)
	shield_bash.effects = [StatusEffectDefs.STUN]
	shield_bash.effect_tier = StatusEffect.TIER_WEAK
	shield_bash.description = "Bash an enemy with the shield, dealing medium Martial damage " \
		+ "and inflicting Stun-."

	var formation: = Ability.make("Formation", 15, Ability.Targets.ALL_ENEMIES, martial, physical)
	formation.description = "Wilhelm rallies the team, striking all enemies and empowering allies."

	var quick_shot: = Ability.make(
		"Quick Shot", 10, Ability.Targets.RANDOM_ENEMY, martial, physical)
	quick_shot.description = "A quickly shot arrow, dealing low Martial damage to a single enemy."

	var multishot: = Ability.make("Multishot", 15, Ability.Targets.ALL_ENEMIES, martial, physical)
	multishot.description = "Fire a volley of arrows at all enemies, dealing low Martial damage."

	var marked: = Ability.make(
		"Marked for Death", 15, Ability.Targets.ALL_ENEMIES, martial, physical)
	marked.description = "Olister fires a batch of specialty arrows, applying a random status " \
		+ "effect from Blind, Poison or Bleed."

	return {
		"Wilhelm": {BASIC: slice, ADVANCED: shield_bash, RALLY: formation},
		"Olister": {BASIC: quick_shot, ADVANCED: multishot, RALLY: marked},
		"Rena": {},
	}


## Rally Strikes that help the team as well as hurting the enemy. Wilhelm's Formation gives every
## ally Shield; Olister's Marked for Death inflicts one of three ailments instead.
const RALLY_ALLY_EFFECTS: = {
	"Wilhelm": [StatusEffectDefs.SHIELD],
}
const RALLY_ENEMY_AILMENTS: = {
	"Olister": [StatusEffectDefs.BLIND, StatusEffectDefs.POISON, StatusEffectDefs.BLEED],
}

# Built once; abilities are read-only in combat.
static var _ability_cache: Dictionary = {}

# Generic stand-ins for a character the vault has not written up, and for generated enemies.
static var _fallbacks: Dictionary = {}


static func exists(character_name: String) -> bool:
	return ROSTER.has(character_name)


static func get_class_name_for(character_name: String) -> String:
	return ROSTER.get(character_name, {}).get("class_name", "")


static func get_type(character_name: String) -> UnitStats.Type:
	return ROSTER.get(character_name, {}).get("type", UnitStats.Type.NONE)


static func get_trait(character_name: String) -> String:
	return ROSTER.get(character_name, {}).get("trait", "")


static func get_sprite(character_name: String) -> Texture2D:
	var entry: Dictionary = ROSTER.get(character_name, {})
	if entry.is_empty():
		return null
	var path: = "%s%s.png" % [SPRITE_DIR, entry["sprite"]]
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## The ability a character performs for `slot`, or a generic stand-in when the vault has not
## written one. Never returns null, so a battle can always resolve a clear.
static func get_ability(character_name: String, slot: String) -> Ability:
	if _ability_cache.is_empty():
		_ability_cache = _abilities()

	var ability: Ability = _ability_cache.get(character_name, {}).get(slot)
	if ability != null:
		return ability
	return get_fallback_ability(slot)


## The generic Basic, Advanced and Rally used by enemies and by unwritten characters. Powers match
## the written characters so the numbers stay comparable.
static func get_fallback_ability(slot: String) -> Ability:
	if _fallbacks.is_empty():
		_fallbacks = {
			BASIC: Ability.make("Attack", 10),
			ADVANCED: Ability.make("Advanced Attack", 18),
			RALLY: Ability.make("Rally Strike", 15, Ability.Targets.ALL_ENEMIES),
		}
	return _fallbacks.get(slot, _fallbacks[BASIC])
