## An arena is the editor-configured environment for a battle. It is a Control node that contains 
## the combat participants and details (such as background, foreground, music, etc.).
class_name CombatArena extends Control

## The music that will be automatically played during this combat instance.
@export var music: AudioStream

@export_group("Tetris Battle")
## Junk rows stacked on the board when combat starts, so it never begins empty.
## -1 = derive from the total attack of the enemies in this arena.
@export var tetris_junk_rows: = -1


## Retrieve the list of the combat participants, in [BattlerRoster] form.
func get_battler_roster() -> BattlerRoster:
	return $Battlers as BattlerRoster
