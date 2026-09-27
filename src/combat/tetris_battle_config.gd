## The Tetris difficulty for a single encounter, derived from the enemies in a [CombatArena].
##
## Enemy stats map onto the board as follows:
## [br]- Each enemy's health -> that enemy's battle HP ([constant HEALTH_PER_HP]), which line clears
##      chip away at. The battle is won when every enemy is defeated.
## [br]- Total enemy attack  -> garbage rows already on the board ([constant ATTACK_PER_GARBAGE_ROW]).
## [br]- Fastest enemy speed -> starting level, i.e. fall speed ([constant SPEED_PER_LEVEL]).
## [br][br]Any value can be overridden per arena from the "Tetris Battle" group in the
## [CombatArena] inspector.
class_name TetrisBattleConfig extends RefCounted

## Every this-many points of a Battler's health becomes 1 HP in the Tetris battle. Damage is small
## (one point per line cleared), so raw RPG health would take far too long to chew through. Lower
## this to make every fight longer, raise it to make them shorter.
const HEALTH_PER_HP: = 4
## Every this-many points of enemy attack adds one row of starting garbage.
const ATTACK_PER_GARBAGE_ROW: = 5
## Every this-many points of the fastest enemy's speed adds one starting level.
const SPEED_PER_LEVEL: = 20

## The enemies to defeat, in the order they are targeted.
var enemies: Array[TetrisEnemy] = []
var garbage_rows: = 0
var start_level: = 1

## Human-readable summary of the opposing side, e.g. "Bugcat x2, Wolf".
var enemy_description: = "a mysterious foe"


## Builds a config from the arena a [signal FieldEvents.combat_triggered] carried. A null or
## non-arena scene yields the defaults, so combat can still be triggered without one.
static func from_arena(arena: PackedScene) -> TetrisBattleConfig:
	var config: = TetrisBattleConfig.new()
	if arena == null:
		config._add_fallback_enemy()
		return config

	var instance: = arena.instantiate()
	var combat_arena: = instance as CombatArena
	if combat_arena == null:
		instance.free()
		config._add_fallback_enemy()
		return config

	var total_attack: = 0
	var top_speed: = 0
	var enemy_counts: = {}  # Insertion-ordered: enemy name -> how many.

	for battler in combat_arena.get_battler_roster().get_enemy_battlers():
		if battler.stats == null:
			continue
		# Base stats are read because the derived stats are only initialized once in the tree.
		total_attack += battler.stats.base_attack
		top_speed = maxi(top_speed, battler.stats.base_speed)

		var enemy_name: = _get_enemy_name(battler)
		enemy_counts[enemy_name] = enemy_counts.get(enemy_name, 0) + 1

		var enemy_hp: = maxi(1, roundi(float(battler.stats.base_max_health) / HEALTH_PER_HP))
		var enemy: = TetrisEnemy.new(enemy_name, enemy_hp)
		enemy.icon = _load_enemy_icon(battler)
		config.enemies.append(enemy)

	if not config.enemies.is_empty():
		config.garbage_rows = total_attack / ATTACK_PER_GARBAGE_ROW
		config.start_level = 1 + top_speed / SPEED_PER_LEVEL
		config.enemy_description = _describe(enemy_counts)

	# Per-arena overrides set by a designer win over the derived values.
	if combat_arena.tetris_enemy_hp > 0:
		for enemy in config.enemies:
			enemy.max_hp = combat_arena.tetris_enemy_hp
			enemy.hp = combat_arena.tetris_enemy_hp
	if combat_arena.tetris_garbage_rows >= 0:
		config.garbage_rows = combat_arena.tetris_garbage_rows
	if combat_arena.tetris_start_level > 0:
		config.start_level = combat_arena.tetris_start_level

	instance.free()
	if config.enemies.is_empty():
		config._add_fallback_enemy()
	return config


## Combined health of every enemy, i.e. the total damage needed to win.
func get_total_hp() -> int:
	var total: = 0
	for enemy in enemies:
		total += enemy.max_hp
	return total


# A battle with no enemies could never be won, so stand something up to fight.
func _add_fallback_enemy() -> void:
	enemies.append(TetrisEnemy.new("Training Dummy", 5))


# Battler art follows the same convention as its stats, so
# "res://combat/battlers/bugcat/bugcat_stats.tres" implies "res://combat/battlers/bugcat/bugcat.png".
# Returns null when an enemy has no portrait, which the roster UI tolerates.
static func _load_enemy_icon(battler: Battler) -> Texture2D:
	var stats_path: = battler.stats.resource_path
	if stats_path.is_empty():
		return null

	var slug: = stats_path.get_file().get_basename().trim_suffix("_stats")
	var icon_path: = "%s/%s.png" % [stats_path.get_base_dir(), slug]
	if not ResourceLoader.exists(icon_path):
		return null
	return load(icon_path) as Texture2D


# Battler nodes are named generically ("Battler2"), so name enemies after their stats resource:
# "res://combat/battlers/bugcat/bugcat_stats.tres" -> "Bugcat".
static func _get_enemy_name(battler: Battler) -> String:
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
