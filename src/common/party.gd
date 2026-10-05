## The player's party, as it persists outside combat.
##
## The design's Unit Stats note gives the Party its own stat block — Level, Experience, Tech Points,
## Luck, Crowns, Play Time, Battle Count, Gravity, Move Speed and Encounter Rate — and those outlive
## any one battle, so they live here rather than being rebuilt per encounter. [TetrisBattleConfig]
## reads this when a battle starts.
##
## The player's name comes from the character creator at the start of the game. The design writes it
## as PLAYER throughout the Opening, and every one of those is replaced with what the player typed,
## which is what the Dialogic variable keeps in step.
extends Node

## Emitted when the Crowns total changes, so the UI can react.
signal crowns_changed(total: int)

## Emitted once the player has named themselves.
signal player_named(player_name: String)

## The Dialogic variable the Opening's timelines read as {PlayerName}.
const NAME_VARIABLE: = "PlayerName"

## Used until the player names themselves, and if they confirm an empty field.
const DEFAULT_NAME: = "Psion"

const SAVE_PATH: = "user://party.tres"

var stats: PartyStats = PartyStats.new()

var player_name: = DEFAULT_NAME:
	set(value):
		var trimmed: = value.strip_edges()
		player_name = trimmed if not trimmed.is_empty() else DEFAULT_NAME
		_publish_name()
		player_named.emit(player_name)


func _ready() -> void:
	restore()
	_publish_name()


## Adds Crowns, the design's currency. Negative amounts spend them, never below zero.
func add_crowns(amount: int) -> int:
	stats.crowns = maxi(stats.crowns + amount, 0)
	crowns_changed.emit(stats.crowns)
	return stats.crowns


func save() -> void:
	ResourceSaver.save(stats, SAVE_PATH)


func restore() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		var loaded: = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		if loaded is PartyStats:
			stats = loaded


## Clears the party back to a new game. Used by the character creator, so starting over does not
## inherit the last run's Crowns.
func reset() -> void:
	stats = PartyStats.new()
	crowns_changed.emit(stats.crowns)


# Dialogic variables are the only way a timeline can interpolate text, so the name is mirrored into
# one. Guarded because Dialogic is not up yet during autoload registration.
func _publish_name() -> void:
	if Engine.is_editor_hint() or not is_inside_tree():
		return
	if Dialogic and Dialogic.has_subsystem("VAR"):
		Dialogic.VAR.set_variable(NAME_VARIABLE, player_name)
