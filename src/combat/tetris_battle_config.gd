## Everything a Tetris battle needs: who is fighting on each side, and how the board starts.
##
## Built from the [CombatArena] that triggered the encounter. The arena's Battlers become
## [CombatUnit]s: player Battlers form the active team, enemy Battlers the opposing team.
##
## Block types are handed out across the active team, so clearing a line with a given block makes
## the character holding it attack. The Line block is never assigned — the design reserves it for
## Rally Strikes.
class_name TetrisBattleConfig extends RefCounted

## Junk blocks seeded on the board per point of total enemy attack, so combat never starts empty.
const ATTACK_PER_JUNK_ROW: = 5

## The player's active team.
var allies: Array[CombatUnit] = []

## The units to defeat.
var enemies: Array[CombatUnit] = []

## Party-wide stats, including Gravity and the unlocked Psionic Powers.
var party: PartyStats = PartyStats.new()

## Junk rows stacked on the board when combat begins.
var junk_rows: = 0

## Human-readable summary of the opposing side, e.g. "Bugcat x2, Wolf".
var enemy_description: = "a mysterious foe"


## Builds a config from the arena a [signal FieldEvents.combat_triggered] carried. A null or
## non-arena scene still yields a usable battle, so combat can be triggered without one.
static func from_arena(arena: PackedScene, party_stats: PartyStats = null) -> TetrisBattleConfig:
	var config: = TetrisBattleConfig.new()
	if party_stats != null:
		config.party = party_stats

	var combat_arena: CombatArena = null
	var instance: Node = null
	if arena != null:
		instance = arena.instantiate()
		combat_arena = instance as CombatArena

	if combat_arena == null:
		if instance != null:
			instance.free()
		config._add_fallback_units()
		return config

	var roster: = combat_arena.get_battler_roster()
	var total_attack: = 0
	var enemy_counts: = {}  # Insertion-ordered: enemy name -> how many.

	for battler in roster.get_enemy_battlers():
		if battler.stats == null:
			continue
		total_attack += battler.stats.base_attack

		var enemy_name: = _get_unit_name(battler)
		enemy_counts[enemy_name] = enemy_counts.get(enemy_name, 0) + 1

		var enemy: = CombatUnit.new(_build_stats(battler, enemy_name), false)
		enemy.icon = _load_unit_icon(battler)
		# Faster enemies act more often. The design gives enemies cast bars but no cast-time stat,
		# so this is derived from speed and is a placeholder.
		enemy.cast_rounds = clampi(roundi(120.0 / maxf(battler.stats.base_speed, 1.0)), 2, 8)
		config.enemies.append(enemy)

	for battler in roster.get_player_battlers():
		if battler.stats == null:
			continue
		var ally_name: = _get_unit_name(battler)
		var ally: = CombatUnit.new(_build_stats(battler, ally_name), true)
		ally.icon = _load_unit_icon(battler)
		config.allies.append(ally)

	config._assign_block_types()

	if not enemy_counts.is_empty():
		config.junk_rows = total_attack / ATTACK_PER_JUNK_ROW
		config.enemy_description = _describe(enemy_counts)

	if combat_arena.tetris_junk_rows >= 0:
		config.junk_rows = combat_arena.tetris_junk_rows

	instance.free()
	if config.enemies.is_empty() or config.allies.is_empty():
		config._add_fallback_units()
	return config


## The ally whose block types include `block_type`, or null when no one is assigned it.
func find_ally_for_block(block_type: int) -> CombatUnit:
	for ally in allies:
		if ally.handles_block(block_type) and not ally.is_downed():
			return ally
	return null


## Allies still standing, who take part in Rally Strikes and the Union Assault.
func get_active_allies() -> Array[CombatUnit]:
	return allies.filter(func(ally: CombatUnit) -> bool: return not ally.is_downed())


## Combined health of every enemy, i.e. the damage needed to win.
func get_total_enemy_hp() -> int:
	var total: = 0
	for enemy in enemies:
		total += enemy.stats.max_hp
	return total


# Deals the assignable blocks out across the active team, so every block that can be assigned has
# an owner as long as there is at least one ally.
func _assign_block_types() -> void:
	if allies.is_empty():
		return
	for i in BlockTypes.ASSIGNABLE.size():
		allies[i % allies.size()].block_types.append(BlockTypes.ASSIGNABLE[i])


# OpenRPG's BattlerStats predate the design's stat list, so map what exists and use the design's
# defaults for the rest.
static func _build_stats(battler: Battler, unit_name: String) -> UnitStats:
	var stats: = UnitStats.new()
	stats.display_name = unit_name
	stats.max_hp = battler.stats.base_max_health
	stats.power = battler.stats.base_attack
	stats.defense = battler.stats.base_defense
	stats.barrier = battler.stats.base_defense
	stats.dodge = maxf(1.0, float(battler.stats.base_evasion))
	return stats


# A battle needs someone on each side, so stand in placeholders rather than deadlock.
func _add_fallback_units() -> void:
	if allies.is_empty():
		var hero_stats: = UnitStats.new()
		hero_stats.display_name = "Psion"
		allies.append(CombatUnit.new(hero_stats, true))
		_assign_block_types()
	if enemies.is_empty():
		var dummy_stats: = UnitStats.new()
		dummy_stats.display_name = "Training Dummy"
		dummy_stats.max_hp = 40
		enemies.append(CombatUnit.new(dummy_stats, false))


# Battler art and stats follow the same convention, so
# "res://combat/battlers/bugcat/bugcat_stats.tres" implies ".../bugcat.png".
static func _load_unit_icon(battler: Battler) -> Texture2D:
	var stats_path: = battler.stats.resource_path
	if stats_path.is_empty():
		return null

	var slug: = stats_path.get_file().get_basename().trim_suffix("_stats")
	var icon_path: = "%s/%s.png" % [stats_path.get_base_dir(), slug]
	if not ResourceLoader.exists(icon_path):
		return null
	return load(icon_path) as Texture2D


# Battler nodes are named generically ("Battler2"), so name units after their stats resource.
static func _get_unit_name(battler: Battler) -> String:
	var file_name: = battler.stats.resource_path.get_file().get_basename()
	if file_name.is_empty():
		return battler.name
	return file_name.trim_suffix("_stats").capitalize()


static func _describe(enemy_counts: Dictionary) -> String:
	var parts: Array[String] = []
	for enemy_name: String in enemy_counts:
		var count: int = enemy_counts[enemy_name]
		parts.append(enemy_name if count == 1 else "%s x%d" % [enemy_name, count])
	return ", ".join(parts)
