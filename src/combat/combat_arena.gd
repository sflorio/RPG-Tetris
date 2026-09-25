## An arena is the editor-configured environment for a battle. It is a Control node that contains 
## the combat participants and details (such as background, foreground, music, etc.).
class_name CombatArena extends Control

## The music that will be automatically played during this combat instance.
@export var music: AudioStream

@export_group("Tetris Battle")
## Battle HP given to every enemy here. 0 = derive each from its Battler's health.
@export var tetris_enemy_hp: = 0
## Garbage rows on the board when the battle starts. -1 = derive from total enemy attack.
@export var tetris_garbage_rows: = -1
## Starting level, which sets fall speed. 0 = derive from the fastest enemy's speed.
@export var tetris_start_level: = 0


## Retrieve the list of the combat participants, in [BattlerRoster] form.
func get_battler_roster() -> BattlerRoster:
	return $Battlers as BattlerRoster
