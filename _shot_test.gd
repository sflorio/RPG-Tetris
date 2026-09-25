extends Node

const O := TetrisDamageRules.Piece.O

func _ready() -> void:
	var main: Node = load("res://src/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(1.5).timeout
	Dialogic.end_timeline()
	await get_tree().create_timer(0.5).timeout
	FieldEvents.combat_triggered.emit(load("res://overworld/maps/town/battles/test_combat_arena.tscn"))
	await get_tree().create_timer(3.0).timeout

	var battle: TetrisBattle = null
	for n in get_tree().root.find_children("*", "TetrisBattle", true, false):
		battle = n
	print("CFG: %s total HP=%d" % [battle.config.enemy_description, battle.config.get_total_hp()])
	var grid: Node = battle.get_node("Main/Grid")
	# Land a few hits so the bars are partly drained, ending on the square-streak payoff.
	grid.lines_cleared.emit(2, O, false)
	await get_tree().create_timer(0.4).timeout
	grid.lines_cleared.emit(2, O, false)
	await get_tree().create_timer(0.4).timeout
	grid.lines_cleared.emit(3, O, false)
	await get_tree().create_timer(0.2).timeout
	for e in battle.config.enemies:
		print("  ", e)
	get_viewport().get_texture().get_image().save_png("C:/Godot/_battle_shot.png")
	print("SHOT saved")
	get_tree().quit()
