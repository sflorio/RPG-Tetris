## Maps the OpenRPG placeholder battlers onto the design's characters and alien invaders.
##
## The arenas still reference GDQuest's demo battlers (bear, squirrel, bugcat, wolf), because the
## real encounters do not exist yet. Rather than rewrite every arena scene and stats resource for
## placeholders that will be replaced anyway, the name and portrait are swapped here at the point
## the battle is built.
##
## The three player battlers become Wilhelm, Olister and Rena, so they pick up the abilities and
## Traits in [Characters]. When real encounters arrive this file goes away: give each unit its own
## stats resource and the convention in [TetrisBattleConfig] picks up the matching art.
class_name UnitAppearance extends RefCounted

## Where the unit art lives.
const SPRITE_DIR: = "res://assets/units/"

## Source battler name -> how it should appear. Keys are lower case.
const APPEARANCES: = {
	# The party, from the design's Characters note.
	"bear": {"name": "Wilhelm", "sprite": "soldier"},
	"squirrel": {"name": "Olister", "sprite": "archer"},
	"gobot": {"name": "Rena", "sprite": "cleric"},
	# The invaders.
	"bugcat": {"name": "Xeno Drone", "sprite": "xeno_drone"},
	"wolf": {"name": "Xeno Stalker", "sprite": "xeno_stalker"},
	"ghost": {"name": "Xeno Watcher", "sprite": "xeno_watcher"},
}

## Art that exists but is not yet assigned to a battler, ready for real units.
const UNUSED_SPRITES: Array[String] = [
	"mage", "barbarian", "thief", "xeno_crawler", "xeno_swarm", "xeno_ooze",
]


## The display name for a source battler, or the original name when it has no mapping.
static func get_display_name(source_name: String) -> String:
	var entry: Dictionary = APPEARANCES.get(source_name.to_lower(), {})
	return entry.get("name", source_name)


## The portrait for a source battler, or null when it has no mapping — in which case
## [TetrisBattleConfig] falls back to the battler's own art.
static func get_sprite(source_name: String) -> Texture2D:
	var entry: Dictionary = APPEARANCES.get(source_name.to_lower(), {})
	if entry.is_empty():
		return null

	var path: = "%s%s.png" % [SPRITE_DIR, entry["sprite"]]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func has_mapping(source_name: String) -> bool:
	return APPEARANCES.has(source_name.to_lower())
