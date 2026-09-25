## One enemy taking part in a Tetris battle.
##
## Enemies are damaged by line clears (see [TetrisDamageRules]) and the battle is won once every
## enemy is defeated. Built from an arena's Battlers by [method TetrisBattleConfig.from_arena].
class_name TetrisEnemy extends RefCounted

## Name shown above this enemy's health bar.
var display_name: String = "Enemy"

## Health this enemy started with.
var max_hp: int = 5

## Health remaining. Reaching 0 defeats the enemy.
var hp: int = 5


func _init(enemy_name: String = "Enemy", starting_hp: int = 5) -> void:
	display_name = enemy_name
	max_hp = maxi(1, starting_hp)
	hp = max_hp


func is_defeated() -> bool:
	return hp <= 0


## Applies damage and returns how much was actually dealt, which is capped by remaining health so
## overkill doesn't leak onto the next enemy.
func take_damage(amount: int) -> int:
	var dealt: = clampi(amount, 0, hp)
	hp -= dealt
	return dealt


## Health remaining as a 0..1 ratio, for the health bar.
func get_health_ratio() -> float:
	return float(hp) / float(max_hp)


func _to_string() -> String:
	return "%s (%d/%d)" % [display_name, hp, max_hp]
