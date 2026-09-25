extends Node

const I := TetrisDamageRules.Piece.I

func _ready() -> void:
	var cfg := TetrisBattleConfig.from_arena(load("res://overworld/maps/town/battles/test_combat_arena.tscn"))
	print("ENEMIES: %s  total HP=%d  garbage=%d level=%d" % [cfg.enemy_description, cfg.get_total_hp(), cfg.garbage_rows, cfg.start_level])
	for e in cfg.enemies:
		print("   - ", e)

	var battle := TetrisBattle.new()
	battle.config = cfg
	battle.finished.connect(func(won: bool, _s: int, _l: int) -> void:
		print("BATTLE: finished won=", won)
		get_tree().quit())
	add_child(battle)
	await get_tree().process_frame

	var grid: Node = battle.get_node("Main/Grid")
	# Deal damage the way the board does: emit clears. 3 Bugcats of 5 HP = 15 HP total.
	for i in 6:
		grid.lines_cleared.emit(4, I, false)   # a Tetris each time
		await get_tree().process_frame
		var alive := 0
		for e in cfg.enemies:
			if not e.is_defeated(): alive += 1
		print("  after tetris %d -> %s | alive=%d" % [i + 1, ", ".join(cfg.enemies.map(func(e): return str(e))), alive])
		if alive == 0:
			break
	await get_tree().create_timer(1.5).timeout
	print("BATTLE: did not finish in time")
	get_tree().quit()
